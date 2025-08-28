# 🚀 Istio + KrakenD + Python Socket.IO Architecture

A production-ready microservices architecture using **Istio** for service mesh, **KrakenD** for API gateway, and **Python Socket.IO** for real-time communication with background tasks.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Components](#components)
- [Data Flow](#data-flow)
- [API Endpoints](#api-endpoints)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting]
- [Security Features](#security-features)
- [Production Considerations](#production-considerations)

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client/Browser│    │  Istio Gateway   │    │  KrakenD API   │
│                 │───▶│  (Port 30080)    │───▶│   Gateway      │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Istio Virtual  │    │  Python Socket │
                       │     Service     │    │     .IO Server  │
                       │                 │    │                 │
                       └──────────────────┘    └─────────────────┘
```

### **Key Features:**
- **Service Mesh**: Istio handles traffic management, security, and observability
- **API Gateway**: KrakenD provides rate limiting, authentication, and request routing
- **Real-time Communication**: Python Socket.IO server with background tasks and automatic updates
- **Load Balancing**: Automatic load balancing and failover
- **Security**: TLS, authentication, and authorization at multiple layers
- **Background Processing**: Automatic counter updates every 10 minutes
- **Organized Endpoints**: `/socket` prefix for all WebSocket-related services

## 🧩 Components

### **1. Istio Service Mesh**
- **Gateway**: Entry point for external traffic (Port 30080)
- **Virtual Service**: Routes traffic to appropriate services
- **Sidecar Proxies**: Envoy proxies for each service

### **2. KrakenD API Gateway**
- **Version**: 2.4.6
- **Features**: Rate limiting, caching, request aggregation
- **Endpoints**: `/health`, `/status`, and `/socket/ws` endpoints with backend routing

### **3. Python Socket.IO Server**
- **Technology**: Python 3.11 + Socket.IO + Uvicorn (ASGI)
- **Features**: 
  - Real-time bidirectional communication
  - Background task processing (counter updates every 10 minutes)
  - Automatic client management
  - Health monitoring endpoints
  - Session tracking and management

## 🔄 Data Flow

### **HTTP Request Flow (Health/Status Endpoints)**
```
Client → Istio Gateway (30080) → Virtual Service → KrakenD → Python Socket.IO Server
```

1. **Client Request**: `GET http://localhost:30080/health` or `/status`
2. **Istio Gateway**: Receives request on port 30080
3. **Virtual Service**: Routes traffic to KrakenD
4. **KrakenD**: Processes request, applies rate limiting and caching
5. **Python Socket.IO Server**: Returns health/status information
6. **Response**: JSON response flows back through the chain

### **Socket.IO WebSocket Connection Flow**
```
Client → Istio Gateway (30080) → Virtual Service → Python Socket.IO Server (Direct)
```

1. **Client Request**: Socket.IO connection to `/socket/socket.io/`
2. **Istio Gateway**: Receives request on port 30080
3. **Virtual Service**: Routes Socket.IO traffic directly to Python server
4. **Python Socket.IO Server**: Handles connection and maintains WebSocket
5. **Background Tasks**: Automatically sends updates every 10 minutes
6. **Connection**: Persistent Socket.IO connection with real-time updates

### **Standard WebSocket Connection Flow**
```
Client → Istio Gateway (30080) → Virtual Service → KrakenD → Python Socket.IO Server
```

1. **Client Request**: WebSocket upgrade request to `/socket/ws`
2. **Istio Gateway**: Receives request on port 30080
3. **Virtual Service**: Routes WebSocket traffic to KrakenD
4. **KrakenD**: Applies rate limiting and monitoring
5. **Python Socket.IO Server**: Handles WebSocket upgrade and maintains connection

## 🌐 API Endpoints

### **HTTP Endpoints (via KrakenD)**
| Endpoint | Method | Description | Features |
|----------|--------|-------------|----------|
| `/health` | GET | Health check with metrics | Rate limiting, caching, monitoring |
| `/status` | GET | Server status and info | Rate limiting, caching, monitoring |

### **WebSocket Endpoints**
| Endpoint | Type | Description | Route |
|----------|------|-------------|-------|
| `/socket/socket.io/` | Socket.IO | Socket.IO protocol connections | Direct → ws-server |
| `/socket/ws` | WebSocket | Standard WebSocket connections | Via KrakenD → ws-server |

### **Endpoint Structure Benefits**
- **Organization**: All WebSocket services under `/socket` prefix
- **Scalability**: Easy to add more WebSocket services
- **Monitoring**: Clear separation of HTTP vs WebSocket traffic
- **Security**: Different routing rules for different protocols

## 📋 Prerequisites

### **Required Software**
- **Docker Desktop** with Kubernetes enabled
- **kubectl** command-line tool
- **Python 3.11+** (for local testing)
- **curl** for testing endpoints

### **System Requirements**
- **RAM**: Minimum 4GB (8GB recommended)
- **CPU**: 2 cores minimum
- **Storage**: 20GB free space

### **Kubernetes Version**
- **Minimum**: 1.24+
- **Recommended**: 1.27+

## 🚀 Installation

### **1. Clone the Repository**
```bash
git clone <your-repo-url>
cd k8_istio_krakend
```

### **2. Install Istio**
```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -

# Add Istio to PATH
export PATH=$PWD/istio-1.27.0/bin:$PATH

# Install Istio with default profile
istioctl install --set profile=demo -y
```

### **3. Enable Istio Injection**
```bash
# Label namespace for Istio injection
kubectl label namespace krakend-test istio-injection=enabled
```

### **4. Build Python Socket.IO Server**
```bash
cd ws-server
docker build -t ws-server:latest .
cd ..
```

### **5. Deploy Services**
```bash
# Deploy Python Socket.IO server
kubectl apply -f server.yaml

# Deploy KrakenD
kubectl apply -f krakend.yaml

# Deploy Istio configuration
kubectl apply -f istio.yaml

# Deploy NodePort service for local access
kubectl apply -f istio-nodeport.yaml
```

## ⚙️ Configuration

### **Istio Configuration (`istio.yaml`)**
```yaml
# Gateway configuration
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: krakend-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      protocol: HTTP
    hosts:
    - "*"

# Virtual Service for routing
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: krakend-vs
spec:
  hosts:
  - "*"
  gateways:
  - krakend-gateway
  http:
  # Socket.IO WebSocket endpoint - direct routing
  - match:
    - uri:
        prefix: /socket/socket.io
    route:
    - destination:
        host: ws-server
        port:
          number: 8080
  # WebSocket endpoint via KrakenD
  - match:
    - uri:
        prefix: /socket/ws
    route:
    - destination:
        host: krakend
        port:
          number: 8080
  # Health endpoint via KrakenD
  - match:
    - uri:
        prefix: /health
    route:
    - destination:
        host: krakend
        port:
          number: 8080
  # Status endpoint via KrakenD
  - match:
    - uri:
        prefix: /status
    route:
    - destination:
        host: krakend
        port:
          number: 8080
```

### **KrakenD Configuration (`configmap.yaml`)**
```json
{
  "version": 3,
  "timeout": "5s",
  "cache_ttl": "3600s",
  "rate_limit": {
    "max_rate": 100,
    "client_max_rate": 10
  },
  "extra_config": {
    "qos/ratelimit/router": {
      "max_rate": 100,
      "client_max_rate": 10
    },
    "qos/ratelimit/proxy": {
      "max_rate": 200,
      "client_max_rate": 20
    }
  },
  "endpoints": [
    {
      "endpoint": "/health",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/health",
          "host": ["http://ws-server.krakend-test.svc.cluster.local:8080"],
          "timeout": "5s"
        }
      ]
    },
    {
      "endpoint": "/status",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/",
          "host": ["http://ws-server.krakend-test.svc.cluster.local:8080"],
          "timeout": "5s"
        }
      ]
    },
    {
      "endpoint": "/socket/ws",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/ws",
          "host": ["http://ws-server.krakend-test.svc.cluster.local:8080"],
          "timeout": "5s"
        }
      ]
    }
  ]
}
```

### **Python Socket.IO Server Configuration (`ws-server/server.py`)**
```python
import socketio
import uvicorn
import asyncio
from datetime import datetime

sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")
app = socketio.ASGIApp(sio)

COUNTER = 0
BACKGROUND_TASK: asyncio.Task | None = None

# When a client connects, we start the background task to send updates
@sio.event
async def connect(sid, environ):
    global BACKGROUND_TASK
    print(f"Client connected: {sid}")
    await sio.emit("message", {"data": f"Welcome to the server - {sid}"}, to=sid)

    if BACKGROUND_TASK is None or BACKGROUND_TASK.done():
        await sio.emit("message", {"data": "Background task started"})
        BACKGROUND_TASK = sio.start_background_task(send_updates)
        print("Background task started")

# Background task that sends updates every 10 minutes
async def send_updates():
    global COUNTER
    try:
        while True:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            message = {"update": f"Counter: {COUNTER} at {timestamp}"}
            print(f"Sending update: {message}")
            await sio.emit("update", message)
            COUNTER += 1
            await asyncio.sleep(600) # 10 minutes
    except asyncio.CancelledError:
        print("Background task cancelled")
```

## 🧪 Testing

### **1. Check Service Status**
```bash
# Check all pods are running
kubectl get pods -n krakend-test

# Check services
kubectl get svc -n krakend-test

# Check Istio resources
kubectl get virtualservice -n krakend-test
kubectl get gateway -n krakend-test
```

### **2. Test HTTP Endpoints**
```bash
# Test health endpoint (should return 200 OK)
curl "http://localhost:30080/health"

# Expected response:
{
  "status": "healthy",
  "timestamp": "2025-08-27T21:34:43.292Z",
  "service": "ws-server-python",
  "connected_clients": 0,
  "counter": 0
}

# Test status endpoint
curl "http://localhost:30080/status"
```

### **3. Test Socket.IO Connection (with /socket prefix)**
```bash
# Test Socket.IO endpoint (should return Socket.IO handshake)
curl "http://localhost:30080/socket/socket.io/"
```

### **4. Test Standard WebSocket (with /socket prefix)**
```bash
# Test WebSocket upgrade (should return 101 Switching Protocols)
curl -v -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
     "http://localhost:30080/socket/ws"
```

### **5. Test with Python Client**
```bash
# Install Python dependencies
pip install python-socketio aiohttp

# Run the test client (updated for /socket prefix)
python test-socketio-client.py
```

### **6. Test with Browser Client**
```bash
# Open the HTML test page (updated for /socket prefix)
open test-socketio.html
```

## 🔍 Troubleshooting

### **Common Issues and Solutions**

#### **1. Port 30080 Not Accessible**
```bash
# Check if NodePort service is running
kubectl get svc -n istio-system istio-ingressgateway-nodeport

# Check if pods are ready
kubectl get pods -n krakend-test

# Check Istio gateway logs
kubectl logs -n istio-system -l app=istio-ingressgateway
```

#### **2. 400/500 Errors**
```bash
# Check KrakenD logs
kubectl logs -n krakend-test -l app=krakend

# Check Python Socket.IO server logs
kubectl logs -n krakend-test -l app=ws-server

# Check Istio sidecar logs
kubectl logs -n krakend-test -c istio-proxy -l app=krakend
```

#### **3. Socket.IO Connection Issues**
```bash
# Verify Virtual Service routing
kubectl get virtualservice krakend-vs -n krakend-test -o yaml

# Check if Python server is accessible from KrakenD
kubectl exec -n krakend-test -it $(kubectl get pod -l app=krakend -o jsonpath='{.items[0].metadata.name}') -- curl http://ws-server:8080/health
```

### **Debug Commands**
```bash
# Get detailed pod information
kubectl describe pod -n krakend-test -l app=krakend

# Check Istio proxy configuration
istioctl proxy-config all -n krakend-test -l app=krakend

# View Istio metrics
istioctl dashboard grafana
```

## 🔒 Security Features

### **Current Security Measures**
- **Network Policies**: Restricted inter-service communication
- **Istio Authorization**: Service-to-service access control
- **Rate Limiting**: Request throttling at multiple levels
- **Health Checks**: Liveness and readiness probes
- **CORS Configuration**: Socket.IO CORS settings
- **Endpoint Organization**: Clear separation of service types

### **Recommended Security Enhancements**
- **TLS/HTTPS**: Enable encryption for production
- **JWT Authentication**: Add token-based authentication
- **API Keys**: Implement API key validation
- **Input Validation**: Sanitize all incoming data
- **Rate Limiting**: Per-client rate limiting

## 🚀 Production Considerations

### **Scaling**
```bash
# Scale Python Socket.IO server
kubectl scale deployment ws-server -n krakend-test --replicas=3

# Scale KrakenD
kubectl scale deployment krakend -n krakend-test --replicas=3
```

### **Monitoring**
```bash
# Enable Prometheus metrics
kubectl apply -f istio-1.27.0/samples/addons/prometheus.yaml

# Enable Grafana dashboard
kubectl apply -f istio-1.27.0/samples/addons/grafana.yaml

# Access Grafana
istioctl dashboard grafana
```

### **High Availability**
```bash
# Check pod distribution across nodes
kubectl get pods -n krakend-test -o wide

# Verify anti-affinity rules
kubectl get pods -n krakend-test -o yaml | grep -A 10 affinity
```

## 📊 Performance Tuning

### **KrakenD Optimization**
```json
{
  "timeout": "2s",
  "cache_ttl": "1800s",
  "rate_limit": {
    "max_rate": 1000,
    "client_max_rate": 100
  }
}
```

### **Python Socket.IO Server Optimization**
```python
# Connection pooling and performance settings
sio = socketio.AsyncServer(
    async_mode="asgi", 
    cors_allowed_origins="*",
    max_http_buffer_size=1e6,  # 1MB max message size
    ping_timeout=60,
    ping_interval=25
)
```

### **Istio Performance Tuning**
```yaml
# Gateway optimization
spec:
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
    tls:
      httpsRedirect: false  # Disable for HTTP-only setup
```

## 🔧 Maintenance

### **Regular Tasks**
```bash
# Update Istio
istioctl upgrade

# Update KrakenD
kubectl set image deployment/krakend krakend=devopsfaith/krakend:latest -n krakend-test

# Update Python Socket.IO server
kubectl set image deployment/ws-server ws-server=ws-server:latest -n krakend-test

# Clean up old images
docker system prune -f
```

### **Backup and Recovery**
```bash
# Backup configurations
kubectl get configmap krakend-config -n krakend-test -o yaml > krakend-config-backup.yaml

# Backup Istio resources
kubectl get virtualservice,gateway -n krakend-test -o yaml > istio-resources-backup.yaml
```

## 📚 Additional Resources

- [Istio Documentation](https://istio.io/latest/docs/)
- [KrakenD Documentation](https://www.krakend.io/docs/)
- [Python Socket.IO Documentation](https://python-socketio.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the logs using the debug commands
3. Open an issue with detailed error information
4. Include your Kubernetes and Istio versions

---

**Happy coding! 🚀** 