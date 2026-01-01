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

# Create hard links for skills directory structure
SKILLS_SOURCE_DIR="$SHARED_PROMPTS_DIR/skills"
if [ -d "$SKILLS_SOURCE_DIR" ]; then
    # Create skills directory for codex
    CODEX_SKILLS_DIR="$HOME/.codex/skills"
    mkdir -p "$CODEX_SKILLS_DIR"

    # Create hard links for all files in skills directory (preserving directory structure)
    find "$SKILLS_SOURCE_DIR" -type f | while read -r skill_file; do
        relative_path="${skill_file#$SKILLS_SOURCE_DIR/}"
        target_dir="$CODEX_SKILLS_DIR/$(dirname "$relative_path")"
        mkdir -p "$target_dir"
        hardlink_path="$CODEX_SKILLS_DIR/$relative_path"

        # Remove existing file if it exists and create new hard link
        if [ -e "$hardlink_path" ]; then
            rm -f "$hardlink_path"
        fi
        ln "$skill_file" "$hardlink_path"
        echo "Created hard link: $hardlink_path -> $skill_file"
    done

    # Create skills directory for claude
    CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
    mkdir -p "$CLAUDE_SKILLS_DIR"

    # Create hard links for all files in skills directory (preserving directory structure)
    find "$SKILLS_SOURCE_DIR" -type f | while read -r skill_file; do
        relative_path="${skill_file#$SKILLS_SOURCE_DIR/}"
        target_dir="$CLAUDE_SKILLS_DIR/$(dirname "$relative_path")"
        mkdir -p "$target_dir"
        hardlink_path="$CLAUDE_SKILLS_DIR/$relative_path"

        # Remove existing file if it exists and create new hard link
        if [ -e "$hardlink_path" ]; then
            rm -f "$hardlink_path"
        fi
        ln "$skill_file" "$hardlink_path"
        echo "Created hard link: $hardlink_path -> $skill_file"
    done
fi

echo "AI agent configuration setup completed!" 