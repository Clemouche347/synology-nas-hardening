variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "state_bucket_name" {
  description = "Bucket name for Terraform state"
  type        = string
  default     = "nas-terraform-state"
}

variable "backup_bucket_name" {
  description = "Bucket name for Hyper Backup DR"
  type        = string
  default     = "nas-backup-dr"
}

variable "backup_sa_name" {
  description = "Service account ID for Hyper Backup"
  type        = string
  default     = "nas-hyper-backup"
}

variable "backup_lifecycle_age" {
  description = "Days before objects are deleted from backup bucket"
  type        = number
  default     = 120
}
