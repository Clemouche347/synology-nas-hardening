# Terraform state bucket
resource "google_storage_bucket" "state" {
  name     = var.state_bucket_name
  location = var.region
  project  = var.project_id

  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = 604800 # 7 days
  }

  labels = {
    managed_by = "terraform"
    purpose    = "nas-state"
  }
}

# Hyper Backup DR bucket — Coldline, asia-southeast1
resource "google_storage_bucket" "backup" {
  name          = var.backup_bucket_name
  location      = var.region
  project       = var.project_id
  storage_class = "COLDLINE"

  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = var.backup_lifecycle_age
    }
    action {
      type = "Delete"
    }
  }

  soft_delete_policy {
    retention_duration_seconds = 0 # disabled — lifecycle handles cleanup
  }

  labels = {
    managed_by = "terraform"
    purpose    = "nas-backup-dr"
  }
}

# Dedicated service account for Synology Hyper Backup
resource "google_service_account" "hyper_backup" {
  account_id   = var.backup_sa_name
  display_name = "NAS Hyper Backup"
  project      = var.project_id
}

# Bucket-level IAM — Storage Admin
resource "google_storage_bucket_iam_member" "hyper_backup" {
  bucket = google_storage_bucket.backup.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.hyper_backup.email}"
}

# Granted manually at project level due missing  roles/resourcemanager.projectIamAdmin

# resource "google_project_iam_member" "hyper_backup_storage_admin" {
#  project = var.project_id
#  role    = "roles/storage.admin"
#  member = "serviceAccount:${google_service_account.hyper_backup.email}"
#}

# Service account-level IAM — monitoring viewer role
# resource "google_project_iam_member" "hyper_backup_monitoring" {
#  project = var.project_id
#  role    = "roles/monitoring.viewer"
#  member  = "serviceAccount:${google_service_account.hyper_backup.email}"
# }

# HMAC key for S3-compatible access from Hyper Backup
resource "google_storage_hmac_key" "hyper_backup" {
  service_account_email = google_service_account.hyper_backup.email
  project               = var.project_id
}
