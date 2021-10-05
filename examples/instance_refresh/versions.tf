terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws        = ">= 3.22.0"
    local      = ">= 2.0.0"
    random     = ">= 2.1"
    kubernetes = ">= 2.0.0"
    helm       = "~> 2.1.2"
  }
}
