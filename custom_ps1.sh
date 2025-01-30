# /etc/bash_config/ps1_config.sh

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
    
    # Git branch in yellow if it exists
    GIT_BRANCH="${LIGHT_YELLOW}\$(parse_git_branch)${RESET}"
    
    # Add timestamp in gray
    TIMESTAMP="\[\033[90m\][\t]${RESET}"
    
    # Show number of background jobs if any exist
    JOBS="\[\033[95m\][\j jobs]${RESET}"
    
    # Combine all elements
    PS1="${TIMESTAMP} ${EXIT_STATUS}${USER_HOST}:${DIR}${GIT_BRANCH} ${JOBS}\n\$ "
}

# Set up PROMPT_COMMAND to update PS1 before each prompt
PROMPT_COMMAND=set_ps1
