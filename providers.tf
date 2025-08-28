# providers.tf
provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "docker-desktop"
  }
}

provider "minio" {
  alias      = "local"
  minio_server   = "http://localhost:9000"
  minio_user     = "minioadmin"
  minio_password = "minioadmin"
}

provider "null" {
  # No configuration needed for null provider
}

provider "time" {
  # No configuration needed for time provider
}
