# apfel — Status Overview

**Version:** 0.7.8
**Date:** 2026-04-05
**Build:** Local release builds are clean with Swift 6.3 / macOS 26.4 SDK
**Tests:** ✅ 118 unit tests + 97 integration tests

---

## Golden Goal Scorecard

| Goal | Status | Evidence |
|------|--------|----------|
| **UNIX tool** | ✅ 100% | Pipe, stdin, `--json`, `--quiet`, exit codes (0-6), `NO_COLOR`, env vars, `--system-file`, `--temperature/seed/max-tokens/permissive/model-info` |
| **OpenAI server** | ✅ 100% | `/v1/chat/completions` (stream+non-stream), `/v1/models`, `/health`, tools (native ToolDefinition), `response_format`, `finish_reason` (stop/tool_calls/length), CORS, 501 stubs, real token counts, streaming usage stats |
| **CLI chat** | ✅ 100% | Multi-turn, context rotation, typed errors, system prompt, line editing + session-local history |
| **On-device** | ✅ 100% | SystemLanguageModel only. Zero network. Zero cloud. |
| **Honest** | ✅ 100% | 501 for unsupported, real token counts, typed errors, semantic exit codes |

## Closed Tickets Snapshot

| # | Title | Resolved in |
|---|-------|-------------|
| 001 | Real token counting | v0.3.0 |
| 002 | Context window truncation | v0.3.0 |
| 003 | CLI polish | v0.4.0 |
| 004 | Server polish | v0.4.0 |
| 005 | Python OpenAI E2E tests | v0.5.0 |
| ~~006~~ | ~~Context summarization~~ | Killed (not aligned with golden goal) |
| 007 | GUI token budget display | v0.5.0 |
| 008 | `finish_reason:"length"` | v0.5.0 |
| 009 | Environment variables | v0.5.0 |
| 010 | `--system-file` flag | v0.5.0 |
| 011 | Semantic exit codes | v0.5.0 |
| 012 | OpenAPI spec validation | v0.6.x |
| 013 | Tool call args not JSON | v0.6.x |
| 014 | Allow role:"tool" as last message | v0.6.x |
| 015 | Deduplicate tool prompt/schema assembly | v0.6.4 |
| 016 | Centralize chat handler error/trace construction | v0.6.4 |
| 017 | Consolidate transcript budget candidate assembly | v0.6.4 |
| 018 | Publish apfel via Homebrew tap | v0.6.4 |

## Active GitHub Issue Snapshot

- `#34` `Arrow key navigation in chat mode` was the latest open UX bug at this snapshot.
- `#33` `Webpage example doesn't work due to exclamation mark` is closed.
