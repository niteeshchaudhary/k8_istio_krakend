# Wait for the PostgreSQL CRD to be available before creating the cluster
resource "time_sleep" "wait_for_postgres_crd" {
  depends_on = [helm_release.postgres_operator]
  
  create_duration = "30s"
}

# PostgreSQL cluster resource - now that operator is deployed
resource "kubernetes_manifest" "postgres_cluster" {
  manifest = {
    apiVersion = "acid.zalan.do/v1"
    kind       = "postgresql"
    metadata = {
      name      = "acid-local-cluster"
      namespace = var.namespace
      labels = {
        team = "acid"
      }
    }
    spec = {
      teamId             = "acid"
      numberOfInstances  = var.postgres_instances

      volume = {
        size         = var.postgres_volume_size
        storageClass = var.storageclass_name  # local-path (existing StorageClass)
      }

      users = {
        app_user = ["superuser", "createdb"]
      }

      databases = {
        appdb = "app_user"
      }

      postgresql = {
        version = "15"
      }

      # Optional: enable connection pooler (PgBouncer) if you like
      # enableConnectionPooler = true
      # allowedSourceRanges = ["0.0.0.0/0"]
    }
  }

  depends_on = [
    time_sleep.wait_for_postgres_crd
  ]

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
