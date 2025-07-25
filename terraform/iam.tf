####################################
# Create Service Account
####################################
resource "google_service_account" "deployer" {
  account_id   = "cloud-functions-deployer"
  display_name = "GitHub Actions Cloud Functions Deployer"
}

resource "google_service_account" "runner" {
  account_id   = "cloud-functions-runner"
  display_name = "GitHub Actions Cloud Functions Deployer"
}

####################################
# IAM policy for projects
####################################
module "project-iam-bindings" {
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.0"

  projects = [var.project_id]
  mode     = "additive"

  bindings = {
    "roles/cloudfunctions.developer" = [
      "serviceAccount:${google_service_account.deployer.email}"
    ]
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:${google_service_account.deployer.email}"
    ],
    "roles/compute.admin" = [
      "serviceAccount:${google_service_account.runner.email}"
    ]
  }
}

####################################
# IAM policy for Cloud Run Service
####################################
resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

####################################
# IAM policy for Secret Manager Secret
####################################
module "secret_manager_iam" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "~> 8.1"

  project = var.project_id
  secrets = [module.secret-manager.name]
  mode    = "additive"

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${google_service_account.runner.email}"
    ]
  }
}
