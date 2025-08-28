#!/bin/bash

# 🚀 Istio + KrakenD + Python Socket.IO Deployment Script
# This script automates the deployment of your microservices architecture

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="krakend-test"
ISTIO_NAMESPACE="istio-system"

echo -e "${BLUE}🚀 Starting Istio + KrakenD + Python Socket.IO Deployment${NC}"
echo "=================================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please ensure your cluster is running."
    exit 1
fi

print_status "Prerequisites check passed"

# Create namespace if it doesn't exist
echo -e "${BLUE}🏗️  Setting up namespace...${NC}"
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    kubectl create namespace $NAMESPACE
    print_status "Created namespace: $NAMESPACE"
else
    print_status "Namespace $NAMESPACE already exists"
fi

# Enable Istio injection
echo -e "${BLUE}🔧 Enabling Istio injection...${NC}"
kubectl label namespace $NAMESPACE istio-injection=enabled --overwrite
print_status "Istio injection enabled for namespace: $NAMESPACE"

# Build Python Socket.IO server Docker image
echo -e "${BLUE}🐳 Building Python Socket.IO server...${NC}"
cd ws-server
if docker build -t ws-server:latest .; then
    print_status "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi
cd ..

# Deploy services
echo -e "${BLUE}📦 Deploying services...${NC}"

# Deploy Python Socket.IO server
echo "Deploying Python Socket.IO server..."
kubectl apply -f server.yaml
print_status "Python Socket.IO server deployed"

# Deploy KrakenD
echo "Deploying KrakenD..."
kubectl apply -f krakend.yaml
print_status "KrakenD deployed"

# Deploy Istio configuration
echo "Deploying Istio configuration..."
kubectl apply -f istio.yaml
print_status "Istio configuration deployed"

# Deploy NodePort service
echo "Deploying NodePort service..."
kubectl apply -f istio-nodeport.yaml
print_status "NodePort service deployed"

# Wait for pods to be ready
echo -e "${BLUE}⏳ Waiting for pods to be ready...${NC}"
echo "Waiting for Python Socket.IO server..."
kubectl wait --for=condition=ready pod -l app=ws-server -n $NAMESPACE --timeout=300s
print_status "Python Socket.IO server is ready"

echo "Waiting for KrakenD..."
kubectl wait --for=condition=ready pod -l app=krakend -n $NAMESPACE --timeout=300s
print_status "KrakenD is ready"

# Wait for Istio gateway
echo "Waiting for Istio gateway..."
kubectl wait --for=condition=ready pod -l app=istio-ingressgateway -n $ISTIO_NAMESPACE --timeout=300s
print_status "Istio gateway is ready"

# Get service information
echo -e "${BLUE}📊 Service Information${NC}"
echo "=================================================="

# Show pods status
echo -e "${BLUE}Pods Status:${NC}"
kubectl get pods -n $NAMESPACE

echo -e "${BLUE}Services:${NC}"
kubectl get svc -n $NAMESPACE

echo -e "${BLUE}Istio Resources:${NC}"
kubectl get virtualservice,gateway -n $NAMESPACE

# Test endpoints
echo -e "${BLUE}🧪 Testing endpoints...${NC}"

# Wait a bit for services to be fully ready
sleep 10

# Test health endpoint
echo "Testing health endpoint..."
if curl -s "http://localhost:30080/health" > /dev/null; then
    print_status "Health endpoint is accessible"
else
    print_warning "Health endpoint test failed (this might be normal if port-forwarding is needed)"
fi

# Test status endpoint
echo "Testing status endpoint..."
if curl -s "http://localhost:30080/status" > /dev/null; then
    print_status "Status endpoint is accessible"
else
    print_warning "Status endpoint test failed (this might be normal if port-forwarding is needed)"
fi

# Test Socket.IO endpoint
echo "Testing Socket.IO endpoint..."
if curl -s "http://localhost:30080/socket.io/" > /dev/null; then
    print_status "Socket.IO endpoint is accessible"
else
    print_warning "Socket.IO endpoint test failed (this might be normal if port-forwarding is needed)"
fi

# Deployment summary
echo -e "${BLUE}🎉 Deployment Complete!${NC}"
echo "=================================================="
echo -e "${GREEN}Your microservices architecture is now running!${NC}"
echo ""
echo -e "${BLUE}📱 Access Points:${NC}"
echo "  • Health API: http://localhost:30080/health"
echo "  • Status API: http://localhost:30080/status"
echo "  • Socket.IO: http://localhost:30080/socket.io/"
echo ""
echo -e "${BLUE}🧪 Testing:${NC}"
echo "  • Python client: python test-socketio-client.py"
echo "  • Browser client: open test-socketio.html"
echo "  • Manual testing: curl http://localhost:30080/health"
echo ""
echo -e "${BLUE}📊 Monitoring:${NC}"
echo "  • Pods: kubectl get pods -n $NAMESPACE"
echo "  • Logs: kubectl logs -n $NAMESPACE -l app=ws-server"
echo "  • Services: kubectl get svc -n $NAMESPACE"
echo ""
echo -e "${BLUE}🔧 Troubleshooting:${NC}"
echo "  • Check pod status: kubectl get pods -n $NAMESPACE"
echo "  • View logs: kubectl logs -n $NAMESPACE -l app=ws-server"
echo "  • Check Istio: kubectl get virtualservice,gateway -n $NAMESPACE"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}" 