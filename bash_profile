alias grep='grep --color=auto'
alias pull='git pull --rebase'
alias commit='git commit'
alias gc='git checkout'
alias push='git push'
alias st='git status'
alias add='git add'
alias di='git diff'
alias ll='ls -lah'
alias k="kubectl"
alias kg="kubectl get"
alias ke="kubectl edit"
alias kl="kubectl logs"
alias kd="kubectl describe"
alias ka="kubectl apply -f"
alias ks="kubectl scale --replicas"
alias kga="kubectl get all"
alias kgp="kubectl get pods -o wide"
alias kgpw="kubectl get pods -w"

shopt -s cdspell

export BASH_SILENCE_DEPRECATION_WARNING=1
export COLOREDLOGS_LOG_FORMAT='%(message)s' LSCOLORS=GxFxCxDxbxegedabagaced
export SVN_EDITOR=vim CLICOLOR=1 LANG=en_US

export CONTEXT_NAME=YOUR_CONTEXT
export KUBE_NAMESPACE=default
export ENV_NAME=ENV-1


HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000

stac(){ # Set title and color
    echo -ne "\033]0;$1\007\033]6;1;bg;red;brightness;$2\a\033]6;1;bg;green;brightness;$3\a\033]6;1;bg;blue;brightness;$4\a"
}

show() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    kubectl -n $KUBE_NAMESPACE get all --selector=app=$1
}

recreate() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    kubectl -n $KUBE_NAMESPACE delete pod --selector=app=$1
}

delete() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    for deployment_and_cm in $@; do kubectl -n $KUBE_NAMESPACE delete {cm,deployment}/$deployment_and_cm; done
}

evicted_pods() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    kubectl -n $KUBE_NAMESPACE get pod | grep Evicted || echo "No any"
}

delete_evicted_pods() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    kubectl -n $KUBE_NAMESPACE get pod | grep Evicted | awk "{print \$1}" | xargs kubectl -n $KUBE_NAMESPACE delete pod
}

pod() { # Usage: 'pod deploymentname' (or 'pod deploymentname' 2 if there are > 1 pods)
    pod=$(kubectl get pod --field-selector=status.phase=Running --selector=app=$1 -o jsonpath='{.items[*].metadata.name}')
    kubectl exec -it $pod -- bash
}


logs() {
    if [ -z "$2" ]; then
        pods=$(kubectl -n $KUBE_NAMESPACE get pod --field-selector=status.phase=Running --selector=app=$1 \
            -o jsonpath='{.items[*].metadata.name}')
        pods_number=$(echo $pods | wc -w)
        if [[ $pods_number -eq 1 ]]; then
            kubectl -n $KUBE_NAMESPACE logs -f $pods -c $1 --tail=1000
        else
            ${K8}/scripts/kubetail.sh $1 -n $KUBE_NAMESPACE -k pod -s 1h | grep -v 'out_flowcounter'
        fi
    else
        kubectl -n $KUBE_NAMESPACE logs -f --tail=1000 $(kubectl -n $KUBE_NAMESPACE get pod --field-selector=status.phase=Running \
            --selector=app=$1 -o jsonpath='{.items[*].metadata.name}' | awk "{print \$$2}") -c $1 | grep -v 'out_flowcounter'
    fi
}

copyfrompod() { # Usage: copyfrompod deploymentname /path/to/file/inside.pod
    [ -z "$3" ] && pod_number=1 || pod_number=$3
    kubectl -n $KUBE_NAMESPACE exec $(kubectl -n $KUBE_NAMESPACE get pod --field-selector=status.phase=Running \
        --selector=app=$1 -o jsonpath='{.items[*].metadata.name}' | awk "{print \$$pod_number}") -it cat $2 > ${2##*/}
}

fuck() {
    TF_PYTHONIOENCODING=$PYTHONIOENCODING
    export TF_SHELL=bash
    export TF_ALIAS=fuck
    export TF_SHELL_ALIASES=$(alias)
    export TF_HISTORY=$(fc -ln -10)
    export PYTHONIOENCODING=utf-8
    TF_CMD=$(thefuck THEFUCK_ARGUMENT_PLACEHOLDER $@) && eval $TF_CMD;
    unset TF_HISTORY
    export PYTHONIOENCODING=$TF_PYTHONIOENCODING
    history -s $TF_CMD
}

server(){ #start local server in current dir on port 8000
    echo 'http://'$(ifconfig en0 | grep 'inet ' | awk "{print \$2}")':8000'
    echo 'http://127.0.0.1:8000'
    python -m SimpleHTTPServer 8000
}

mkcd(){
    mkdir $1; cd $1
}

compare(){
    diff --side-by-side --suppress-common-lines -w -b <(sort $1) <(sort $2)
}

tree() {
    ls -R $1 | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
}

fixlayout() {
    en="qwertyuiop\[]asdfghjkl;'\zxcvbnm,.QWERTYUIOP{}ASDFGHJKL:\"|ZXCVBNM<>\@№%%^&*"
    ru="йцукенгшщз\хъфывапролджэёячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖ\ЭЁЯЧСМИТЬБЮ\"#$:,.;"
    pbpaste | sed y=$en$ru=$ru$en= | pbcopy
}

hidden_files() { #YES or NO
    defaults write com.apple.finder AppleShowAllFiles $1; killall Finder
}

ip(){
    printf 'WiFi: '; ifconfig en0 | grep 'inet ' | awk "{print \$2}"
}

tab() {
    iterm() {
        osascript -e "tell application \"System Events\" to tell process \"iTerm\" to $1"
    }
    iterm 'keystroke "t" using command down'; iterm "keystroke \"$1\""; iterm 'key code 52'
}
