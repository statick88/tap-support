# Contributing to TikTok Tap Support

> **Built by Statick | https://statick.dev**

Thank you for considering contributing to TikTok Tap Support! We welcome contributions from the community.

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please be respectful and inclusive.

## 🚀 Quick Start

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/tap-support.git`
3. **Create** a feature branch: `git checkout -b feature/amazing-feature`
4. **Make** your changes
5. **Test** your changes: `make test`
6. **Lint** your code: `make lint`
7. **Commit** your changes: `git commit -m 'feat: add amazing feature'`
8. **Push** to your fork: `git push origin feature/amazing-feature`
9. **Create** a Pull Request

## 📋 Development Setup

### Prerequisites

- Go 1.24 or later
- Make
- Docker (optional)

### Install Dependencies

```bash
make deps
```

### Build the Project

```bash
make build
```

### Run Tests

```bash
make test
```

### Run with Coverage

```bash
make coverage
```

### Run Linters

```bash
make lint
```

## 🏗️ Architecture

This project follows **Clean Architecture** principles:

```
cmd/tap-support/     # Entry point
internal/
  ├── application/    # Use cases
  ├── domain/         # Business entities
  ├── infrastructure/ # External services
  └── ui/             # TUI components
```

## 📝 Coding Standards

- Follow Go standard conventions
- Use meaningful variable names
- Add comments for complex logic
- Write unit tests for new features
- Run `make lint` before committing

## 🐛 Reporting Bugs

Use GitHub Issues to report bugs. Include:

1. **Description**: Clear explanation of the bug
2. **Steps to Reproduce**: How to trigger the bug
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happened
5. **Environment**: OS, Go version, etc.

## 💡 Feature Requests

Open a GitHub Issue with:

1. **Feature Description**: What you want to add
2. **Use Case**: Why this feature is needed
3. **Implementation Ideas** (optional): How you think it could be done

## 🔧 Pull Request Guidelines

- Keep PRs focused and small
- Update documentation if needed
- Add tests for new functionality
- Ensure all CI checks pass
- Use conventional commits:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation
  - `refactor:` for code refactoring
  - `test:` for tests

## 📄 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

Thank you to all contributors!

---

**Built by Statick | https://statick.dev**