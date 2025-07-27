resource "google_pubsub_topic" "discord-vm-control" {
  name = "discord-vm-control"

  message_retention_duration = "86600s"
}
