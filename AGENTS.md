# Repository Guidelines

## Project Structure & Module Organization
- `src/` contains all TypeScript source.
- `src/entrypoints/cli.tsx` is the Bun build entrypoint; build output is root-level `cli.js` (generated file).
- `src/commands/` holds slash-command handlers, usually one folder per command.
- `src/components/` contains Ink/React UI components.
- `src/services/`, `src/tools/`, and `src/utils/` contain integrations, tool implementations, and shared utilities.
- `src/verify/examples/` stores verification-related examples.

## Build, Test, and Development Commands
- `bun install`: install dependencies.
- `bun run build`: bundle `src/entrypoints/cli.tsx` into `cli.js`.
- `bun run start`: run the built CLI (`bun cli.js`).
- `bun run typecheck`: run strict TypeScript checks (`tsc --noEmit`).
- `bun cli.js --help` or `bun cli.js -p "hello"`: quick runtime smoke checks.

## Coding Style & Naming Conventions
- Language: TypeScript (ES modules, `strict: true`).
- Follow existing style in `src/`: 2-space indentation, semicolons, and single quotes.
- Naming: components use `PascalCase.tsx`; utility modules use `camelCase.ts`; command directories are typically kebab-case (for example `src/commands/output-style/`).
- Prefer the configured path alias for cross-module imports: `src/*`.
- Do not hand-edit generated artifacts such as `cli.js`.

## Testing Guidelines
- This repository currently has no dedicated `test` script or committed unit-test framework.
- Minimum pre-PR validation is:
  1. `bun run typecheck`
  2. `bun run build`
  3. relevant CLI smoke tests for changed behavior
- Document exact manual checks in the PR description (commands + observed result).

## Commit & Pull Request Guidelines
- Match existing commit style: short, imperative subjects (for example `Add ...`, `Update ...`, `Remove ...`, `Replace ...`).
- Keep each commit focused on one change area.
- PRs should include: change summary, motivation, risk/impact, validation steps, and linked issues.
- For terminal UI changes, include screenshots or short recordings.

## Security & Configuration Tips
- Never commit credentials; use environment variables (for example `ANTHROPIC_API_KEY`).
- Treat private-package stubs and auth flows carefully; call out any behavior limits introduced by local stubs.
