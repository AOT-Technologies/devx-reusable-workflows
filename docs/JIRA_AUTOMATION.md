# 🤖 Jira Automation: Automatic Branch Creation

This guide explains how to configure Jira to automatically create a GitHub branch when a work item (Task/Bug/Story) is moved to **"In Progress"**.

## Prerequisites
1.  **GitHub for Jira App**: Must be installed and configured in your Jira instance ([link to app](https://marketplace.atlassian.com/apps/1219592/github-for-jira)).
2.  **Repo Connection**: Your GitHub organization/repository must be connected in Jira (Settings -> Apps -> GitHub for Jira).

---

## 🛠️ Step-by-Step Configuration

### 1. Create a New Automation Rule
1.  In your Jira Project, go to **Project settings** -> **Automation**.
2.  Click **Create rule**.

### 2. Set the Trigger
1.  Select **Issue transitioned**.
2.  **From status**: (Any status)
3.  **To status**: `In Progress`
4.  Click **Save**.

### 3. Add a Condition (Recommended)
1.  Click **New condition** -> **Issue fields condition**.
2.  **Field**: `Issue Type`
3.  **Condition**: `is one of`
4.  **Values**: `Task`, `Bug`, `Story`
5.  Click **Save**.

### 4. Set the Action (Create Branch)
1.  Click **New action**.
2.  Search for **Create GitHub branch**.
3.  **Repository**: Select your target repository (e.g., `demo-python-app`).
4.  **Branch name**: 
    ```text
    feature/{{issue.key}}-{{issue.summary.slug}}
    ```
5.  **Target branch**: `development`
6.  Click **Save**.

### 5. Name and Turn On
1.  Give the rule a name: `Auto-create Feature Branch on In-Progress`.
2.  Click **Turn it on**.

---

## 🔄 How it works
1.  A developer picks up a Jira ticket (e.g., `DEV-123: Add Login logic`).
2.  They move it to **In Progress**.
3.  Jira automatically creates `feature/DEV-123-add-login-logic` in GitHub, branched from `development`.
4.  The developer can now `git fetch` and start working immediately.
