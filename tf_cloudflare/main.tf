# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "= 3.20.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "cloudflare_ip_list" "ip_list_deny" {
  account_id  = var.cloudflare_account_id
  name        = "ip_list_deny"
  kind        = "ip"
  description = "IP addresses to ban"

  item {
    value = "192.168.0.1"
    comment = "Foobar comments"
  }

}

# export TF_VAR_cloudflare_account_id="1234abcd" from machine running Terraform
variable "cloudflare_account_id" {
  description = "The Cloudflare Account ID associated with my CF!"

  type    = string
  default = ""
}

variable "cloudflare_token" {
  description = "The Cloudflare API Token associated with my CF!"

  type    = string
  default = ""
}

output "my_account_id" {
  value = var.cloudflare_account_id
}

# Changes to Outputs:
#   + my_account_id = "1234abcd"
