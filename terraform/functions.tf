resource "google_cloudfunctions2_function" "default" {
  name        = "discord-interactions"
  location    = "us-central1"
  description = "Discord Interactions webhook."

  build_config {
    runtime     = "go124"
    entry_point = "HelloHTTP" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.go124.name
        object = google_storage_bucket_object.go124.name
      }
    }
  }

  service_config {
    timeout_seconds       = 60
    service_account_email = google_service_account.runner.email
    environment_variables = {
      CLIENT_PUBLIC_KEY = "c0f9c3f75e45e1f5a69a6a18055c27636ca093df4b56250da90eaf75d5e28d68"
      PROJECT_ID        = var.project_id
      ZONE              = "asia-east1-a"
      INSTANCE          = "instance-20250714-084552"
    }
    # secret_environment_variables {
    #   key        = "WEBHOOK_URL"
    #   project_id = var.project_id
    #   secret     = module.secret-manager.env_vars.SECRET.secret
    #   version    = "latest"
    # }
  }

  lifecycle {
    ignore_changes = [
      build_config.0.entry_point,
      build_config.0.source,
      build_config.0.docker_repository,
    ]
  }
}

resource "google_cloudfunctions2_function" "discord-interactions-node" {
  name        = "discord-interactions-node"
  location    = "us-central1"
  description = "Discord Interactions webhook."

  build_config {
    runtime     = "nodejs22"
    entry_point = "helloHttp" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.nodejs22.name
        object = google_storage_bucket_object.nodejs22.name
      }
    }
  }

  service_config {
    timeout_seconds       = 60
    service_account_email = google_service_account.discord-interactions.email
    environment_variables = {
      CLIENT_PUBLIC_KEY = "c0f9c3f75e45e1f5a69a6a18055c27636ca093df4b56250da90eaf75d5e28d68"
      PROJECT_ID        = google_pubsub_topic.discord-vm-control.project
      TOPIC_NAME = google_pubsub_topic.discord-vm-control.name
    }
  }

  lifecycle {
    ignore_changes = [
      build_config.0.entry_point,
      build_config.0.source,
      build_config.0.docker_repository,
    ]
  }
}
