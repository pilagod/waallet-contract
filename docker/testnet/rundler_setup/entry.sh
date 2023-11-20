#!/bin/sh

apk --no-cache add curl

# Set rundler to manual mode
curl -d '{"id":1,"jsonrpc":"2.0","method":"debug_bundler_setBundlingMode","params":["manual"]}' -H "Content-Type: application/json" -X POST http://rundler:3000
