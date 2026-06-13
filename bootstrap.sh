#!/bin/sh
# ai-fleet bootstrap — get the whole free-first OpenRouter + autohand setup running on a
# fresh Mac in one shot. Idempotent. Stores NO secrets in the repo: the OpenRouter API key
# is read interactively and saved ONLY to the macOS Keychain.
#
#   git clone <this repo> && cd ai-fleet && ./bootstrap.sh
#
set -eu
REPO="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/bin"
ACCOUNT="${AI_FLEET_OR_ACCOUNT:-$USER}"

echo "==> ai-fleet bootstrap"

# 1) Install the launcher + tool scripts into ~/bin
mkdir -p "$BIN"
cp -f "$REPO"/bin/* "$REPO"/bin/.ah-paid-run "$BIN"/ 2>/dev/null || cp -f "$REPO"/bin/* "$BIN"/
chmod 755 "$BIN"/autohand "$BIN"/ah "$BIN"/ah-* "$BIN"/ai-status "$BIN"/aicost "$BIN"/.ah-paid-run 2>/dev/null || true
echo "    installed scripts -> $BIN"

# 2) Ensure ~/bin is first in PATH (so the guard shadows the real autohand binary)
case ":$PATH:" in *":$BIN:"*) : ;; *) echo "    NOTE: add 'export PATH=\"\$HOME/bin:\$PATH\"' to your shell rc" ;; esac

# 3) autohand itself (the real binary the guard wraps)
if ! [ -x "$HOME/.local/bin/autohand" ]; then
  echo "    autohand not found at ~/.local/bin/autohand"
  echo "    install it first:  curl -fsSL https://autohand.ai/install.sh | sh"
fi

# 4) OpenRouter API key -> Keychain ONLY (never written to disk in the repo)
if security find-generic-password -s openrouter -a "$ACCOUNT" -w >/dev/null 2>&1; then
  echo "    OpenRouter key already in Keychain (service=openrouter account=$ACCOUNT)"
else
  # Prompt ONLY when there's a real terminal, and with a timeout, so an UNATTENDED
  # run (no TTY, e.g. over `tailscale ssh` or piped) never hangs invisibly waiting
  # for a paste that will never come. No TTY -> skip cleanly, set the key later.
  OR_KEY=""
  if [ -t 0 ]; then
    printf "    Paste your OpenRouter API key (from https://openrouter.ai/keys), or leave blank to skip: "
    stty -echo 2>/dev/null || true; read -t 120 OR_KEY 2>/dev/null || true; stty echo 2>/dev/null || true; echo
  else
    echo "    no terminal (unattended) -> skipping OpenRouter key prompt; set it later."
  fi
  if [ -n "${OR_KEY:-}" ]; then
    security add-generic-password -U -s openrouter -a "$ACCOUNT" -w "$OR_KEY"
    mkdir -p "$HOME/.config/openrouter"; printf '%s' "$OR_KEY" > "$HOME/.config/openrouter/key"; chmod 600 "$HOME/.config/openrouter/key"
    echo "    saved key to Keychain + ~/.config/openrouter/key (chmod 600)"
  else echo "    skipped (set it later: security add-generic-password -U -s openrouter -a $ACCOUNT -w <key>)"; fi
fi

# 5) Seed config (free default; quotas display) and autohand plaintext key from Keychain
mkdir -p "$HOME/.config/ai-status" "$HOME/.autohand"
[ -f "$HOME/.autohand/.preferred-model" ] || cp "$REPO/examples/preferred-model.example" "$HOME/.autohand/.preferred-model"
[ -f "$HOME/.config/ai-status/quotas.json" ] || cp "$REPO/examples/quotas.example.json" "$HOME/.config/ai-status/quotas.json"
if [ -f "$HOME/.autohand/config.json" ]; then
  KEY="$(security find-generic-password -s openrouter -a "$ACCOUNT" -w 2>/dev/null || true)"
  [ -n "$KEY" ] && /usr/bin/python3 - "$HOME/.autohand/config.json" "$KEY" <<'PY' || true
import json,sys
p,k=sys.argv[1],sys.argv[2]
c=json.load(open(p)); c.setdefault("openrouter",{})["apiKey"]=k
c["openrouter"].setdefault("model","openai/gpt-oss-120b:free")
open(p,"w").write(json.dumps(c,indent=2)+"\n")
PY
fi

# 6) Wire the zshrc snippet (banner + cost line) if not already present
RC="$HOME/.zshrc"
if ! grep -qF 'ai-fleet banner' "$RC" 2>/dev/null; then
  cat "$REPO/examples/zshrc-snippet.zsh" >> "$RC"
  echo "    appended dashboard banner + cost line to ~/.zshrc"
fi

echo "==> done. Open a new terminal, then:  ah   (free)   ·   ai-status   ·   aicost"
