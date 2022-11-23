

output "example_secret_name" {
  value       = var.env_name == "prod" ? data.aws_secretsmanager_secret.get-example[0].name : "nothing to show"
  description = "Example Secret name"
  sensitive   = false
}

output "example_secret_arn" {
  value       = var.env_name == "prod" ? data.aws_secretsmanager_secret.get-example[0].arn : "nothing to show"
  description = "Example Secret ARN"
  sensitive   = false
}

output "get_list_of_subscribers" {
  value       = local.subscribers
  description = "Subscribers based on env_name"
  sensitive   = true
}
