#!/usr/bin/env bash
set -euo pipefail

npm install -g @anthropic-ai/claude-code
npm install -g codeburn

claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add obra/superpowers

claude plugin install context7@claude-plugins-official
claude plugin install superpowers@superpowers-dev
