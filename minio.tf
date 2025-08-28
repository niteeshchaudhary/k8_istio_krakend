resource "helm_release" "minio" {
  name       = "minio"
  namespace  = "minio"
  create_namespace = true

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "minio"
  version    = "12.8.13" # stable version

  set {
    name  = "image.tag"
    value = "2024.8.29-debian-12-r0" # explicit tag from Bitnami repo
  }

  set {
    name  = "accessKey.password"
    value = "minioadmin"
  }

  set {
    name  = "secretKey.password"
    value = "minioadmin"
  }

  set {
    name  = "defaultBuckets"
    value = "pg-backups" # for Postgres backups
  }

  set {
    name  = "resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "250m"
  }

  set {
    name  = "persistence.size"
    value = "5Gi"
  }
}
