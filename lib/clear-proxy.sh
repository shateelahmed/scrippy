if $clear_proxy; then
    unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
    echo "Cleared proxy"
fi
