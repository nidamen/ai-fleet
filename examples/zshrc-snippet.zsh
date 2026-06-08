# --- ai-fleet: paste into ~/.zshrc (or `source` this file) ---
# 1) Make sure ~/bin (where the ai-fleet scripts live) is first in PATH:
export PATH="$HOME/bin:$PATH"

# 2) Show the fleet dashboard when opening Ghostty (quotas, reset dates, launchers):
if [[ -o interactive && -n "$GHOSTTY_RESOURCES_DIR" ]] && command -v ai-status >/dev/null 2>&1; then
  ai-status --fast
fi

# 3) Persistent bottom-right status: model · FREE/PAID · live session spend · OpenRouter balance.
if [[ -o interactive ]] && command -v aicost >/dev/null 2>&1; then
  autoload -Uz add-zsh-hook
  _ai_cost_rprompt() { RPROMPT="$(aicost --line 2>/dev/null)" }
  add-zsh-hook precmd _ai_cost_rprompt
fi
