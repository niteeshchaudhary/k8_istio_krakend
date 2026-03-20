helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade \
  argocd-dev argo/argo-cd \
  --install \
  --create-namespace \
  -n argocd \
  --version 9.4.15 \
  -f values.yaml