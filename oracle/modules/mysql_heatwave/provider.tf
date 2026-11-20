terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}

provider "oci" {
  auth                = var.auth
  region              = var.region
  config_file_profile = var.profile
}
