#/bin/bash

rm -rf logs/*.log
mkdir -p logs

if [ -f "./logs/nginx.pid" ]; then
    echo "stop nginx.."
    nginx -p ./ -c conf/nginx.conf -s stop
fi

echo "start nginx..."
nginx -p ./ -c conf/nginx.conf
