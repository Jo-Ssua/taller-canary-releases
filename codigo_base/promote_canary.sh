#!/usr/bin/env bash
set -e

PERCENTAGE=${1:-50}

echo "=========================================================="
echo "  PROMOCIÓN DE CANARY A $PERCENTAGE% DEL TRÁFICO"
echo "=========================================================="

if [ "$PERCENTAGE" -eq 100 ]; then
    CANARY_RULE="*       app-canary:8080;"
else
    CANARY_RULE="$PERCENTAGE%     app-canary:8080;
        *       app-stable:8080;"
fi

cat << EOF > ./nginx/nginx.conf
events { worker_connections 1024; }

http {
    split_clients "\${remote_addr}\${http_user_agent}SEED" \$backend_upstream {
        $CANARY_RULE
    }

    server {
        listen 80;
        location / {
            proxy_pass http://\$backend_upstream;
            proxy_set_header Host \$host;
            add_header X-Served-By \$backend_upstream always;
        }
    }
}
EOF

docker exec canary-router sh -c "cat << 'INNER_EOF' > /etc/nginx/nginx.conf
events { worker_connections 1024; }
http {
    split_clients \"\${remote_addr}\${http_user_agent}SEED\" \$backend_upstream {
        $CANARY_RULE
    }
    server {
        listen 80;
        location / {
            proxy_pass http://\$backend_upstream;
            proxy_set_header Host \$host;
            add_header X-Served-By \$backend_upstream always;
        }
    }
}
INNER_EOF"

docker exec canary-router nginx -s reload

echo "=========================================================="
echo "🚀 Tráfico actualizado a $PERCENTAGE% para CANARY con éxito."
echo "=========================================================="
