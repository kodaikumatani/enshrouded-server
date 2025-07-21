####################################
# Random ID
####################################
resource "random_id" "go124-gcf-source" {
  byte_length = 8
}

resource "random_id" "nodejs22-gcf-source" {
  byte_length = 8
}

####################################
# Google Storage Bucket
####################################
resource "google_storage_bucket" "go124-gcf-source" {
  name                        = "${random_id.go124-gcf-source.hex}-go124-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "nodejs22-gcf-source" {
  name                        = "${random_id.nodejs22-gcf-source.hex}-nodejs22-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

####################################
# Archive File
####################################
data "archive_file" "go124-gcf-source" {
  type        = "zip"
  output_path = "/tmp/go124-gcf-source.zip"
  source_dir  = "template/go124/"
}

data "archive_file" "nodejs22-gcf-source" {
  type        = "zip"
  output_path = "/tmp/nodejs22-gcf-source.zip"
  source_dir  = "template/nodejs22/"
}

####################################
# Google Storage Bucket Object
####################################
resource "google_storage_bucket_object" "go124-gcf-source" {
  name   = "go124-gcf-source.zip"
  bucket = google_storage_bucket.go124-gcf-source.name
  source = data.archive_file.go124-gcf-source.output_path # Add path to the zipped function source code
}

resource "google_storage_bucket_object" "nodejs22-gcf-source" {
  name   = "nodejs22-gcf-source.zip"
  bucket = google_storage_bucket.nodejs22-gcf-source.name
  source = data.archive_file.nodejs22-gcf-source.output_path # Add path to the zipped function source code
}
