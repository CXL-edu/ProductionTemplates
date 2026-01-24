#!/bin/bash

mkdir -p ~/.local/bin

npm install -g @anthropic-ai/claude-code || true
npm install -g @openai/codex || true
curl -fsSL https://opencode.ai/install | bash || true
curl -fsSL https://cursor.com/install | bash || true

# 更新 PATH
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.local/bin:$PATH"
