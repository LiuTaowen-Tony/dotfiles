# Personal Dotfiles

A comprehensive dotfiles configuration for macOS that provides a streamlined development environment with intelligent shell configuration, macOS system optimizations, and useful utilities.

## ✨ Features

### 🐚 Shell Configuration
- **Multi-shell support**: Works with Bash, Zsh, and Fish
- **Smart prompts**: Shows git status, error codes, and branch information
- **Enhanced history**: Improved history management with deduplication and search
- **Auto-completion**: Intelligent tab completion and suggestions
- **Auto-updates**: Automatically pulls latest dotfiles updates in background

### 🛠 Development Tools
- **Git configuration**: Useful aliases, LFS support, and smart defaults
- **Vim setup**: Feature-rich vim configuration with SpaceVim support
- **Command line utilities**: Custom scripts for common development tasks
- **GPU management**: Utilities for CUDA device selection

### 📁 Utility Scripts
- **Safe deletion**: `trash` command that moves files to Trash instead of permanent deletion
- **Package management**: Auto-installation of development tools (asdf, zsh plugins)
- **AI assistant**: Built-in natural language to bash command translator
- **Build tools**: Deployment and export utilities

### 🍎 macOS Optimizations
- **System preferences**: Comprehensive macOS tweaks for better UX
- **Finder enhancements**: Show hidden files, path bar, status bar
- **Dock optimizations**: Auto-hide, better animations, reduced clutter
- **Keyboard improvements**: Faster key repeat, disabled autocorrect for coding
- **Performance tweaks**: Optimized scrollbars, animations, and system behavior

## 🚀 Quick Start

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Source the configuration:**
   ```bash
   echo 'source $HOME/dotfiles/shellrc' >> ~/.bashrc  # For Bash
   echo 'source $HOME/dotfiles/shellrc' >> ~/.zshrc   # For Zsh
   ```

3. **Personalize the configuration:**
   ```bash
   # Update your name and email in gitconfig
   nano ~/dotfiles/gitconfig
   ```

4. **Apply macOS settings (optional):**
   ```bash
   ./macos
   ```

### Automatic Setup
The dotfiles will automatically:
- Add the `bin` directory to your PATH
- Set up git configuration
- Deploy vim/SpaceVim configuration
- Install zsh plugins if using zsh
- Check for updates in the background

## 🔄 Auto-Update

The dotfiles automatically check for updates when you open a new shell session. Updates are pulled in the background and you'll be notified if new changes are available.

To manually update:
```bash
cd ~/dotfiles && git pull
```

## 📂 Structure

```
dotfiles/
├── bin/                    # Utility scripts
│   ├── deploy_dotfiles     # Setup and deployment
│   ├── bootstrap           # Install development tools
│   ├── my_copilot.py      # AI bash translator
│   ├── trash              # Safe file deletion
│   └── ...                # More utilities
├── space_vim_config/      # SpaceVim configuration
├── aliases                # Command aliases
├── common_config.fish     # Fish shell config
├── gitconfig             # Git configuration
├── inputrc               # Readline configuration
├── macos                 # macOS system preferences
├── shellrc               # Main shell configuration
└── vimrc                 # Vim configuration
```

## 🔧 Key Features Explained

### Shell Prompt
The intelligent prompt shows:
- **Green arrow (→)**: Last command succeeded
- **Red exclamation (!n)**: Last command failed with exit code n
- **Git branch**: Current branch name with dirty state indicator (⚠️)
- **Hostname and current directory**

### Useful Aliases
```bash
# Navigation
..          # cd ..
...         # cd ../..
....        # cd ../../..

# File operations
ll          # ls -lh (detailed list)
la          # ls -a (show hidden)
rm          # trash (safe deletion)

# System monitoring
psmem       # Top memory-consuming processes
pscpu       # Top CPU-consuming processes
meminfo     # Memory usage information

# Development
gpu0        # Set CUDA_VISIBLE_DEVICES=0
sact        # source .venv/bin/activate
json        # Pretty-print JSON with jq
```

### Git Aliases
```bash
git st      # status -s (short status)
git cm      # commit -m
git acm     # add . && commit -m
git acp     # add . && commit -m "update" && push
git lg      # Pretty log with graph
git amend   # Amend last commit
```

### Utility Scripts

#### `bootstrap` - Install Development Tools
```bash
bootstrap zsh       # Install zsh plugins
bootstrap spacevim  # Install SpaceVim
bootstrap appman    # Install appman package manager
```

#### `=` - AI Bash Translator
Translates natural language to bash commands using AI:
```bash
= "create a tar archive of project folder"
# Output: tar -czvf project.tar.gz project
```

#### `copilot` - AI assistant dispatcher
`copilot` is a two-layer tool: `bin/my_copilot.py` is a neutral Gemini engine that simply accepts a prompt (`--prompt` or `--prompt-file`), shows a small spinner, and emits the raw completion. `bin/copilot` is the dispatcher that builds persona-specific prompts, feeds them to the engine, and routes the result to the right user-facing flow.

Examples:
```bash
copilot bash "find all .txt files and delete them"
copilot commit -s "Fix spinner" -d "Guard against mode-specific assumptions"
```
The `commit` flow opens `$EDITOR` with the generated message before calling `git commit -F` when you save.

#### `trash` - Safe File Deletion
this is aliased to rm
```bash
trash file.txt        # Move to ~/.Trash instead of permanent deletion
trash *.log           # Move multiple files safely
rm file.txt           # rm is aliased to trash, so it will move thing to trash
/bin/rm file.txt      # use the system /bin/rm explicitly to actually remove
```

## ⚙️ Configuration

### Environment Variables
Before using certain features, set up these environment variables:
- `GOOGLE_API_KEY`: Required for the AI copilot functionality (get from Google Cloud Console)
- `MAKE`: Automatically set to `make -j16` for parallel builds

Add to your shell profile:
```bash
export GOOGLE_API_KEY="your-google-api-key-here"
```

### Customization

#### Personal Information
**Important**: Before using these dotfiles, update your personal information:
```bash
# Edit gitconfig and replace placeholder values
nano ~/dotfiles/gitconfig
# Update:
# name = Your Name          → name = Your Actual Name
# email = your.email@example.com → email = your.actual@email.com
```

#### Other Customizations
- **Shell prompt**: Modify `git_info()` and `precmd()` functions in `shellrc`
- **Aliases**: Add custom aliases to the `aliases` file
- **macOS settings**: Customize system preferences in the `macos` script



## 🐟 Fish Shell Support

For Fish shell users, source the Fish configuration:
```fish
# Add to ~/.config/fish/config.fish
source ~/dotfiles/common_config.fish
```

## 📱 macOS Specific Features

The `macos` script includes optimizations for:
- **Keyboard**: Fast key repeat, disabled autocorrect
- **Finder**: Show hidden files, extensions, path bar
- **Dock**: Auto-hide, better animations, removed recent apps
- **System**: Disabled transparency, faster animations
- **Security**: Secure keyboard entry in Terminal

Run with: `./macos` (requires admin password)

Manual settings:
- Input method
- Modifier key

Recommended Apps:
[Rectangle](https://rectangleapp.com/)
Hapigo `brew install --cask hapigo`


## 🤝 Contributing

Feel free to:
1. Fork this repository
2. Add your own customizations
3. Submit pull requests for useful features
4. Report issues or suggest improvements

## 📄 License

This dotfiles configuration is open source and available under the MIT License.

---

**Note**: Some features are macOS-specific. The shell configuration and utilities work on other Unix-like systems, but the `macos` script should only be run on macOS. 
