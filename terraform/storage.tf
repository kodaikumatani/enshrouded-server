resource "random_id" "default" {
  byte_length = 8
}

####################################
# Google Storage Bucket
####################################
resource "google_storage_bucket" "http" {
  name                        = "${random_id.default.hex}-http-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "pubsub" {
  name                        = "${random_id.default.hex}-pubsub-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

####################################
# Archive File
####################################
data "archive_file" "http" {
  type        = "zip"
  output_path = "/tmp/http/function-source.zip"
  source_dir  = "template/http/"
}

data "archive_file" "pubsub" {
  type        = "zip"
  output_path = "/tmp/pubsub/function-source.zip"
  source_dir  = "template/pubsub/"
}

####################################
# Google Storage Bucket Object
####################################
resource "google_storage_bucket_object" "http" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.http.name
  source = data.archive_file.http.output_path # Add path to the zipped function source code
}

resource "google_storage_bucket_object" "pubsub" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.pubsub.name
  source = data.archive_file.pubsub.output_path # Add path to the zipped function source code
}
