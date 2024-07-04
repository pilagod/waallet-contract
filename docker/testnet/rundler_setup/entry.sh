#!/bin/sh

apk update && apk --no-cache add bash curl coreutils

rundler_url="http://rundler:3000"

/script/wait.sh rundler:3000 -t 60 || {
    echo "wait for ${rundler_url} failed";
    exit 1; 
}

# Set rundler to manual mode
curl -d '{"id":1,"jsonrpc":"2.0","method":"debug_bundler_setBundlingMode","params":["manual"]}' -H "Content-Type: application/json" -X POST ${rundler_url}
