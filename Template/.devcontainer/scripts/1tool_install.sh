#!/bin/bash

npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://cursor.com/install | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
