# ai-fleet

A free-first, never-stuck setup for running coding agents through **OpenRouter** (via [autohand](https://autohand.ai)) with a **live cost meter** and a one-glance fleet dashboard. Built so you can switch between models without ever exiting your CLI, never get surprise-billed, and bootstrap the whole thing on a fresh machine in one command.

> **New here?** Read [`WHITEPAPER.md`](WHITEPAPER.md) for the why, the design, and the economics in plain language. Then come back here for the commands.

## What it gives you

- **`ah`** — autohand on a **free** OpenRouter model (default `openai/gpt-oss-120b:free`). Always works: a launch guard re-injects your API key from the Keychain and re-pins the free model on every launch, so a stale key or a cloud-sync clobber can never break you. In headless mode (`ah -p "task"`) it **auto-fails-over across free models** if one is rate-limited, so a single `ah` just keeps going — all $0. (Live interactive chat can't auto-flip; use `/model` or a paid launcher.)
- **Paid only when you confirm** — `ah-gpt`, `ah-claude`, `ah-grok`, `ah-gemini` show the exact `$/M` price and refuse to run until you type `yes`. `ah` / `ah-free` are always free.
- **`aicost`** — exactly what you're paying: live OpenRouter session spend, balance, current model rate, plus your subscription quotas. `aicost --watch` is a live ticker; `aicost --reset` zeroes the session.
- **`ai-status`** — fleet dashboard: per-provider quota + reset dates + the launcher cheatsheet. Shows automatically when you open [Ghostty](https://ghostty.org).
- **Bottom-of-prompt status line** — `🤖 <model> FREE|PAID · sess $X · OR $balance` on every prompt.

## Quickstart

```sh
git clone <this-repo> ai-fleet && cd ai-fleet
./bootstrap.sh           # installs scripts to ~/bin, prompts for your OpenRouter key (-> Keychain only), wires ~/.zshrc
# (install autohand first if needed:  curl -fsSL https://autohand.ai/install.sh | sh )
```
Open a new terminal, then just type **`ah`**.

## Commands

| Command | What it does | Cost |
|---|---|---|
| `ah` / `ah-free` | autohand on the free default; `ah -p` auto-fails-over across free models on rate-limit | **$0** |
| `ah-gpt` / `ah-claude` / `ah-grok` / `ah-gemini` | autohand on that paid model (confirms first) | metered |
| `ai-status` | fleet dashboard (quotas, resets, launchers) | $0 |
| `aicost` | spend dashboard; `--watch` live; `--reset` zero session | $0 |
| `/model` (inside autohand) | switch model mid-session, no exit | — |

## Free-only policy

OpenRouter stays **free unless you explicitly opt in to paid**:
- The guard reverts the config model to a `:free` model on launch unless `~/.autohand/.allow-paid` exists.
- Paid launchers require a typed `yes` (bypass with `PAID_OK=1` or the `.allow-paid` marker).
- Pinned default lives in `~/.autohand/.preferred-model` (change it there).

## How it stays working

`~/bin/autohand` is a tiny wrapper that **shadows** the real `~/.local/bin/autohand`. On every launch it (1) reads your OpenRouter key from the macOS Keychain (`security -s openrouter -a $USER`) and (2) pins your preferred free model, then `exec`s the real binary. Updating autohand never touches the guard. Per-run `--model` (the launchers) overrides for that run.

## Security

**No secrets live in this repo.** The API key is read interactively by `bootstrap.sh` and stored **only** in the macOS Keychain (and a `chmod 600 ~/.config/openrouter/key`). `.gitignore` blocks `config.json`, `*.key`, caches, and the `.allow-paid` marker. If you ever need a new key: create one at https://openrouter.ai/keys and run `security add-generic-password -U -s openrouter -a $USER -w <key>`.

## Optional: autonomous failover engine

For hands-off "keep building even when a subscription caps out," pair this with a continuity supervisor that fails over Claude → Codex → OpenRouter (free) and resumes work via git handoff. That's a separate background daemon (not required for the CLIs above). See `SETUP.md`.
