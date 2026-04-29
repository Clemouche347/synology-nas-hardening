# Synology NAS Terraform — Off-site Backup to GCS

## Project context

This Terraform project provisions the GCS infrastructure for the Synology NAS off-site disaster recovery backup.

The Synology NAS (DS925+) is at an office serving ~25 users across two organizations. The NAS already has local protection (RAID1, immutable Btrfs snapshots, Synology Drive versioning). This project adds the off-site "1" in the 3-2-1 backup rule.

Synology Hyper Backup built-in app connects to GCS via the S3-compatible interoperability endpoint (`storage.googleapis.com`) using HMAC keys. In Hyper Backup, the destination type is "S3 Storage" — this is the S3 protocol standard, not AWS-specific.

## GCP project

- **Project ID:** `YOUR_PROJECT_ID`
- **Region:** `YOUR_REGION` (e.g. `asia-southeast1` for Singapore)
- **Terraform operator account:** `your-account@example.com`
- **Auth:** `gcloud auth application-default login` (no service account key file needed for Terraform itself)

This assumes a shared GCP project where other resources may already exist. We only add our backup resources. Do not modify or reference existing resources.

## What Terraform creates

1. **State bucket:** `nas-terraform-state` — versioned, public access prevented
2. **Backup bucket:** `nas-backup-dr` — Coldline, lifecycle delete after 120 days
3. **Service account:** `nas-hyper-backup@YOUR_PROJECT_ID.iam.gserviceaccount.com`
4. **IAM binding:** service account gets `roles/storage.admin` on the backup bucket only
5. **HMAC key:** for the service account, used by Hyper Backup S3 interop

## Manual IAM (outside Terraform)

The following project-level binding should be applied manually by Admin
unless Terraform operator has `roles/resourcemanager.projectIamAdmin`:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:nas-hyper-backup@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

Required for S3 ListBuckets API — Hyper Backup needs to enumerate buckets during task setup.
Write access remains scoped to `nas-backup-dr` bucket only.

## Key decisions

- **Coldline** storage class (not Archive) — 90-day min duration aligns with 12-version rotation, avoids early deletion fees
- **120-day lifecycle delete** — safety margin above Coldline's 90-day minimum
- **Uniform bucket-level access** — no legacy ACLs, IAM only
- **Public access prevention** — enforced on both buckets
- **Client-side encryption** — configured in Synology Hyper Backup, not in Terraform (AES-256, password set in Synology DSM)
- **HMAC keys** — output as sensitive, manually entered into Hyper Backup on the NAS

## Terraform conventions

- Provider: `hashicorp/google ~> 7.0`
- Required Terraform: `>= 1.9`
- Backend: GCS (`nas-terraform-state`) — bootstrap with local backend first, then migrated
- No modules — flat structure, small project
- Variables for project ID, region, bucket names
- Outputs: HMAC access key ID (non-sensitive), HMAC secret (sensitive), other three outputs are convenience

## Bootstrap sequence

The state bucket must exist before Terraform can use it as backend. Two-step process:

1. Started with `backend "local" {}` → `terraform apply` to create the state bucket
2. Switched to `backend "gcs" { bucket = "nas-terraform-state" }` → `terraform init -migrate-state`

## Files

- `README.md` — this file
- `providers.tf` — provider and backend config
- `variables.tf` — input variables
- `terraform.tfvars` — actual values (committed — contains no secrets)
- `main.tf` — all resources
- `outputs.tf` — HMAC keys and bucket info
- `.gitignore`

## Security notes

- HMAC secret is sensitive — never commit `terraform.tfstate` to git
- `.gitignore` excludes state files, `.terraform/` directory, and crash logs
- `terraform.tfvars` only contains project ID and region (non-sensitive), safe to commit
- The service account needs viewing project-level permissions — bucket-level objectAdmin only

## Usage

```bash
# authenticate
gcloud auth application-default login

# init (first time, local backend)
terraform init

# plan
terraform plan

# apply
terraform apply

# get HMAC secret after apply
terraform output -raw hmac_secret

# migrate state to GCS (after state bucket exists)
terraform init -migrate-state
```
