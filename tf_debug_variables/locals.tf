locals {
  country_codes = [
    ".es",
    ".fr",
    ".hk",
    ".it",
    ".nl"
  ]

  foobar_domains = [
    "foobar.es",
    "foobar.hk",
    "foobar.fr",
    "foobar.it",
    "foobar.nl"
  ]

  sns_subscribers = {
    prod = ["bar", "foo"]
    test = ["baz"]
  }

  subscribers = lookup(local.sns_subscribers, var.env_name, ["alice"])
}
