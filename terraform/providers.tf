terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }

  # Step 1: bootstrap with local backend
  # backend "local" {}

  # Step 2: after state bucket created, switched to:
  backend "gcs" {
    bucket = "YOUR_STATE_BUCKET" # replace with your state bucket name
    prefix = "nas-backup"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
