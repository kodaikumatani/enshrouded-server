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

resource "google_service_account" "discord-interactions" {
  account_id   = "discord-interactions-sa"
  display_name = "discord-interactions service account"
}

resource "google_service_account" "vm-instance-control" {
  account_id   = "vm-instance-control-sa"
  display_name = "vm-instance-control service account"
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
      "serviceAccount:${google_service_account.runner.email}",
      "serviceAccount:${google_service_account.vm-instance-control.email}"
    ]
  }
}

####################################
# IAM policy for Cloud Run Service
####################################
module "cloud-run-services-iam-bindings" {
  source  = "terraform-google-modules/iam/google//modules/cloud_run_services_iam"
  version = "~> 8.1"

  project = var.project_id
  cloud_run_services = [
    google_cloudfunctions2_function.default.name,
    google_cloudfunctions2_function.discord-interactions-node.name,
  ]
  mode = "authoritative"

  bindings = {
    "roles/run.invoker" = [
      "allUsers"
    ]
  }
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
      "serviceAccount:${google_service_account.vm-instance-control.email}",
    ]
  }
}

####################################
# IAM policy for PubSub Topic
####################################
module "pubsub_topic-iam-bindings" {
  source  = "terraform-google-modules/iam/google//modules/pubsub_topics_iam"
  version = "~> 8.0"

  project       = var.project_id
  pubsub_topics = [google_pubsub_topic.discord-vm-control.name]
  mode          = "authoritative"

  bindings = {
    "roles/pubsub.publisher" = [
      "serviceAccount:${google_service_account.discord-interactions.email}",
    ]
  }
}
