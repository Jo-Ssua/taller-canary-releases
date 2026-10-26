#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "  ROLLBACK DE EMERGENCIA: EVACUANDO TRÁFICO CANARY"
echo "=========================================================="

echo "[1/2] Redirigiendo 100% del tráfico a app-stable en Nginx..."
cat << 'EOF' > ./nginx/nginx.conf
events { worker_connections 1024; }

http {
    # Rollback: 100% a Stable
    split_clients "${remote_addr}${http_user_agent}SEED" $backend_upstream {
        *       app-stable:8080;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://$backend_upstream;
            proxy_set_header Host $host;
            add_header X-Served-By $backend_upstream always;
        }
    }
}
EOF

docker exec canary-router sh -c 'cat << "EOF" > /etc/nginx/nginx.conf
events { worker_connections 1024; }
http {
    split_clients "${remote_addr}${http_user_agent}SEED" $backend_upstream {
        * app-stable:8080;
    }
    server {
        listen 80;
        location / {
            proxy_pass http://$backend_upstream;
            proxy_set_header Host $host;
            add_header X-Served-By $backend_upstream always;
        }
    }
}
EOF'

echo "[2/2] Recargando Nginx en caliente..."
docker exec canary-router nginx -s reload

echo "=========================================================="
echo "🛡️  ROLLBACK COMPLETADO. 100% de usuarios a salvo en STABLE"
echo "=========================================================="
