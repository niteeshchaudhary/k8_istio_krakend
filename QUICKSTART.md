# 🚀 Quick Start Guide

Get your Istio + KrakenD + WebSocket architecture running in 5 minutes!

## ⚡ Quick Commands

### **1. One-Command Setup**
```bash
# Clone and setup everything
git clone <your-repo-url> && cd k8_istio_krakend
./setup.sh  # If you have a setup script
```

### **2. Manual Setup (Step by Step)**
```bash
# Build WebSocket server
cd ws-server && docker build -t ws-server:latest . && cd ..

# Deploy everything
kubectl apply -f server.yaml
kubectl apply -f krakend.yaml  
kubectl apply -f istio.yaml
kubectl apply -f istio-nodeport.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=krakend -n krakend-test --timeout=300s
kubectl wait --for=condition=ready pod -l app=ws-server -n krakend-test --timeout=300s
```

### **3. Test Your Setup**
```bash
# Health endpoint
curl "http://localhost:30080/health"

# WebSocket endpoint
curl -v -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" "http://localhost:30080/ws"
```

## 🎯 What You Get

- ✅ **Health API**: `http://localhost:30080/health`
- ✅ **WebSocket**: `ws://localhost:30080/ws`
- ✅ **No port-forwarding needed**
- ✅ **Automatic load balancing**
- ✅ **Health monitoring**

## 🔧 Troubleshooting Quick Fixes

### **Port 30080 not accessible?**
```bash
kubectl get svc -n istio-system istio-ingressgateway-nodeport
kubectl get pods -n krakend-test
```

### **Getting 400/500 errors?**
```bash
kubectl logs -n krakend-test -l app=krakend
kubectl logs -n krakend-test -l app=ws-server
```

### **WebSocket not working?**
```bash
kubectl get virtualservice -n krakend-test
kubectl get gateway -n krakend-test
```

## 📱 Test with JavaScript

```html
<!DOCTYPE html>
<html>
<head>
    <title>WebSocket Test</title>
</head>
<body>
    <h1>WebSocket Test</h1>
    <div id="messages"></div>
    
    <script>
        const ws = new WebSocket('ws://localhost:30080/ws');
        
        ws.onopen = function() {
            document.getElementById('messages').innerHTML += '<p>Connected!</p>';
            ws.send('Hello from browser!');
        };
        
        ws.onmessage = function(event) {
            document.getElementById('messages').innerHTML += '<p>Received: ' + event.data + '</p>';
        };
        
        ws.onerror = function(error) {
            document.getElementById('messages').innerHTML += '<p>Error: ' + error + '</p>';
        };
    </script>
</body>
</html>
```

## 🎉 You're Done!

Your microservices architecture is now running with:
- **Istio** handling traffic management
- **KrakenD** providing API gateway features  
- **WebSocket** server for real-time communication

Access your endpoints at `http://localhost:30080` 🚀 