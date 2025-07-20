

resource "google_cloudfunctions2_function" "default" {
  name        = "handle-gce-instance"
  location    = "us-central1"
  description = "A Cloud Function to start and stop GCE instances based on HTTP triggers."

  build_config {
    runtime     = "go124"
    entry_point = "HelloHTTP" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
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

output "function_uri" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}
