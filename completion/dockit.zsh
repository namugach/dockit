_dockit() {
    local -a commands
    commands=(
        'init:Initialize dockit project'
        'start:Start container'
        'stop:Stop container'
        'status:Check container status'
        'config:Manage configuration'
        'connect:Connect to container'
    )
    _describe 'command' commands
}
compdef _dockit dockit
