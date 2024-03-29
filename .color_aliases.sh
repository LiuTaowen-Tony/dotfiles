# Determine if we are using bash or zsh
current_shell=$(ps -p $$ -ocomm=)

# Function to check if the terminal supports color
check_color_support() {
    # Check if stdout is a terminal
    if [ -t 1 ]; then
        # Check for color support
        ncolors=$(tput colors)
        if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
            echo "yes"
        else
            echo "no"
        fi
    else
        echo "no"
    fi
}

# Define aliases based on color support
if [ "$(check_color_support)" = "yes" ]; then
    # Common aliases for both Bash and Zsh
    alias grep='grep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip -color=auto'

    # Git with color output
    alias git='git -c color.ui=auto'
    
    # Colorized JSON output (requires jq)
    alias json='jq .'

    if [ "$current_shell" = "zsh" ]; then
        # Zsh specific color options
        alias ls='ls -G'
        alias dir='dir -G'
    else
        # Bash specific color options
        alias ls='ls --color=auto'
        alias dir='dir --color=auto'
    fi

    # Syntax highlighting for various file types using bat (if installed)
    if command -v bat >/dev/null 2>&1; then
        alias cat='bat --theme=TwoDark'
        alias less='bat --theme=TwoDark --pager="less -R"'
    fi
fi

