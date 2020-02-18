
export CONTEXT_NAME=YOUR_CONTEXT
export KUBE_NAMESPACE=default
export ENV_NAME=ENV-1

stac(){ # Set title and color
    echo -ne "\033]0;$1\007\033]6;1;bg;red;brightness;$2\a\033]6;1;bg;green;brightness;$3\a\033]6;1;bg;blue;brightness;$4\a"
}

alias k="kubectl"
alias kg="kubectl get"
alias ke="kubectl edit"
alias kl="kubectl logs"
alias kga="kubectl get all"
alias kd="kubectl describe"
alias ka="kubectl apply -f"
alias ks="kubectl scale --replicas "

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

pod() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    pods=$(kubectl -n $KUBE_NAMESPACE get pod --field-selector=status.phase=Running --selector=app=$1 \
        -o jsonpath='{.items[*].metadata.name}')
    if [ "1" -ne $(echo $pods | wc -w) ] && [ -z "$2" ]; then
        pods_number=$(echo $pods | wc -w | xargs)
        if [[ $pods_number -ne 0 ]]; then
            echo "$1 have $(echo $pods | wc -w | xargs) nodes. Use \"pod $1 1\", \"pod $1 2\" commands instead"
        else
            echo "No pods for this deployment"
        fi
    else
        [ -z "$2" ] && pod_number=1 || pod_number=$2
        kubectl -n $KUBE_NAMESPACE exec -it $(echo $pods | awk "{print \$$pod_number}") bash
    fi
}

logs() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
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

editcm() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    deploy=$(kubectl -n $KUBE_NAMESPACE get deploy --selector=app=$1 | grep -v ' 0 \|NAME' | awk "{print \$1}")
    kubectl -n $KUBE_NAMESPACE edit cm $deploy
}

editdpl() {
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    deploy=$(kubectl -n $KUBE_NAMESPACE get deploy --selector=app=$1 | grep -v ' 0 \|NAME' | awk "{print \$1}")
    kubectl -n $KUBE_NAMESPACE edit deployment $deploy
}

copyfrompod() { # Usage: copyfrompod component /path/to/file/inside.pod
    kubectl config use-context $CONTEXT_NAME 1>/dev/null 2>/dev/null
    [ -z "$3" ] && pod_number=1 || pod_number=$3
    kubectl -n $KUBE_NAMESPACE exec $(kubectl -n $KUBE_NAMESPACE get pod --field-selector=status.phase=Running \
        --selector=app=$1 -o jsonpath='{.items[*].metadata.name}' | awk "{print \$$pod_number}") -it cat $2 > ${2##*/}
}
