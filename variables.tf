variable "kubeconfig_path" {
  description = "Path to kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Namespace to deploy DB resources"
  type        = string
  default     = "default"
}

variable "operator_namespace" {
  description = "Namespace for Zalando operator"
  type        = string
  default     = "postgres-operator"
}

variable "storageclass_name" {
  description = "StorageClass name to simulate EBS locally"
  type        = string
  default     = "local-path"
}

# MinIO (S3-compatible) for logical backups
variable "minio_namespace" {
  type        = string
  default     = "default"
}

variable "minio_access_key" {
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "minio_secret_key" {
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "minio_bucket" {
  type        = string
  default     = "postgres-backups"
}

variable "minio_storage_size" {
  type        = string
  default     = "10Gi"
}

variable "postgres_volume_size" {
  type        = string
  default     = "10Gi"
}

variable "logical_backup_schedule" {
  description = "Cron schedule for logical backups (pg_dump)"
  type        = string
  default     = "0 3 * * *" # daily at 03:00
}

variable "postgres_instances" {
  type    = number
  default = 2 # 1 primary + 1 replica
}
