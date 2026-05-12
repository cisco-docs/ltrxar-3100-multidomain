terraform {
  required_version = ">= 1.0"
  required_providers {
    sdwan = {
      source  = "CiscoDevNet/sdwan"
      version = "~> 0.11.0"
    }
  }
  backend "http" {
    skip_cert_verification = true
  }
}

module "sdwan" {
  source = "github.com/netascode/terraform-sdwan-nac-sdwan"

  yaml_directories = ["data/"]

  write_default_values_file = "defaults.yaml"
}
