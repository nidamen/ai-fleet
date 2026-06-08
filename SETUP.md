# SETUP / Recovery runbook

Everything needed to rebuild this from scratch, and why each piece exists. The goal: never spend hours re-debugging again.

## The original problem (root cause)

autohand authenticates to OpenRouter with a key stored in `~/.autohand/config.json`. Two failure modes bit hard:
1. **A revoked key** — the stored OpenRouter key had been deleted server-side, so every call returned `401 "User not found"` shown as **"Missing Authentication header"**. Fix = mint a new key; there's nothing to "repair" in config.
2. **autohand cloud-sync clobber** — on a fresh login + "restore from cloud", autohand overwrites `config.json` with a stale copy (old key + slow model). Its sync *upload* is broken, so you can't fix the cloud copy from the CLI.

The durable fix for both is the **launch guard** (`bin/autohand`): it re-asserts the correct key + free model from the Keychain on every launch, so neither failure mode can persist.

## Key facts

- autohand reads the OpenRouter key **only** from `~/.autohand/config.json` `openrouter.apiKey` (it ignores `OPENROUTER_API_KEY`). A **plaintext** `sk-or-v1-...` value works directly.
- The key is stored in the macOS **Keychain** (`service=openrouter`, `account=$USER`) and mirrored to `~/.config/openrouter/key` (chmod 600). **Never** in git.
- Free models work with any valid key; they rate-limit more than paid. Default free model: `openai/gpt-oss-120b:free`.

## Mint / rotate the OpenRouter key

1. https://openrouter.ai/keys → **Create Key** → copy it (shown once).
2. `security add-generic-password -U -s openrouter -a "$USER" -w '<key>'`
3. `printf '%s' '<key>' > ~/.config/openrouter/key && chmod 600 ~/.config/openrouter/key`
4. Next `ah` launch heals `config.json` automatically. Verify: `curl -s https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer $(security find-generic-password -s openrouter -a $USER -w)"` → HTTP 200.

## Bootstrap a new machine

```sh
# 1. autohand itself
curl -fsSL https://autohand.ai/install.sh | sh
# 2. this toolkit
git clone <this-repo> ai-fleet && cd ai-fleet && ./bootstrap.sh
# 3. new terminal -> `ah`
```

## Files this manages

| Path | Purpose | In git? |
|---|---|---|
| `~/bin/autohand` | launch guard (heals key + pins free model) | yes (generic) |
| `~/bin/ah*`, `ai-status`, `aicost`, `.ah-paid-run` | launchers + HUD | yes |
| `~/.autohand/.preferred-model` | pinned default model | example only |
| `~/.autohand/.allow-paid` | marker: allow paid models in autohand | **no** (you create it) |
| `~/.autohand/config.json` | autohand config (holds plaintext key) | **no** (gitignored) |
| `~/.config/ai-status/quotas.json` | Codex/Grok status + reset dates for the dashboard | example only |
| `~/.config/openrouter/key` | key mirror | **no** |
| Keychain `openrouter/$USER` | source of truth for the key | n/a |

## Cost meter notes

`aicost` computes session spend as `total_usage - baseline` from OpenRouter `/api/v1/credits`. OpenRouter bills with a few-second lag, so the meter is near-real-time (updates right after each call), not per-token mid-generation — that's the most precise an external tool can be. `aicost --reset` sets the baseline to "now".

## Autonomous failover engine (optional, separate)

A continuity supervisor can keep work moving when a subscription caps out: it scores Claude / Codex / OpenRouter availability and launches a fresh **headless** agent (`codex exec` / `claude -p` / codex→OpenRouter) from a handoff packet, mirroring the work tree + a "resume from git" packet on every flip. Key points if you run one:
- OpenRouter fallback should be **free by default**; gate any paid selection behind an explicit marker file.
- It launches fresh headless agents — it does **not** keep a live interactive session alive across a flip.
- Feed it work via its backlog; it idles when the backlog is empty.

## Troubleshooting

- **"Missing Authentication header" again** → the Keychain key was revoked. Mint a new one (above).
- **autohand stuck on a slow/old model** → `cat ~/.autohand/.preferred-model` should be a `:free` model; the guard re-pins it each launch.
- **Paid model won't run** → that's by design; type `yes` at the prompt, or `PAID_OK=1 ah-grok ...`, or `touch ~/.autohand/.allow-paid`.
- **Cost line shows `$?`** → run `aicost --refresh` once (network) to warm the cache.
