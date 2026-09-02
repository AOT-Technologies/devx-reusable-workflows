#!/usr/bin/env python3
"""Static contract checks for the DevX reusable workflows.

actionlint validates each workflow file in isolation. These checks validate the
relationships *between* them -- the failure mode that costs the most, because
GitHub reports it as an empty string at run time rather than as an error:

  1. needs-completeness   every `needs.<job>` reference is a declared dependency
  2. job-outputs          every consumed job output is declared in `outputs:`
  3. call contracts       `with:`/`secrets:` match the callee's declaration,
                          required inputs are supplied, and consumed workflow
                          outputs actually exist on the callee
  4. secret declarations  every `secrets.X` used is declared in workflow_call
  5. action pinning       no third-party action on a mutable tag or branch

Run from the repository root:  python .github/scripts/validate_workflows.py
"""
from __future__ import annotations

import os
import re
import sys
import glob

import yaml

WORKFLOW_DIR = os.path.join('.github', 'workflows')
SELF_PREFIX = 'AOT-Technologies/devx-reusable-workflows/.github/workflows/'
SHA_RE = re.compile(r'^[0-9a-f]{40}$')

# Workflows that are entrypoints for humans/CI rather than reusable modules.
NON_REUSABLE = {'repo-ci.yaml', 'release.yaml'}


def load(path):
    with open(path, encoding='utf-8') as fh:
        return yaml.safe_load(fh)


def workflow_call(doc):
    # PyYAML parses the bare key `on` as the boolean True.
    on = doc.get('on', doc.get(True)) or {}
    if not isinstance(on, dict):
        return {}
    return on.get('workflow_call') or {}


def main() -> int:
    paths = sorted(glob.glob(os.path.join(WORKFLOW_DIR, '*.y*ml')))
    if not paths:
        print(f'::error::No workflows found under {WORKFLOW_DIR}')
        return 1

    docs = {os.path.basename(p): load(p) for p in paths}
    sources = {os.path.basename(p): open(p, encoding='utf-8').read() for p in paths}
    specs = {
        name: {
            'inputs': workflow_call(doc).get('inputs') or {},
            'secrets': workflow_call(doc).get('secrets') or {},
            'outputs': workflow_call(doc).get('outputs') or {},
        }
        for name, doc in docs.items()
    }

    errors: list[str] = []

    def err(name, msg):
        errors.append(f'{WORKFLOW_DIR}/{name}: {msg}')
        print(f'::error file={WORKFLOW_DIR}/{name}::{msg}')

    for name, doc in docs.items():
        src = sources[name]
        jobs = doc.get('jobs') or {}

        # ---- 4. every secret used must be declared -------------------------
        declared_secrets = set(specs[name]['secrets'])
        used_secrets = set(re.findall(r'secrets\.([A-Za-z0-9_]+)', src)) - {'GITHUB_TOKEN'}
        for missing in sorted(used_secrets - declared_secrets):
            err(name, f"secrets.{missing} is used but not declared in "
                      f"on.workflow_call.secrets -- it will resolve to an empty string")

        for job_name, job in jobs.items():
            if not isinstance(job, dict):
                continue

            needs = job.get('needs') or []
            needs = {needs} if isinstance(needs, str) else set(needs)
            body = yaml.safe_dump(job)

            # ---- 1. needs-completeness -------------------------------------
            referenced = set(re.findall(r'needs\.([A-Za-z0-9_-]+)\.', body))
            for missing in sorted(referenced - needs):
                err(name, f"job '{job_name}' reads needs.{missing}.* but does not list "
                          f"'{missing}' in its needs: -- the reference is always empty")

            # ---- 2. job outputs consumed elsewhere must be declared ---------
            if 'steps' in job:
                declared = set((job.get('outputs') or {}))
                consumed = set(re.findall(
                    rf'needs\.{re.escape(job_name)}\.outputs\.([A-Za-z0-9_]+)', src))
                consumed |= set(re.findall(
                    rf'jobs\.{re.escape(job_name)}\.outputs\.([A-Za-z0-9_]+)', src))
                for missing in sorted(consumed - declared):
                    err(name, f"job '{job_name}' output '{missing}' is consumed but not "
                              f"declared in that job's outputs: map")

            # ---- 3. reusable-workflow call contracts -----------------------
            uses = job.get('uses')
            if uses and SELF_PREFIX in uses:
                callee = uses.split(SELF_PREFIX, 1)[1].split('@')[0]
                spec = specs.get(callee)
                if spec is None:
                    err(name, f"job '{job_name}' calls unknown workflow '{callee}'")
                    continue

                given_in = set(job.get('with') or {})
                given_sec = set(job['secrets']) if isinstance(job.get('secrets'), dict) else set()
                required_in = {k for k, v in spec['inputs'].items()
                               if isinstance(v, dict) and v.get('required')}
                required_sec = {k for k, v in spec['secrets'].items()
                                if isinstance(v, dict) and v.get('required')}

                for bad in sorted(given_in - set(spec['inputs'])):
                    err(name, f"job '{job_name}' passes input '{bad}', which {callee} "
                              f"does not declare")
                for bad in sorted(required_in - given_in):
                    err(name, f"job '{job_name}' omits required input '{bad}' of {callee}")
                for bad in sorted(given_sec - set(spec['secrets'])):
                    err(name, f"job '{job_name}' passes secret '{bad}', which {callee} "
                              f"does not declare")
                if job.get('secrets') != 'inherit':
                    for bad in sorted(required_sec - given_sec):
                        err(name, f"job '{job_name}' omits required secret '{bad}' "
                                  f"of {callee}")

                consumed = set(re.findall(
                    rf'needs\.{re.escape(job_name)}\.outputs\.([A-Za-z0-9_]+)', src))
                consumed |= set(re.findall(
                    rf'jobs\.{re.escape(job_name)}\.outputs\.([A-Za-z0-9_]+)', src))
                for bad in sorted(consumed - set(spec['outputs'])):
                    err(name, f"job '{job_name}' reads output '{bad}', which {callee} "
                              f"does not declare")

        # ---- 5. action pinning --------------------------------------------
        for ref in re.findall(r'uses:\s*(\S+)', src):
            if ref.startswith(SELF_PREFIX) or ref.startswith('./'):
                continue
            if '@' not in ref:
                err(name, f"action reference '{ref}' has no version")
                continue
            action, rev = ref.rsplit('@', 1)
            if not SHA_RE.match(rev):
                err(name, f"action '{action}' is pinned to '{rev}'. Third-party actions "
                          f"must be pinned to a full 40-character commit SHA "
                          f"(add the version as a trailing comment)")

        # ---- every reusable module should declare permissions --------------
        if name not in NON_REUSABLE and 'permissions' not in doc:
            err(name, 'no top-level permissions: block -- declare least privilege '
                      'explicitly rather than inheriting the caller default')

    if errors:
        print(f'\n{len(errors)} contract violation(s) found.')
        return 1

    print(f'All contract checks passed across {len(docs)} workflows.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
