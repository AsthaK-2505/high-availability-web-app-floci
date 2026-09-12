#!/bin/bash
set -e

IMAGE="ghcr.io/asthak-2505/high-availability-app:latest"
CONTAINER="devops-app-cd"
PORT="8082"

echo "== Pull latest image =="
docker pull "$IMAGE"

echo "== Remove previous deployment =="
docker rm -f "$CONTAINER" 2>/dev/null || true

echo "== Start new deployment =="
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p "${PORT}:80" \
  "$IMAGE"

echo "== Wait for application =="
for i in {1..10}; do
  if curl -fsS "http://localhost:${PORT}" > /tmp/app-response.txt; then
    break
  fi
  sleep 2
done

echo "== Application response =="
cat /tmp/app-response.txt

grep -q "Hello from Dockerized Application" /tmp/app-response.txt

echo
echo "== Deployment successful =="
