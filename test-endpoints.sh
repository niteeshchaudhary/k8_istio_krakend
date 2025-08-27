#!/bin/bash

echo "Testing KrakenD endpoints..."

# Check if we're in a local cluster (minikube/kind)
EXTERNAL_IP=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$EXTERNAL_IP" ]; then
    # Check for localhost (minikube/kind)
    EXTERNAL_IP=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ "$EXTERNAL_IP" = "localhost" ]; then
        # For minikube, we need to use the tunnel or port-forward
        echo "Detected local cluster (minikube/kind)"
        echo "Using port-forward for testing..."
        
        # Start port-forward in background
        kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80 &
        PF_PID=$!
        sleep 3
        
        echo "Testing endpoints via port-forward (localhost:8080)..."
        echo ""
        
        # Test health endpoint
        echo "Testing /health endpoint..."
        curl -v "http://localhost:8080/health"
        echo ""
        echo ""
        
        # Test WebSocket endpoint
        echo "Testing /ws endpoint..."
        curl -v -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" "http://localhost:8080/ws"
        echo ""
        echo ""
        
        # Kill port-forward
        kill $PF_PID
        wait $PF_PID 2>/dev/null
        
    else
        echo "Error: Could not get external IP or hostname for ingress gateway"
        exit 1
    fi
else
    echo "Ingress Gateway External IP: $EXTERNAL_IP"
    echo ""
    
    # Test health endpoint
    echo "Testing /health endpoint..."
    curl -v "http://$EXTERNAL_IP/health"
    echo ""
    echo ""
    
    # Test WebSocket endpoint
    echo "Testing /ws endpoint..."
    curl -v -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" "http://$EXTERNAL_IP/ws"
    echo ""
    echo ""
fi

echo "Test completed!"
echo ""
echo "To check logs:"
echo "kubectl logs -n krakend-test -l app=krakend"
echo "kubectl logs -n krakend-test -l app=ws-server"
echo ""
echo "To check services:"
echo "kubectl get svc -n krakend-test"
echo "kubectl get svc -n istio-system"
echo ""
echo "To check Istio resources:"
echo "kubectl get virtualservice -n krakend-test"
echo "kubectl get gateway -n krakend-test" 