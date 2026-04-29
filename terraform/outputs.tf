output "backup_bucket_url" {
  description = "Backup bucket URL"
  value       = google_storage_bucket.backup.url
}

output "state_bucket_url" {
  description = "State bucket URL"
  value       = google_storage_bucket.state.url
}

output "hyper_backup_sa_email" {
  description = "Hyper Backup service account email"
  value       = google_service_account.hyper_backup.email
}

output "hmac_access_id" {
  description = "HMAC access key ID — enter in Hyper Backup as Access Key"
  value       = google_storage_hmac_key.hyper_backup.access_id
}

output "hmac_secret" {
  description = "HMAC secret — enter in Hyper Backup as Secret Key"
  value       = google_storage_hmac_key.hyper_backup.secret
  sensitive   = true
}
