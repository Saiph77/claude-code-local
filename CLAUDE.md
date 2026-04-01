# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the source code for `@anthropic-ai/claude-code v2.1.88` — a terminal AI coding assistant built with TypeScript, React (Ink), and Bun.

## Build & Run

**Install dependencies:**
```bash
bun install
```

**Build (compiles `src/` → `cli.js`):**
```bash
bun run build
```

The build injects compile-time macros (`MACRO.VERSION`, `MACRO.BUILD_TIME`, etc.) via Bun's `--define` flags. These are not available at runtime from `.ts` source directly.

**Run:**
```bash
export ANTHROPIC_API_KEY=sk-ant-xxxx
bun cli.js           # interactive mode
bun cli.js -p "..."  # non-interactive / headless
```

**Type-check (no emit):**
```bash
bun run typecheck
```

There are no test commands in `package.json`. No linter config exists in the repo.

## Path Aliases

- `src/*` resolves to `./src/*` (configured in both `bunfig.toml` and `tsconfig.json`)
- `react/compiler-runtime` → `react-compiler-runtime`
- `bun:bundle` is a Bun build-time module (provides `feature()` for dead-code elimination flags)

## Architecture

### Entry Points (`src/entrypoints/`)
- `cli.tsx` — Bootstrap entry: fast-paths `--version`, then delegates to `main.tsx`
- `init.ts` — One-time initialization (telemetry, config, migrations)
- `mcp.ts` — MCP server mode entry

### Main Application (`src/main.tsx`)
Parses CLI args via Commander, initializes auth/config/growthbook, then calls `launchRepl()` which renders the Ink UI.

### Core Loop
- `src/query.ts` — Single API turn: sends messages to Anthropic API, handles tool use, returns stream events
- `src/QueryEngine.ts` — Multi-turn orchestration: manages conversation history, compact/context-collapse, session persistence, and calls `query.ts` in a loop
- `src/Task.ts` — Task type definitions (`local_bash`, `local_agent`, `remote_agent`, `in_process_teammate`, etc.)

### UI Layer (`src/screens/`, `src/components/`)
- `src/screens/REPL.tsx` — Main interactive REPL screen (the primary UI component)
- `src/screens/Doctor.tsx` — Diagnostics screen
- `src/components/` — All React/Ink UI components (messages, diffs, dialogs, settings, etc.)
- `src/state/AppState.tsx` / `AppStateStore.ts` — Global React state store (Zustand-like pattern with `createStore`)

### Tools (`src/tools/`, `src/tools.ts`)
Each tool lives in its own directory (e.g. `src/tools/BashTool/`). `src/tools.ts` assembles the full tool list. Feature-flagged tools (REPL, Cron, etc.) use `feature()` guards and dynamic `require()`.

Key tools: `BashTool`, `FileEditTool`, `FileReadTool`, `FileWriteTool`, `GlobTool`, `GrepTool`, `AgentTool`, `SkillTool`, `WebFetchTool`, `WebSearchTool`, `TodoWriteTool`, `TaskCreate/Get/List/Update/Stop/Output`.

### Commands (`src/commands/`, `src/commands.ts`)
Slash commands (e.g. `/commit`, `/compact`, `/config`). Each command is a directory under `src/commands/`. `src/commands.ts` exports the command registry.

### Skills (`src/skills/`)
User-invocable skill definitions (markdown prompts). Bundled skills are in `src/skills/bundled/`. `SkillTool` executes them.

### Plugins (`src/plugins/`)
Plugin system. `builtinPlugins.ts` registers built-in plugins. External plugins loaded from `~/.claude/plugins/`.

### Services (`src/services/`)
- `api/` — Anthropic API client, retry logic, streaming, cost tracking
- `mcp/` — Model Context Protocol server management
- `compact/` — Context compaction (auto-compact when context window fills)
- `analytics/` — GrowthBook feature flags, telemetry
- `oauth/` — OAuth authentication flow
- `lsp/` — Language Server Protocol integration

### Context & State
- `src/context.ts` — Builds system prompt context (git status, CLAUDE.md files, memory)
- `src/constants/prompts.ts` — System prompt assembly
- `src/bootstrap/state.ts` — Session-level singleton state (session ID, token budgets, etc.)
- `src/utils/config.ts` — Reads/writes `~/.claude/settings.json`

### Feature Flags
`feature('FLAG_NAME')` calls from `bun:bundle` are dead-code-eliminated at build time. Internal/Ant-only features are gated this way and absent from external builds.

## Private Package Stubs

Four Anthropic-internal packages are stubbed in `node_modules/` (not on npm):
- `@ant/claude-for-chrome-mcp` — Chrome browser integration
- `@ant/computer-use-mcp` — Computer Use (mouse/keyboard)
- `@anthropic-ai/mcpb` — Plugin marketplace (.dxt format)
- `@anthropic-ai/sandbox-runtime` — Sandbox isolation

Modifying files under `src/utils/claudeInChrome/`, `src/utils/sandbox/`, `src/skills/bundled/claudeInChrome.ts`, or `src/utils/plugins/mcpbHandler.ts` will break the build.
