_dockit_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local commands="init start stop status config connect"
    
    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    fi
}
complete -F _dockit_completion dockit
