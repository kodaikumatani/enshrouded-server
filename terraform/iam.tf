####################################
# Create Service Account
####################################
resource "google_service_account" "deployer" {
  account_id   = "cloud-functions-deployer"
  display_name = "GitHub Actions Cloud Functions Deployer"
}

####################################
# IAM policy for projects
####################################
module "project-iam-bindings" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  version  = "~> 8.0"

  projects = [var.project_id]
  mode     = "additive"

  bindings = {
    "roles/cloudfunctions.developer" = [
      "serviceAccount:${google_service_account.deployer.email}"
    ]
  }
}

####################################
# IAM policy for Cloud Run Service
####################################
module "cloud-run-services-iam-bindings" {
  source  = "terraform-google-modules/iam/google//modules/cloud_run_services_iam"
  version = "~> 8.1"

  project            = var.project_id
  cloud_run_services = [
    google_cloudfunctions2_function.instance-controller.name,
    google_cloudfunctions2_function.discord-interactions.name
  ]
  mode               = "authoritative"

  bindings = {
    "roles/run.invoker" = [
      "allUsers"
    ]
  }
}
