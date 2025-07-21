#######################################
# Cloud Functions: instance-controller
#######################################
resource "google_cloudfunctions2_function" "instance-controller" {
  name        = "instance-controller"
  location    = "us-central1"
  description = "A Cloud Function to start and stop GCE instances based on HTTP triggers."

  build_config {
    runtime     = "go124"
    entry_point = "HelloHTTP" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.go124-gcf-source.name
        object = google_storage_bucket_object.go124-gcf-source.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    min_instance_count = 0
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      LOG_EXECUTION_ID = "true"
      PROJECT_ID = var.project_id
      ZONE = "asia-east1-a"
      INSTANCE = "instance-20250714-084552"
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

#######################################
# Cloud Functions: discord-interactions
#######################################
resource "google_cloudfunctions2_function" "discord-interactions" {
  name        = "discord-interactions"
  location    = "us-central1"
  description = "Discord Interactions webhook."

  build_config {
    runtime     = "nodejs22"
    entry_point = "helloHttp" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.nodejs22-gcf-source.name
        object = google_storage_bucket_object.nodejs22-gcf-source.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    min_instance_count = 0
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      LOG_EXECUTION_ID = "true"
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
