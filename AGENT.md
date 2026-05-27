# ClearTranslate Agent Instructions

## Project Context

ClearTranslate is a Flutter-based cross-platform translation tool focused on a clean, high-quality Chinese-English translation experience.

The product direction is documented under `docs/`. Before making product, architecture, or roadmap-level changes, read the relevant documentation first.

## Development Habits

### Test Before Finishing

After completing a small feature, bug fix, or meaningful code change, run the relevant tests before considering the task done.

Preferred checks, depending on the project state:

- `flutter test`
- `flutter analyze`
- targeted unit tests for the changed module
- manual verification for UI behavior when automated tests are not available

If tests cannot be run because the Flutter project or test setup does not exist yet, state that clearly in the final response.

### Commit After Passing Tests

After a small feature or fix is complete and tests pass, make a local Git commit.

Use this commit format:

```text
feat(foo-function): short description
```

Examples:

```text
feat(settings): add api key storage
feat(history): save translation records locally
fix(translate): handle empty provider response
docs(roadmap): update mvp milestones
```

Use common conventional prefixes where appropriate:

- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation-only change
- `refactor`: code change without behavior change
- `test`: test-only change
- `chore`: tooling, config, or maintenance

### Branching For Large Phases

For large phases or broad changes, create a new branch before development.

Recommended branch format:

```text
feature/phase-name
```

Examples:

```text
feature/phase-0-prototype
feature/phase-1-mvp-translation
feature/phase-2-long-text-dictionary
```

Do not mix unrelated phases in the same branch.

### Keep Changes Scoped

Keep each task focused on the requested scope.

- Avoid unrelated refactors.
- Avoid changing generated files unless required.
- Avoid mixing documentation, architecture, UI, and infrastructure changes in one commit unless the task explicitly requires it.

### Protect User Work

The working tree may contain user changes.

- Do not revert files unless explicitly asked.
- Do not run destructive Git commands such as `git reset --hard`.
- If unrelated files are modified, leave them alone.
- If existing changes affect the current task, work with them and mention any relevant constraints.

## Documentation Expectations

When adding or changing major behavior, update the relevant documentation:

- Product behavior: `docs/overview.md` or `docs/mvp-spec.md`
- Technical design: `docs/technical-doc.md`
- Roadmap or delivery phase: `docs/roadmap.md`
- Known risks: `docs/risk-register.md`

Documentation should be concise, practical, and directly useful for implementation.

