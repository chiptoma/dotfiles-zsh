#!/usr/bin/env zsh
# ==============================================================================
# EDITORS & IDES REGISTRY
# VSCode, Cursor, Sublime, JetBrains, and other editor CLIs.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    # macOS IDE/Editor CLI tools
    'ide_vscode'            '/Applications/Visual Studio Code.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_vscode_insiders'   '/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_vscodium'          '/Applications/VSCodium.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_cursor'            '/Applications/Cursor.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_windsurf'          '$HOME/.codeium/windsurf/bin:append:os_is_darwin'
    'ide_sublime'           '/Applications/Sublime Text.app/Contents/SharedSupport/bin:append:os_is_darwin'
    'ide_bbedit'            '/Applications/BBEdit.app/Contents/Helpers:append:os_is_darwin'
    'ide_tower'             '/Applications/Tower.app/Contents/MacOS:append:os_is_darwin'
    'ide_sourcetree'        '/Applications/Sourcetree.app/Contents/Resources:append:os_is_darwin'
    'ide_github_desktop'    '/Applications/GitHub Desktop.app/Contents/Resources/app/bin:append:os_is_darwin'

    # Cross-platform development tools
    'dev_jetbrains'         '$HOME/.local/share/JetBrains/Toolbox/scripts:append:not_minimal_mode'
    'dev_vscode_remote'     '$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin:append:not_minimal_mode'
)
