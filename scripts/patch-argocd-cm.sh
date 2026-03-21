#!/bin/bash

# Exit on error
set -e

NAMESPACE="argocd"

echo "🔧 Patching argocd-cm ConfigMap to enable Kustomize Helm support..."

# Patch the ConfigMap to add kustomize.buildOptions
kubectl patch cm argocd-cm -n "$NAMESPACE" --type merge -p '{"data": {"kustomize.buildOptions": "--enable-helm"}}'

echo "✅ Successfully patched argocd-cm!"
echo ""
echo "🔄 Important Next Steps:"
echo "1. Restart the argocd-repo-server so it picks up the new config:"
echo "   kubectl rollout restart deploy/argocd-repo-server -n $NAMESPACE"
echo "2. Go to the Argo CD UI and click 'Sync' on your application."
