terraform {
  required_version = ">= 0.12.26"
}

# just outputs "Hello, World!"
output "hello_world" {
  value = "Hello world"
}

# Iterate over Array of strings
output "hello_array" {
  value = local.country_codes
}
