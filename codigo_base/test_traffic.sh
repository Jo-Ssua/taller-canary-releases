#!/usr/bin/env bash

REQUESTS=${1:-50}

echo "=========================================================="
echo "  MONITOREO DE TRÁFICO CANARY ($REQUESTS peticiones simuladas)"
echo "=========================================================="

STABLE_COUNT=0
CANARY_COUNT=0
ERROR_COUNT=0

for i in $(seq 1 $REQUESTS); do
    # Simular diferentes IPs de clientes pasando X-Forwarded-For
    CLIENT_IP="192.168.1.$(( (RANDOM % 250) + 1 ))"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -H "X-Forwarded-For: $CLIENT_IP" http://localhost:8080/api/info)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)

    BACKEND=$(echo "$BODY" | grep -o '"environment":"[^"]*' | cut -d'"' -f4 || echo "ERROR")
    
    if [ "$HTTP_CODE" = "200" ]; then
        if [ "$BACKEND" = "STABLE" ]; then
            STABLE_COUNT=$((STABLE_COUNT + 1))
            echo -e "[Req #$i] IP $CLIENT_IP -> \033[1;34mSTABLE (v1.0.0)\033[0m [HTTP 200]"
        elif [ "$BACKEND" = "CANARY" ]; then
            CANARY_COUNT=$((CANARY_COUNT + 1))
            echo -e "[Req #$i] IP $CLIENT_IP -> \033[1;33mCANARY (v2.0.0)\033[0m [HTTP 200]"
        fi
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        echo -e "[Req #$i] IP $CLIENT_IP -> \033[1;31mFALLO HTTP $HTTP_CODE en Canary\033[0m"
    fi
    sleep 0.05
done

TOTAL_OK=$((STABLE_COUNT + CANARY_COUNT))
echo "----------------------------------------------------------"
echo "📊 RESULTADOS DE LA PRUEBA SINTÉTICA:"
echo "   • Peticiones a STABLE: $STABLE_COUNT ($(( STABLE_COUNT * 100 / REQUESTS ))%)"
echo "   • Peticiones a CANARY: $CANARY_COUNT ($(( CANARY_COUNT * 100 / REQUESTS ))%)"
echo "   • Errores HTTP 500:    $ERROR_COUNT ($(( ERROR_COUNT * 100 / REQUESTS ))%)"
echo "=========================================================="
