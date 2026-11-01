# Changelog

## 0.1.2
- `apprentice-deploy` serves a Mac-trained model the way it was trained: the full `mlx_lm.server` command with `enable_thinking` off, the adapter folder, and a test request before any code changes. It also says the two edits a switch needs: model name `"default_model"`, because the server applies the adapter only under that name, and the row's input as one user message with no system prompt.
- `apprentice-train` runs local training the way an agent should: detached, with the user's live watch command, status polling, and the coded errors (needs `runapprentice` 0.4.4).
- `apprentice-train` asks the user how much memory training may use (low, medium, high or auto) before starting, in words a person understands, and no longer claims a higher tier is faster.
- `apprentice-train` leaves `--effort` off by default, since it is auto-detected from memory, and names `--effort low` as the fix for an out-of-memory error.

## 0.1.1
- `apprentice-capture` is opt-in. Before any capture line or upload, the agent says that each call's input and output is sent to runapprentice.com and waits for an explicit yes. Capture is a visible line in the repo and is removed by deleting it. Secrets and personal data are not captured. If the service cannot be reached, the app keeps running and that call is not recorded.
- The same ask is stated in the other three skills, the README, and the submission notes wherever capture is described.

## 0.1.0
- First release: four skills (apprentice, capture, train, deploy).
- Manifests for Claude Code, Codex, Grok and Cursor.
