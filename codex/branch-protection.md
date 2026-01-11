# Branch protection + required checks

Configure branch protection in GitHub (Settings → Branches → `main` protection rule):
- Require pull requests before merging and block direct pushes (recommended: 1–2 approving reviews).
- Require status checks to pass before merging and tick `Require branches to be up to date`.
  - Required checks: `Backend lint & tests`, `Admin lint & tests`.
- Optionally restrict who can push and enforce signed commits.

CI coverage:
- Workflow: `.github/workflows/ci.yml`.
- `Backend lint & tests`: installs deps, fails fast if `backend/src/database/migrations` is missing/empty, runs ESLint with `--max-warnings=0`, then Jest in band.
- `Admin lint & tests`: installs deps, lints `admin/src` (TS/JS/TSX/JSX), runs CRA tests with `CI=true`.

Note: the migration guard currently fails because no files exist under `backend/src/database/migrations`; generate/check in a follow-up before merging to `main`.
