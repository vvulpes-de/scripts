#!/bin/bash

# Docker System Check Script
# Checks Docker installation, status and functionality

echo "=================================================="
echo "🐳 DOCKER SYSTEM CHECK"
echo "=================================================="
echo ""

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for successful tests
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function for failed tests
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function for warnings
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function for info
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "1. Checking Docker Installation..."
echo "---------------------------------"

# Check if Docker is installed
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    success "Docker is installed: $DOCKER_VERSION"
else
    error "Docker is NOT installed!"
    echo ""
    echo "Installation commands:"
    echo "- Ubuntu/Debian: sudo apt-get install docker.io"
    echo "- CentOS/RHEL: sudo yum install docker"
    echo "- macOS/Windows: Download Docker Desktop from docker.com"
    exit 1
fi

echo ""
echo "2. Checking Docker Daemon Status..."
echo "-----------------------------------"

# Check if Docker daemon is running
if docker info &> /dev/null; then
    success "Docker daemon is running"
    
    # Docker system info
    DOCKER_ROOT_DIR=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
    DOCKER_STORAGE_DRIVER=$(docker info --format '{{.Driver}}' 2>/dev/null)
    info "Docker root directory: $DOCKER_ROOT_DIR"
    info "Storage driver: $DOCKER_STORAGE_DRIVER"
else
    error "Docker daemon is NOT running!"
    echo ""
    echo "Start daemon with:"
    if command -v systemctl &> /dev/null; then
        echo "sudo systemctl start docker"
        echo "sudo systemctl enable docker  # For autostart"
    else
        echo "Start Docker Desktop (GUI) or 'sudo service docker start'"
    fi
fi

echo ""
echo "3. Testing Docker Permissions..."
echo "--------------------------------"

# Check if sudo is needed
if docker ps &> /dev/null; then
    success "Docker runs without sudo (user is in docker group)"
else
    if sudo docker ps &> /dev/null 2>&1; then
        warning "Docker requires sudo privileges"
        echo "   Tip: Add user to docker group:"
        echo "   sudo usermod -aG docker \$USER"
        echo "   Then log out and back in!"
    else
        error "Cannot access Docker!"
    fi
fi

echo ""
echo "4. Showing Running Containers..."
echo "--------------------------------"

CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
if [ "$CONTAINERS" -gt 0 ]; then
    success "$CONTAINERS containers currently running"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
else
    info "No containers currently running"
fi

echo ""
echo "5. Checking Docker Images..."
echo "----------------------------"

IMAGES=$(docker images -q 2>/dev/null | wc -l)
if [ "$IMAGES" -gt 0 ]; then
    success "$IMAGES Docker images available"
    echo "Top 5 images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -6
else
    info "No Docker images available"
fi

echo ""
echo "6. Docker Functionality Test..."
echo "-------------------------------"

echo "Running 'docker run hello-world'..."
if docker run --rm hello-world &> /tmp/docker-test.log; then
    success "Docker functionality test successful!"
    info "Hello-world container executed and removed"
else
    error "Docker functionality test failed!"
    echo "Error log:"
    cat /tmp/docker-test.log
fi

echo ""
echo "7. Checking Docker Compose..."
echo "-----------------------------"

if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    success "Docker Compose installed: $COMPOSE_VERSION"
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    success "Docker Compose (plugin) installed: $COMPOSE_VERSION"
else
    warning "Docker Compose is not installed"
    echo "   Installation: sudo apt-get install docker-compose"
fi

echo ""
echo "8. System Resources..."
echo "----------------------"

# Disk usage
DOCKER_SIZE=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}" 2>/dev/null)
if [ $? -eq 0 ]; then
    success "Docker disk usage:"
    echo "$DOCKER_SIZE"
else
    warning "Could not determine disk usage"
fi

echo ""
echo "9. Networks & Volumes..."
echo "------------------------"

NETWORKS=$(docker network ls -q 2>/dev/null | wc -l)
VOLUMES=$(docker volume ls -q 2>/dev/null | wc -l)

info "$NETWORKS Docker networks available"
info "$VOLUMES Docker volumes available"

echo ""
echo "=================================================="
echo "🎉 DOCKER CHECK COMPLETED"
echo "=================================================="

# Cleanup
rm -f /tmp/docker-test.log

# Summary
echo ""
echo "SUMMARY:"
echo "--------"
if docker info &> /dev/null; then
    echo -e "${GREEN}✓ Docker is ready to use!${NC}"
else
    echo -e "${RED}✗ Docker has issues - see details above${NC}"
fi

echo ""
echo "Useful Docker commands:"
echo "• docker ps -a          # Show all containers"
echo "• docker images         # Show all images"
echo "• docker system prune   # Clean up (remove unused data)"
echo "• docker stats          # Show resource usage"
echo "• docker logs <container> # Show container logs"