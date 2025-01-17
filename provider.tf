terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "~> 6.15.0"
        }
        fastly = {
            source = "fastly/fastly"
            version = "~> 5.13.0"
        }
    }
}

provider "google" {
    project = var.gcp_project_id
    region = var.gcp_project_region
}

provider "fastly" {
    api_key = var.fastly_api_key
}
 