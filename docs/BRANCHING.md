# 🏷️ GitHub Branching Strategy

This repository follows a structured branching model designed for stable releases, fast integration, and automated verification.

---

## 🌳 Branch Hierarchy

| Branch | Purpose | Permissions |
| :--- | :--- | :--- |
| **`main`** | **Production-ready code.** Reflects the current state of QA and Production. | **Protected**. No direct pushes. |
| **`development`** | **Integration branch.** Where all features are merged for testing. | **Protected**. PR required from feature branches. |
| **`feature/*`** | **Active development.** Short-lived branches for specific Jira tickets. | Open. Pushed by individual developers. |

---

## ⚙️ Repository Configuration

To ensure the integrity of the strategy, the following **Branch Protection Rules** must be set for the `development` and `main` branches. (Need github paid plan for private repositories to enable branch protection rules)

### 🛡️ Development Branch Protection
1.  **Branch name pattern**: `development`
2.  **Protect matching branches**:
    -   Check **"Require a pull request before merging"**.
    -   Check **"Require status checks to pass before merging"**.
    -   Search for and select: **`DevX CI Pipeline`**.

### 🛡️ Main Branch Protection
1.  **Branch name pattern**: `main`
2.  **Protect matching branches**:
    -   Check **"Require a pull request before merging"** (Development ➡️ Main).
    -   Check **"Require status checks to pass before merging"**.

---

## 🔄 Deployment Lifecycle (4-Stage Flow)

### Stage 1: Feature Build (Verification)
-   **Trigger**: Create Pull Request from `feature/*` ➡️ `development`.
-   **Action**: Runs **CI Only** (Build, Test, Security). No deployment.
-   **Goal**: Ensure code is safe to merge.

### Stage 2: Dev Build (Integration)
-   **Trigger**: Merge Pull Request into `development`.
-   **Action**: Runs **CI + CD to Dev Environment**.
-   **Goal**: Test interactions in a shared dev environment.

### Stage 3: QA Build (Release Candidate)
-   **Trigger**: Merge `development` ➡️ `main`.
-   **Action**: Runs **CI + CD to QA Environment**.
-   **Goal**: Create a "Golden Image" for final sign-off.

### Stage 4: Production Deployment (Promotion)
-   **Trigger**: **Manual trigger** on the `main` branch.
-   **Action**: **CD Only** (Deploys the image built in Stage 3).
-   **Goal**: Zero-recompile promotion from QA to Production.

---

## 🚀 Step-by-Step for Developers

1.  **Start Work**: Jira ticket moves to "In Progress" ➡️ Auto-create `feature/DEV-123-ticket-name`.
2.  **Push Code**: `git push origin feature/DEV-123-ticket-name`.
3.  **Propose Changes**: Open PR to `development`.
4.  **Verify**: Wait for the **DevX CI Pipeline** status check to turn green.
5.  **Integrate**: Click **Merge**. Your changes now automatically deploy to the **Dev Server**!
