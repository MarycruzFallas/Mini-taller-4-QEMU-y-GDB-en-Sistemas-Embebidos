#!/bin/bash
set -euo pipefail
cd "${HOME}/Project_1_Embebidos"
CID="$(docker compose ps -q vigilante)"
[ -n "$CID" ] || { echo "vigilante no está activo"; exit 1; }
VIGILANTE_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID")"
echo "vigilante=$VIGILANTE_IP:5000"
exec socat -v UDP4-RECVFROM:5000,fork UDP4-SENDTO:${VIGILANTE_IP}:5000
