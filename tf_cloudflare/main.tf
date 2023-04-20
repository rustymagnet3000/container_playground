# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

# export TF_VAR_cloudflare_account_id="1234abcd" from machine running Terraform
variable "cloudflare_account_id" {
  description = "The Cloudflare Account ID associated with my CF!"

  type    = string
  default = ""
}

output "my_account_id" {
  value = var.cloudflare_account_id
}


# Changes to Outputs:
#   + my_account_id = "1234abcd"
