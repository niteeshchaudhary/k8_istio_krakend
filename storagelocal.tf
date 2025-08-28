resource "kubernetes_namespace" "operator_ns" {
  metadata {
    name = var.operator_namespace
  }
}
resource "helm_release" "local_path_provisioner" {
  name       = "local-path-provisioner"
  namespace  = "kube-system"
  repository = "https://charts.containeroo.ch"
  chart      = "local-path-provisioner"
  version    = "0.0.29" # check latest with helm search repo

  values = [
    <<EOF
storageClass:
  defaultClass: true
EOF
  ]
}

# Note: Using existing local-path StorageClass instead of creating custom local-ebs
