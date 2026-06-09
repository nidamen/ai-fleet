# ai-fleet: a free-first, never-stuck way to run coding agents

*A short whitepaper on the design, the economics, and why the timing matters.*

---

## 1. The one-line thesis

You can run coding agents all day, switch between frontier models without leaving your terminal, and pay almost nothing, if you route through a free-first model layer that can never silently break and never surprise-bills you. This repo is that layer, wired up to work on a fresh machine in one command.

## 2. Why now (the part most people miss)

Right now the major labs are competing for developers, so inference is sold far below its true cost, and aggregators like OpenRouter expose a tier of genuinely free models on top of that. For someone who lives in a terminal, that is the cheapest the most powerful tools in computing history will ever be.

That gap does not stay open forever. As these companies move toward public markets, the pressure shifts from "win developers" to "show margin," and subsidized or free token tiers are the first thing to tighten. The lesson is simple: the right time to build the muscle of driving everything through an agent is while the cost of practicing is near zero. First in, first out.

The point of this repo is to remove every excuse for not starting. No billing anxiety, no broken-auth rabbit holes, no setup tax.

## 3. What it actually is

A small, auditable toolkit (a launch guard, a handful of one-word launchers, a cost meter, and a status dashboard) that sits between your CLI agent and OpenRouter.

- **`ah`** launches [autohand](https://autohand.ai) on a **free** OpenRouter model by default and, in headless mode, automatically fails over across free models when one is rate-limited. A single command just keeps going, all at $0.
- **Paid is opt-in only.** `ah-gpt`, `ah-claude`, `ah-grok`, `ah-gemini` print the exact `$/M` rate and refuse to run until you type `yes`.
- **`aicost`** shows live session spend, balance, and the current model rate, so you always know the number.
- **`ai-status`** is a one-glance fleet dashboard of quotas, reset dates, and the launcher cheatsheet.

The full command list and quickstart live in [`README.md`](README.md). The recovery runbook (every file it touches and why) lives in [`SETUP.md`](SETUP.md).

## 4. Architecture

```
   you, in your terminal
            │
            ▼
   ┌─────────────────────┐     one-word launchers (ah, ah-claude, ...)
   │   launch guard      │     re-injects the API key from the Keychain
   │   (~/bin/autohand)  │     and re-pins a free model on every launch
   └─────────┬───────────┘
             ▼
        autohand  ──────────►  OpenRouter  ──────────►  any model
         (agent)               (one key,                (free tier by default,
                                many models)             paid only on confirm)

   side channels:
     aicost     → OpenRouter /credits   (live spend + balance)
     ai-status  → quotas.json           (fleet dashboard on shell open)
```

The design choice that makes it durable: the guard is a tiny wrapper that **shadows** the real autohand binary. On every launch it re-asserts the correct key and a free model from the macOS Keychain, then hands off to the real binary. Updating autohand never touches the guard, and a stale key or a cloud-sync clobber can never persist past the next launch. (`README.md` § "How it stays working" has the exact mechanism.)

Two optional layers compose on top, neither required for the CLIs above:

- **A Claude-Code-to-OpenRouter router.** If you prefer to drive from Claude Code rather than autohand, you can front the same OpenRouter key with a router shim and keep one billing surface. autohand remains the never-stuck, always-free floor.
- **An autonomous failover engine.** For "keep building even when a paid subscription caps out," a continuity supervisor can fail over Claude → Codex → OpenRouter (free) and resume work from a git handoff packet. It launches fresh headless agents; it does not keep a live interactive session alive across a flip. See [`SETUP.md`](SETUP.md).

## 5. Design principles

1. **Free-first.** The guard reverts to a `:free` model on every launch unless you have explicitly created an allow-paid marker. The default path is always $0.
2. **Never-stuck.** The two real-world failure modes (a revoked key, and autohand overwriting its config from a stale cloud copy) are both healed automatically on launch. You should never debug auth again.
3. **Cost-transparent.** Spend is always one command away, and paid models cannot run without a typed confirmation.
4. **No secrets in the repo.** The key is entered interactively and stored only in the Keychain (mirrored to a `chmod 600` file). `.gitignore` blocks every config and key path. The repo is safe to publish.
5. **Auditable and small.** Every script is short and readable. Nothing is obfuscated, nothing phones home.

## 6. The economics, concretely

- **Free models** on OpenRouter cost nothing to call; they rate-limit more aggressively than paid, which is exactly why headless `ah` auto-fails-over across them. For most coding-agent work, the free tier is enough to stay productive all day.
- **Paid models** are there when you need frontier quality for a hard task. You opt in per command, see the rate first, and watch the meter. No standing risk.
- **One key, many models.** OpenRouter gives you a single credential and a single balance across providers, so switching models is a launcher away, not an account-migration project.

## 7. Security model

The credential is the boundary. The key lives in the macOS Keychain (`service=openrouter`, `account=$USER`), never in git, never printed. Rotating it is one command (see [`SETUP.md`](SETUP.md)). Because the repo holds no secrets and hardcodes no user identity, it is safe to clone, fork, and publish.

## 8. Who this is for

Anyone who already lives in a CLI and moves fast in it: network, firewall, and infrastructure engineers especially. If you can script a device, you can drive an agent. The skill that compounds is feeding everything you know into the model and letting it do the work through your tools (your MCP servers, your scripts, your pipelines). This repo just makes the cost of building that habit effectively zero.

## 9. Get started

```sh
git clone https://github.com/nidamen/ai-fleet ai-fleet && cd ai-fleet
./bootstrap.sh     # installs the launchers, stores your OpenRouter key in the Keychain, wires your shell
# install autohand first if needed:  curl -fsSL https://autohand.ai/install.sh | sh
```

Open a new terminal and type `ah`. You are now running, for free.
