# Add Zalando chart repo in your environment before first apply (one-time):
# helm repo add zalando https://opensource.zalando.com/postgres-operator/charts/
# (Terraform will fetch it by URL too; adding repo locally just helps with debugging)

resource "helm_release" "postgres_operator" {
  name       = "postgres-operator"
  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart      = "postgres-operator"
  namespace  = var.operator_namespace
  skip_crds  = true  # Skip CRD installation since they already exist

  values = [
    yamlencode({
      configGeneral = {
        enable_team_id_clustername_prefix = true
      }

      # Enable and configure LOGICAL BACKUP (pg_dump cronjobs managed by operator)
      configLogicalBackup = {
        logical_backup_schedule = var.logical_backup_schedule
        logical_backup_docker_image = "registry.opensource.zalan.do/acid/logical-backup:master-35" # stays current enough for local
        logical_backup_s3_bucket     = var.minio_bucket
        logical_backup_s3_endpoint   = "http://minio.${var.minio_namespace}.svc.cluster.local:9000"
        logical_backup_s3_region     = "us-east-1"

        # For MinIO, we also set access/secret keys here (operator will use them for the CronJobs).
        # NOTE: Fine for local. In AWS, use IAM roles/IRSA or a Secret!
        logical_backup_s3_access_key_id     = var.minio_access_key
        logical_backup_s3_secret_access_key = var.minio_secret_key
        # Disable SSL for local MinIO endpoint
        logical_backup_s3_sse = "false"
      }

      # Optional: tweak watched namespaces, etc.
      watched_namespace = ""
    })
  ]

  depends_on = [
    kubernetes_namespace.operator_ns,
    helm_release.minio
  ]
}

resource "helm_release" "postgres_operator_ui" {
  name       = "postgres-operator-ui"
  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui"
  chart      = "postgres-operator-ui"
  namespace  = var.operator_namespace

  set {
    name  = "envs.targetNamespace"
    value = var.namespace
  }

  depends_on = [helm_release.postgres_operator]
}
