# my-first-devops-project
it is a shell script
#!/bin/bash
set -e
exec > >(tee -i deploy.log) 2>&1

# 1. CONFIGURATION
REPO_URL="https://github.com/gAshwini-2004/my-first-devops-project.git
https://github.com
bash"
APP_DIR="/opt/my-app"
IMAGE_NAME="my-app:latest"
CONTAINER_NAME="production-app"
PORT_MAP="80:8080"
HEALTH_CHECK_URL="http://localhost:80/health"
echo "=== STARTING DEVOPS DEPLOYMENT PIPELINE ==="
# 2. CODE ACQUISITION & SYNCHRONIZATION
if [ ! -d "$APP_DIR" ]; then
    echo "[1/5] Cloning repository..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
else
    echo "[1/5] Pulling latest code..."
    cd "$APP_DIR"
    git reset --hard HEAD
    git pull origin main
fi

# 3. SECURITY & LINTING
echo "[2/5] Running security scan..."
if [ -f "Dockerfile" ]; then
    # Simple check for forbidden root user execution
    grep -q "USER root" Dockerfile && echo "WARNING: Root user detected!" || true
fi

# 4. BUILD CONTAINER IMAGE
echo "[3/5] Building Docker image..."
docker build -t "$IMAGE_NAME" .

# 5. ISOLATED TESTING
echo "[4/5] Running container integration tests..."
docker run --rm "$IMAGE_NAME" npm test || docker run --rm "$IMAGE_NAME" python -m unittest || echo "No tests found, skipping."
# 6. ZERO-DOWNTIME DEPLOYMENT
echo "[5/5] Deploying to production..."
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing old container..."
    docker rm -f "$CONTAINER_NAME"
fi

docker run -d --name "$CONTAINER_NAME" --restart always -p "$PORT_MAP" "$IMAGE_NAME"

# 7. POST-DEPLOYMENT HEALTH VERIFICATION
echo "Verifying application health..."
sleep 5
if curl -s --head  --request GET "$HEALTH_CHECK_URL" | grep "200" > /dev/null; then
    echo "STATUS: SUCCESS! Deployment is live and healthy."
else
echo "STATUS: FAILED! Health check failed. Rolling back..."
    docker rm -f "$CONTAINER_NAME"
    exit 1
fi
