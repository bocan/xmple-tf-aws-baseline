
## Features

### CI/CD and Development Guardrails.

- Open Source MIT License.
- All module calls are locked to a specific version.
- Editorconfig to force a consistent coding style.
- A .tool-version for [ASDF](https://asdf-vm.com/) to enforce common tooling
  versions.
- Github Actions to automatically tag and release upon a merge with `main`.
- Tags and Release are immutable across all repos.
- Github Action to run a pre-commit check on a PR. Users would be expected to
  run this themselves before committing by installing it with
  `pre-commit install`
- A Terraform flavoured .gitignore.
- Pre-commit checks for:
    - style enforcement.
    - hard coded secret detection with [Gitleaks](https://gitleaks.io/).
    - generating Terraform documentation.
    - Terraform validation and linting.
    - Using Checkov to scan for security issues.

### Future Improvements

- Ideally, all these modules should exist in their own repositories to allow us
  to individually control their versions.
