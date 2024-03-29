terraform {
  required_version = ">= 0.12.26"
}

# just outputs "Hello, World!"
output "hello_world" {
  value = "Hello world"
}

# Gets List of strings
output "get_list" {
  value = local.country_codes
}

# Convert from List of Strings to Map
output "convert_list_with_no_index_to_map" {
  value = { for idx, val in local.foobar_domains : idx => val }
}

# for x in List
output "return_list_of_strings" {
  value = [for x in local.foobar_domains : x if x == "foobar.fr"]
}

# get index
output "get_index" {
  value = index(local.foobar_domains, "foobar.fr")
}

# Contains Boolean response
output "contains_french_record" {
  value = contains(local.foobar_domains, "foobar.fr")
}


output "subscribers_based_on_input_var" {
  value = local.subscribers
}