# CI

GitHub Actions workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

## Jobs

| Job | Checks |
|-----|--------|
| Backend | format, lint, typecheck, unit tests (`--passWithNoTests` until suites exist), build; Postgres + Redis services |
| Frontend | format, lint, typecheck, tests, build |
| Bot | typecheck, build |

Runs on `push` to `main`/`master`/`develop` and on PRs. Skip with `[skip ci]` in commit message on push.

## Local equivalent

```bash
make ci          # lint + format-check + typecheck + test + build
make pre-commit  # lint-staged + typecheck of staged apps
```

## Node

Use Node **22** (see `.nvmrc`).
