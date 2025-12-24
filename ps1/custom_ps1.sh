# /etc/profile.d/custom_ps1.sh

# paste the following code in .bashrc
#if [ -f /etc/profile.d/custom_ps1.sh ]; then
#   . /etc/profile.d/custom_ps1.sh
#fi

# Define color codes
RESET="\[\033[0m\]"
GREEN="\[\033[32m\]"
LIGHT_GREEN="\[\033[1;32m\]"
BLUE="\[\033[34m\]"
LIGHT_BLUE="\[\033[1;34m\]"
RED="\[\033[31m\]"
LIGHT_RED="\[\033[1;31m\]"
YELLOW="\[\033[33m\]"
LIGHT_YELLOW="\[\033[1;33m\]"

# Function to get Git branch if in a Git repository
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Function to get Git status (dirty/clean)
get_git_status() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Check if there are any changes (staged, unstaged, or untracked)
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            echo "*"  # Dirty - has changes
        fi
    fi
}

# Function to get Python virtual environment name
get_virtualenv() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "($(basename "$VIRTUAL_ENV")) "
    fi
}

# Function to get background jobs count if any exist
get_jobs() {
    local job_count=$(jobs | wc -l)
    if [ $job_count -gt 0 ]; then
        echo "[$job_count jobs] "
    fi
}

# Function to check if in SSH session
get_ssh_indicator() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        echo "[SSH] "
    fi
}

# Function to set PS1 based on user
set_ps1() {
    # Get the exit code of last command
    local EXIT="$?"
    local EXIT_STATUS=""
    if [ $EXIT != 0 ]; then
        EXIT_STATUS="${LIGHT_RED}✘ $EXIT${RESET} "
    else
        EXIT_STATUS="${LIGHT_GREEN}✓${RESET} "
    fi

    # Set different colors for root and normal users
    if [ $(id -u) = 0 ]; then
        # Root user - red username
        USER_HOST="${LIGHT_RED}\u${RESET}@${YELLOW}\h${RESET}"
    else
        # Normal user - green username
        USER_HOST="${LIGHT_GREEN}\u${RESET}@${YELLOW}\h${RESET}"
    fi

    # Current directory with blue color
    DIR="${LIGHT_BLUE}\w${RESET}"

    # Git branch in yellow if it exists, with dirty status in red
    GIT_BRANCH="${LIGHT_YELLOW}\$(parse_git_branch)${RESET}${LIGHT_RED}\$(get_git_status)${RESET}"

    # Python virtual environment in cyan if active
    VENV="\[\033[96m\]\$(get_virtualenv)${RESET}"

    # SSH session indicator in orange/red if active
    SSH_INDICATOR="\[\033[91m\]\$(get_ssh_indicator)${RESET}"

    # Add timestamp in gray
    TIMESTAMP="\[\033[90m\][\t]${RESET}"

    # Show number of background jobs only if any exist
    JOBS="\[\033[95m\]\$(get_jobs)${RESET}"

    # Combine all elements
    PS1="${SSH_INDICATOR}${VENV}${TIMESTAMP} ${EXIT_STATUS}${USER_HOST}:${DIR}${GIT_BRANCH}${JOBS}\n\$ "
}

# Set up PROMPT_COMMAND to update PS1 before each prompt
PROMPT_COMMAND=set_ps1
