#!/bin/bash

# Setup AI agent rules and prompts for codex and claude
echo "Setting up AI agent configuration..."

SHARED_PROMPTS_DIR="$HOME/.ai_agents"
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

# Create directories if they don't exist
mkdir -p "$CODEX_PROMPTS_DIR"
mkdir -p "$CLAUDE_COMMANDS_DIR"

# Create hard links for shared prompts in codex (flattened structure, excluding rules.md)
find "$SHARED_PROMPTS_DIR/prompts" -name "*.md" -type f | while read -r prompt_file; do
    filename=$(basename "$prompt_file")
    hardlink_path="$CODEX_PROMPTS_DIR/$filename"
    
    if [ ! -e "$hardlink_path" ]; then
        ln "$prompt_file" "$hardlink_path"
        echo "Created hard link: $hardlink_path -> $prompt_file"
    fi
done

# Create hard links for shared prompts in claude (flattened structure, excluding rules.md)
find "$SHARED_PROMPTS_DIR/prompts" -name "*.md" -type f | while read -r prompt_file; do
    filename=$(basename "$prompt_file")
    hardlink_path="$CLAUDE_COMMANDS_DIR/$filename"
    
    if [ ! -e "$hardlink_path" ]; then
        ln "$prompt_file" "$hardlink_path"
        echo "Created hard link: $hardlink_path -> $prompt_file"
    fi
done

# Create hard link for rules.md in codex (as AGENTS.md)
RULES_FILE="$SHARED_PROMPTS_DIR/rules.md"
if [ -f "$RULES_FILE" ]; then
    CODEX_RULES_LINK="$HOME/.codex/AGENTS.md"
    if [ ! -e "$CODEX_RULES_LINK" ]; then
        ln "$RULES_FILE" "$CODEX_RULES_LINK"
        echo "Created hard link: $CODEX_RULES_LINK -> $RULES_FILE"
    fi
fi

# Create hard link for rules.md in claude (as CLAUDE.md)
if [ -f "$RULES_FILE" ]; then
    CLAUDE_RULES_LINK="$HOME/.claude/CLAUDE.md"
    if [ ! -e "$CLAUDE_RULES_LINK" ]; then
        ln "$RULES_FILE" "$CLAUDE_RULES_LINK"
        echo "Created hard link: $CLAUDE_RULES_LINK -> $RULES_FILE"
    fi
fi

echo "AI agent configuration setup completed!" 