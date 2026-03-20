#!/bin/bash

# Exit on error
set -e

NAMESPACE="argocd"
BOOTSTRAP_FILE="k8s/argocd/bootstrap.yaml"

echo "🚀 Adding Argo CD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "🛠️ Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Installing Argo CD via Helm..."
helm upgrade --install argocd argo/argo-cd \
    --namespace "$NAMESPACE" \
    --wait

echo "⏳ Waiting for Argo CD components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$NAMESPACE"

echo "🌟 Applying the Root Bootstrap Application (App-of-Apps)..."
if [ -f "$BOOTSTRAP_FILE" ]; then
    kubectl apply -f "$BOOTSTRAP_FILE"
    echo "✅ Root application applied successfully!"
else
    echo "❌ Error: $BOOTSTRAP_FILE not found. Please run this script from the project root."
    exit 1
fi

echo "🎉 Done! You can now access Argo CD."
echo "To get the initial admin password, run:"
echo "kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
