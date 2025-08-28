output "minio_access" {
  value       = "To access MinIO API locally: kubectl port-forward svc/minio -n ${var.minio_namespace} 9000:9000"
  description = "Port-forward command for MinIO API"
}

output "operator_ui" {
  value       = "To open Postgres Operator UI: kubectl port-forward svc/postgres-operator-ui -n ${var.operator_namespace} 8081:80 && open http://localhost:8081"
  description = "Port-forward command for operator UI"
}

output "postgres_connect" {
  value = <<EOT
Once the cluster is Ready:
- Primary service:    svc/acid-local-cluster      (namespace: ${var.namespace})
- Replica service:    svc/acid-local-cluster-repl (namespace: ${var.namespace})
Connect locally:
  kubectl port-forward svc/acid-local-cluster -n ${var.namespace} 5432:5432
  PASSWORD=$(kubectl get secret -n ${var.namespace} postgres.acid-local-cluster.credentials.app_user -o jsonpath='{.data.password}' | base64 -d)

EOT
}
