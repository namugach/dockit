#compdef dockit

# ZSH completion for dockit command
# ZSH에서 dockit 명령어 자동완성

_dockit() {
    local -a commands
    commands=(
        'init:Initialize dockit project'
        'start:Start container'
        'stop:Stop container'
        'down:Remove container completely'
        'status:Check container status'
        'connect:Connect to container'
        'help:Display help information'
        'version:Display version information'
    )
    _describe 'command' commands
}

# Ensure the completion system is initialized
# 자동완성 시스템이 초기화되었는지 확인
(( $+functions[compdef] )) || autoload -Uz compinit && compinit

# Register the completion function
# 자동완성 함수 등록
compdef _dockit dockit
