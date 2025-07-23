module "secret-manager" {
  source  = "GoogleCloudPlatform/secret-manager/google//modules/simple-secret"
  version = "~> 0.8"

  project_id  = var.project_id
  name        = "discord_webhook_url"
  secret_data = "secret information"
}
