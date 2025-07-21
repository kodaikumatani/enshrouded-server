provider "google" {
  project = var.project_id
  region = var.region
  access_token = data.google_service_account_access_token.default.access_token
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket                      = "enshrouded-tfstate"
    impersonate_service_account = "terraform@enshrouded-465714.iam.gserviceaccount.com"
  }
}

provider "google" {
  alias = "impersonation"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_service_account_access_token" "default" {
  provider               = google.impersonation
  target_service_account = "terraform@enshrouded-465714.iam.gserviceaccount.com"
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "300s"
}
