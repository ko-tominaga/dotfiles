#!/bin/bash

# Setup AI agent rules and prompts for codex and claude
echo "Setting up AI agent configuration..."

SHARED_PROMPTS_DIR="$HOME/.ai_agents"
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

# Create directories if they don't exist
mkdir -p "$CODEX_PROMPTS_DIR"
mkdir -p "$CLAUDE_COMMANDS_DIR"

# Create symlinks for shared prompts in codex (flattened structure, excluding rules.md)
find "$SHARED_PROMPTS_DIR/prompts" -name "*.md" -type f | while read -r prompt_file; do
    filename=$(basename "$prompt_file")
    symlink_path="$CODEX_PROMPTS_DIR/$filename"
    
    if [ ! -e "$symlink_path" ]; then
        ln -s "$prompt_file" "$symlink_path"
        echo "Created symlink: $symlink_path -> $prompt_file"
    fi
done

# Create symlinks for shared prompts in claude (flattened structure, excluding rules.md)
find "$SHARED_PROMPTS_DIR/prompts" -name "*.md" -type f | while read -r prompt_file; do
    filename=$(basename "$prompt_file")
    symlink_path="$CLAUDE_COMMANDS_DIR/$filename"
    
    if [ ! -e "$symlink_path" ]; then
        ln -s "$prompt_file" "$symlink_path"
        echo "Created symlink: $symlink_path -> $prompt_file"
    fi
done

# Create symlink for rules.md in codex (as AGENTS.md)
RULES_FILE="$SHARED_PROMPTS_DIR/rules.md"
if [ -f "$RULES_FILE" ]; then
    CODEX_RULES_LINK="$HOME/.codex/AGENTS.md"
    if [ ! -e "$CODEX_RULES_LINK" ]; then
        ln -s "$RULES_FILE" "$CODEX_RULES_LINK"
        echo "Created symlink: $CODEX_RULES_LINK -> $RULES_FILE"
    fi
fi

# Create symlink for rules.md in claude (as CLAUDE.md)
if [ -f "$RULES_FILE" ]; then
    CLAUDE_RULES_LINK="$HOME/.claude/CLAUDE.md"
    if [ ! -e "$CLAUDE_RULES_LINK" ]; then
        ln -s "$RULES_FILE" "$CLAUDE_RULES_LINK"
        echo "Created symlink: $CLAUDE_RULES_LINK -> $RULES_FILE"
    fi
fi

echo "AI agent configuration setup completed!" 