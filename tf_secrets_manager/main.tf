provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name                    = "example"
  recovery_window_in_days = 0
}

# https://automateinfra.com/2021/03/24/how-to-create-secrets-in-aws-secrets-manager-using-terraform-in-amazon-account/
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password
resource "random_password" "dummy_pswd" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret_version" "version" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = random_password.dummy_pswd.result
}

data "aws_secretsmanager_secret" "get-example" {
  count = var.env_name == "prod" ? 1 : 0
  name  = aws_secretsmanager_secret.example.name
}


data "aws_secretsmanager_secret_version" "latest" {
  count     = var.env_name == "prod" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.get-example[0].id
}

locals {
  sns_subscribers = {
    prod = ["foo@bar.com", var.env_name == "prod" ? "${data.aws_secretsmanager_secret_version.latest[0].secret_string}" : ""]
  }
  subscribers = lookup(local.sns_subscribers, var.env_name, ["foo@bar.com"])
}
