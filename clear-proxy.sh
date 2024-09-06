clear_proxy="${BULK_GIT_CLEAR_PROXY:-n}"
if [ "$clear_proxy" == "y" ]; then
    unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
    echo "Cleared proxy"
fi
