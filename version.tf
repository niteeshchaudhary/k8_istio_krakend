# version.tf
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.18"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 2.0"
    }
  }
}
