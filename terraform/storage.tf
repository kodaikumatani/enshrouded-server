resource "random_id" "default" {
  byte_length = 8
}

####################################
# Google Storage Bucket
####################################
resource "google_storage_bucket" "go124" {
  name                        = "${random_id.default.hex}-go124-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "nodejs22" {
  name                        = "${random_id.default.hex}-nodejs22-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

####################################
# Archive File
####################################
data "archive_file" "go124" {
  type        = "zip"
  output_path = "/tmp/go124/function-source.zip"
  source_dir  = "template/go124/"
}

data "archive_file" "nodejs22" {
  type        = "zip"
  output_path = "/tmp/nodejs22/function-source.zip"
  source_dir  = "template/nodejs22/"
}

####################################
# Google Storage Bucket Object
####################################
resource "google_storage_bucket_object" "go124" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.go124.name
  source = data.archive_file.go124.output_path # Add path to the zipped function source code
}

resource "google_storage_bucket_object" "nodejs22" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.nodejs22.name
  source = data.archive_file.nodejs22.output_path # Add path to the zipped function source code
}
