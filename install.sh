#!/bin/bash

################################################################################
# Autopilot Installation Script
#
# Interactive setup wizard for Autopilot in Cursor, Claude Code, or OpenCode
# Creates project configuration and initializes Autopilot in your repository
#
# Usage:
#   bash install.sh                    # Interactive mode
#   bash install.sh --project-only     # Skip IDE setup
#   bash install.sh --help             # Show options
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
AUTOPILOT_VERSION="1.0.0-phase1"

# State
IDE_CHOICE=""
INSTALL_SCOPE=""
JIRA_BOARD_ID=""
JIRA_BOARD_NAME=""
GIT_MAIN_BRANCH="main"
GIT_RELEASE_BRANCH="release/main"
TEAM_NAME=""
ANALYTICS_LEAD=""

################################################################################
# Utility Functions
################################################################################

print_header() {
  echo ""
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} $1"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_section() {
  echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

show_help() {
  cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║              Autopilot Installation Script                        ║
╚════════════════════════════════════════════════════════════════════╝

USAGE:
  bash install.sh [OPTIONS]

OPTIONS:
  --help              Show this help message
  --project-only      Skip IDE setup, configure project only
  --quiet             Skip confirmation prompts (use defaults)
  --force             Overwrite existing configuration

EXAMPLES:
  bash install.sh
    → Full interactive setup (IDE + project config)

  bash install.sh --project-only
    → Project configuration only (no IDE setup)

  bash install.sh --quiet
    → Use all defaults (non-interactive)

WHAT IT DOES:
  1. Asks which IDE (Cursor, Claude Code, OpenCode)
  2. Asks installation scope (global or project-local)
  3. Copies Autopilot files to appropriate location
  4. Creates .autopilot/config.json with your settings
  5. Verifies installation
  6. Shows next steps

OUTPUT:
  Creates: .autopilot/config.json with:
    - IDE configuration
    - JIRA board settings
    - Git branch configuration
    - Team information
    - Installation metadata

REQUIREMENTS:
  - Git configured (git config user.name)
  - dbt CLI installed (dbt --version)
  - Write permissions to project directory

For more info, see: README.md
EOF
  exit 0
}

################################################################################
# Validation Functions
################################################################################

validate_git_setup() {
  print_section "Validating Git setup..."

  if ! git config user.name > /dev/null 2>&1; then
    print_error "Git user not configured. Run: git config user.name 'Your Name'"
    return 1
  fi

  if ! git config user.email > /dev/null 2>&1; then
    print_error "Git email not configured. Run: git config user.email 'you@example.com'"
    return 1
  fi

  print_success "Git is configured"
  return 0
}

validate_dbt_setup() {
  print_section "Validating dbt CLI..."

  if ! command -v dbt &> /dev/null; then
    print_error "dbt CLI not found. Install from: https://docs.getdbt.com/docs/core/installation"
    return 1
  fi

  if ! dbt --version > /dev/null 2>&1; then
    print_error "dbt is installed but not working. Check your installation."
    return 1
  fi

  print_success "dbt CLI is installed"
  return 0
}

validate_repo_structure() {
  print_section "Validating repository structure..."

  if [ ! -d "$PROJECT_ROOT/.git" ]; then
    print_error "Not a Git repository. Run: git init"
    return 1
  fi

  if [ ! -f "$PROJECT_ROOT/dbt_project.yml" ]; then
    print_info "Note: dbt_project.yml not found. Is this a dbt project?"
  fi

  print_success "Repository structure looks good"
  return 0
}

################################################################################
# Interactive Prompts
################################################################################

prompt_ide_choice() {
  print_section "Which IDE are you using?"
  echo ""
  echo "  1) Cursor (Claude Code)"
  echo "  2) OpenCode"
  echo "  3) Both (install to both)"
  echo ""

  read -p "Enter choice (1-3): " choice

  case $choice in
    1)
      IDE_CHOICE="cursor"
      print_success "Selected: Cursor"
      ;;
    2)
      IDE_CHOICE="opencode"
      print_success "Selected: OpenCode"
      ;;
    3)
      IDE_CHOICE="both"
      print_success "Selected: Both Cursor and OpenCode"
      ;;
    *)
      print_error "Invalid choice. Please enter 1, 2, or 3."
      prompt_ide_choice
      ;;
  esac
}

prompt_install_scope() {
  print_section "Where do you want to install Autopilot?"
  echo ""
  echo "  1) Project-local  (in this repo at .cursor/, shared/)"
  echo "  2) Global         (in ~/.cursor/, ~/.shared/)"
  echo "  3) Let me choose  (select for each IDE)"
  echo ""

  read -p "Enter choice (1-3): " choice

  case $choice in
    1)
      INSTALL_SCOPE="project"
      print_success "Selected: Project-local installation"
      ;;
    2)
      INSTALL_SCOPE="global"
      print_success "Selected: Global installation"
      ;;
    3)
      INSTALL_SCOPE="custom"
      print_success "Selected: Custom per-IDE"
      ;;
    *)
      print_error "Invalid choice. Please enter 1, 2, or 3."
      prompt_install_scope
      ;;
  esac
}

prompt_jira_config() {
  print_section "JIRA Configuration"
  echo ""
  echo "These settings help Autopilot connect to your JIRA board."
  echo ""

  read -p "JIRA Board Name (e.g., Analytics, AE): " JIRA_BOARD_NAME
  read -p "JIRA Board ID (e.g., DAAENG, TSK): " JIRA_BOARD_ID

  # Validate format (uppercase, alphanumeric)
  if ! [[ "$JIRA_BOARD_ID" =~ ^[A-Z][A-Z0-9]*$ ]]; then
    print_error "Board ID should be uppercase alphanumeric (e.g., DAAENG, TSK)"
    prompt_jira_config
    return
  fi

  print_success "JIRA configuration: $JIRA_BOARD_NAME ($JIRA_BOARD_ID)"
}

prompt_git_config() {
  print_section "Git Configuration"
  echo ""
  echo "Autopilot creates task branches from your release branch."
  echo ""

  read -p "Main branch name (default: main): " main_input
  if [ -n "$main_input" ]; then
    GIT_MAIN_BRANCH="$main_input"
  fi

  read -p "Release branch name (default: release/main): " release_input
  if [ -n "$release_input" ]; then
    GIT_RELEASE_BRANCH="$release_input"
  fi

  print_success "Git configuration:"
  echo "  Main branch: $GIT_MAIN_BRANCH"
  echo "  Release branch: $GIT_RELEASE_BRANCH"
}

prompt_team_info() {
  print_section "Team Information"
  echo ""

  read -p "Team name (e.g., Analytics Engineering, Data): " TEAM_NAME
  read -p "Analytics lead email: " ANALYTICS_LEAD

  print_success "Team: $TEAM_NAME (Lead: $ANALYTICS_LEAD)"
}

################################################################################
# Installation Functions
################################################################################

install_cursor_agents() {
  local target_dir="$1"

  print_section "Installing Cursor agents..."

  mkdir -p "$target_dir/.cursor/agents"
  mkdir -p "$target_dir/.cursor/rules"

  cp "$SCRIPT_DIR/.cursor/agents"/*.md "$target_dir/.cursor/agents/" || {
    print_error "Failed to copy Cursor agents"
    return 1
  }

  cp "$SCRIPT_DIR/.cursor/rules"/*.mdc "$target_dir/.cursor/rules/" || {
    print_error "Failed to copy Cursor rules"
    return 1
  }

  print_success "Cursor agents installed"
  return 0
}

install_opencode_commands() {
  local target_dir="$1"

  print_section "Installing OpenCode commands..."

  mkdir -p "$target_dir/.opencode/command"

  cp "$SCRIPT_DIR/.opencode/command"/*.md "$target_dir/.opencode/command/" || {
    print_error "Failed to copy OpenCode commands"
    return 1
  }

  print_success "OpenCode commands installed"
  return 0
}

install_shared_files() {
  local target_dir="$1"

  print_section "Installing shared files..."

  mkdir -p "$target_dir/shared/schemas"
  mkdir -p "$target_dir/shared/prompts"

  cp -r "$SCRIPT_DIR/shared/schemas"/* "$target_dir/shared/schemas/" || {
    print_error "Failed to copy schemas"
    return 1
  }

  cp -r "$SCRIPT_DIR/shared/prompts"/* "$target_dir/shared/prompts/" || {
    print_error "Failed to copy prompts"
    return 1
  }

  print_success "Shared files installed"
  return 0
}

create_config_file() {
  local config_dir="$1"

  print_section "Creating configuration..."

  mkdir -p "$config_dir"

  # Create config.json
  cat > "$config_dir/config.json" << EOF
{
  "version": "$AUTOPILOT_VERSION",
  "installed_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "installed_by": "$(git config user.name)",

  "ide": {
    "name": "$IDE_CHOICE",
    "install_scope": "$INSTALL_SCOPE"
  },

  "jira": {
    "board_name": "$JIRA_BOARD_NAME",
    "board_id": "$JIRA_BOARD_ID",
    "mcp_configured": false,
    "mcp_docs": "https://github.com/your-org/jira-mcp"
  },

  "git": {
    "main_branch": "$GIT_MAIN_BRANCH",
    "release_branch": "$GIT_RELEASE_BRANCH"
  },

  "team": {
    "name": "$TEAM_NAME",
    "analytics_lead": "$ANALYTICS_LEAD"
  },

  "features": {
    "state_persistence": true,
    "git_safety": true,
    "hard_stops": true,
    "resumability": true
  }
}
EOF

  if [ ! -f "$config_dir/config.json" ]; then
    print_error "Failed to create config.json"
    return 1
  fi

  print_success "Configuration created: $config_dir/config.json"
  return 0
}

create_gitignore() {
  local target_dir="$1"

  print_section "Setting up .gitignore..."

  if [ -f "$target_dir/.gitignore" ]; then
    # Append to existing .gitignore if .autopilot/ not already there
    if ! grep -q "^\.autopilot/" "$target_dir/.gitignore"; then
      echo "" >> "$target_dir/.gitignore"
      echo "# Autopilot runtime state" >> "$target_dir/.gitignore"
      echo ".autopilot/" >> "$target_dir/.gitignore"
      echo "!.autopilot/.gitkeep" >> "$target_dir/.gitignore"
      print_success "Added .autopilot/ to existing .gitignore"
    else
      print_info ".autopilot/ already in .gitignore"
    fi
  else
    # Create new .gitignore
    cp "$SCRIPT_DIR/.gitignore" "$target_dir/.gitignore"
    print_success "Created new .gitignore with Autopilot rules"
  fi

  # Ensure .autopilot/.gitkeep exists
  mkdir -p "$target_dir/.autopilot"
  touch "$target_dir/.autopilot/.gitkeep"

  return 0
}

verify_installation() {
  local target_dir="$1"

  print_section "Verifying installation..."

  local errors=0

  # Check Cursor files
  if [ "$IDE_CHOICE" = "cursor" ] || [ "$IDE_CHOICE" = "both" ]; then
    if [ ! -d "$target_dir/.cursor/agents" ]; then
      print_error ".cursor/agents not found"
      ((errors++))
    fi

    if [ ! -d "$target_dir/.cursor/rules" ]; then
      print_error ".cursor/rules not found"
      ((errors++))
    fi
  fi

  # Check OpenCode files
  if [ "$IDE_CHOICE" = "opencode" ] || [ "$IDE_CHOICE" = "both" ]; then
    if [ ! -d "$target_dir/.opencode/command" ]; then
      print_error ".opencode/command not found"
      ((errors++))
    fi
  fi

  # Check shared files
  if [ ! -d "$target_dir/shared/schemas" ]; then
    print_error "shared/schemas not found"
    ((errors++))
  fi

  # Check config
  if [ ! -f "$target_dir/.autopilot/config.json" ]; then
    print_error ".autopilot/config.json not found"
    ((errors++))
  fi

  if [ $errors -eq 0 ]; then
    print_success "Installation verified ✅"
    return 0
  else
    print_error "Installation verification failed with $errors errors"
    return 1
  fi
}

################################################################################
# Main Installation Flow
################################################################################

main() {
  print_header "Autopilot Installation Wizard"

  # Show welcome
  cat << 'EOF'
Welcome to Autopilot! This setup wizard will:

  1. Check prerequisites (Git, dbt)
  2. Ask which IDE you're using
  3. Configure JIRA and Git settings
  4. Install Autopilot to your repository
  5. Create configuration file
  6. Verify everything is working

Let's get started! ✨

EOF

  # Check prerequisites
  print_info "Checking prerequisites..."
  validate_git_setup || exit 1
  validate_dbt_setup || exit 1
  validate_repo_structure || exit 1
  echo ""

  # Skip IDE setup if --project-only
  if [ "$1" = "--project-only" ]; then
    print_info "Skipping IDE setup (--project-only)"
    IDE_CHOICE="skip"
  else
    # Ask IDE choice
    prompt_ide_choice
    echo ""

    # Ask installation scope
    prompt_install_scope
    echo ""
  fi

  # Determine target directory
  local target_dir
  if [ "$INSTALL_SCOPE" = "global" ]; then
    target_dir="$HOME"
    print_info "Installing to: $target_dir"
  else
    target_dir="$PROJECT_ROOT"
    print_info "Installing to: $target_dir"
  fi
  echo ""

  # Ask for configuration
  prompt_jira_config
  echo ""

  prompt_git_config
  echo ""

  prompt_team_info
  echo ""

  # Summary and confirmation
  print_header "Installation Summary"

  cat << EOF
IDE:            $IDE_CHOICE
Scope:          $INSTALL_SCOPE
Target:         $target_dir

JIRA Board:     $JIRA_BOARD_NAME ($JIRA_BOARD_ID)
Git Branches:   $GIT_MAIN_BRANCH → $GIT_RELEASE_BRANCH
Team:           $TEAM_NAME

EOF

  read -p "Proceed with installation? (y/n): " confirm
  if [ "$confirm" != "y" ]; then
    print_error "Installation cancelled"
    exit 0
  fi
  echo ""

  # Perform installation
  print_header "Installing Autopilot"

  if [ "$IDE_CHOICE" = "cursor" ] || [ "$IDE_CHOICE" = "both" ]; then
    install_cursor_agents "$target_dir" || exit 1
  fi

  if [ "$IDE_CHOICE" = "opencode" ] || [ "$IDE_CHOICE" = "both" ]; then
    install_opencode_commands "$target_dir" || exit 1
  fi

  install_shared_files "$target_dir" || exit 1
  echo ""

  # Create configuration
  create_config_file "$target_dir/.autopilot" || exit 1
  create_gitignore "$target_dir" || exit 1
  echo ""

  # Verify
  verify_installation "$target_dir" || exit 1
  echo ""

  # Show next steps
  print_header "Installation Complete! ✅"

  cat << EOF
Your Autopilot is ready to use!

📍 Configuration saved to: $target_dir/.autopilot/config.json

🚀 Next Steps:

  1. Restart your IDE (Cursor/OpenCode)
     → Fully quit and reopen for command discovery

  2. Verify commands are available:
     → In Cursor: Type /autopilot: (should show 6 commands)
     → In OpenCode: Type autopilot (should show commands)

  3. Test with a sample task:
     → /autopilot:pull TSK-TEST

  4. See results:
     → cat .autopilot/state.json (verify state file created)
     → git branch -v (verify task branch created)

📚 Documentation:
  • README.md           - Quick start guide
  • HOW_TO_USE.md       - Command reference
  • QUICK_TEST.md       - 5-minute validation
  • TESTING_GUIDE.md    - Comprehensive testing

⚙️  Configuration:
  • .autopilot/config.json  - Your settings
  • .cursor/agents/         - Cursor skills
  • .opencode/command/      - OpenCode commands
  • shared/schemas/         - JSON validation

Need help?
  → See README.md for troubleshooting
  → Check TESTING_GUIDE.md for diagnostics

Happy automating! 🎉

EOF

}

################################################################################
# Script Entry Point
################################################################################

# Handle flags
case "${1:-}" in
  --help)
    show_help
    ;;
  --project-only|--quiet|--force)
    main "$@"
    ;;
  *)
    main "$@"
    ;;
esac
