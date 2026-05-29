#!/usr/bin/env bash
set -euo pipefail

# Mounted .claude volume is root-owned on first creation — hand it to node.
if [ "$(stat -c %U /home/node/.claude)" != "node" ]; then
  sudo chown -R node:node /home/node/.claude
fi

# Keep ~/.claude.json (login + per-project history) inside the persisted volume,
# then symlink it back into $HOME so it survives rebuilds.
if [ ! -e /home/node/.claude/.claude.json ]; then
  if [ -f /home/node/.claude.json ] && [ ! -L /home/node/.claude.json ]; then
    mv /home/node/.claude.json /home/node/.claude/.claude.json   # seed from existing
  else
    echo '{}' > /home/node/.claude/.claude.json                  # first ever run
  fi
fi
ln -sf /home/node/.claude/.claude.json /home/node/.claude.json

npm install -g @anthropic-ai/claude-code
npm install -g codeburn

claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add obra/superpowers

claude plugin install context7@claude-plugins-official
claude plugin install superpowers@superpowers-dev
