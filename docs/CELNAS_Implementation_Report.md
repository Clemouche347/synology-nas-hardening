# CELNAS — Implementation Report

Synology DS925+ | HCMC Office
2×12TB RAID1 Btrfs | 20GB ECC RAM | DSM 7.3.2
Period: March 21 – April 1, 2026

---

## Phase 1 — Security (March 21–25)

Locked down all remote access. Tailscale replaced QuickConnect as the sole remote path (~160 KB/s → ~10 MB/s, ×62 improvement).

| Action | Detail | Status |
|---|---|---|
| Tailscale VPN | Tailnet configured. NAS + 2 laptops + 1 phone. MagicDNS enabled. | ✅ Done |
| ACL Policies | `admin→NAS` all ports, `member→NAS` 443/445/5000/5001/6690, `admin↔admin` all. Tags: `admin`, `member`, `nas`. | ✅ Done |
| QuickConnect | Disabled. Was ~160 KB/s via Taiwan relay. | ✅ Done |
| Firewall | LAN `10.0.0.0/24` + Tailscale `100.64.0.0/10` only. Deny all else. | ✅ Done |
| TLS Certificate | Let's Encrypt via `tailscale cert`. Monthly renewal task. | ✅ Done |
| 2FA | TOTP enforced for all users at first connection. | ✅ Done |
| Default accounts | `admin` + `guest` deactivated. | ✅ Done |
| Password policy | 12 chars, special chars, no common, 90-day expiry. | ✅ Done |
| Auto Block | 10 fails / 5 min → IP ban. | ✅ Done |
| Notifications | Email alerts configured with `[CELNAS]` prefix. | ✅ Done |
| Auto-update | Important DSM app updates only. | ✅ Done |
| TUN mode | 2 scheduled tasks at boot (kernel module + Tailscale restart). | ✅ Done |
| Tailscale update | v1.58.2 → v1.96.4 on NAS. | ✅ Done |
| Device Approval | Enabled. Manual approval by admins required. | ✅ Done |

---

## Phase 2a — Data Integrity (March 26)

| Action | Detail | Status |
|---|---|---|
| Data integrity | Btrfs checksums on all shared folders. | ✅ Done |
| Data migration | Existing data migrated to integrity-enabled folders. | ✅ Done |
| Initial scrub | Completed March 26. | ✅ Done |
| Scheduled scrub | Monthly, outside business hours. | ✅ Done |

---

## Phase 2b — Folder Structure & Snapshots (March 26–27)

### Shared Folders

| Folder | Contents | Permissions |
|---|---|---|
| `ARCHIVE/` | Completed projects – manual move by management | admin: RW · manager: R · staff/team_b/guest: No Access |
| `INTERNAL/` | Business_Dev, HR, IT, Tools_Templates | admin: RW · all others: No Access |
| `MEDIA/` | Entertainment, Marketing_Assets, Team_Photos | admin: RW · manager/staff/team_b: R (Entertainment: RW) |
| `PROJECTS/` | Active projects | admin: RW · manager: R · staff/team_b: per-subfolder override |
| `SANDBOX/` | Personal space per user (**not for secrets**) | admin: RW · per-user RW on own subfolder only |
| `docker/` | Container Manager — hidden from users | Admin-only; activate when necessary |

### Snapshots (Btrfs)

| Parameter | Value |
|---|---|
| Schedule | Hourly, every day |
| Retention | 24 hourly · 7 daily · 4 weekly · 3 monthly + 5 latest |
| Immutable snapshots | Enabled (ransomware protection) |
| Scope | All shared folders on Volume 1 |

### Project Naming Convention

Format: `PROJECT_YEAR` (e.g. `LEAN_SUPPLIER_A_2022`)
Subdirectories: `00_Data`, `01_Model+Tools`, `02_Analysis`, `03_Deliverables`

---

## Phase 2b — Synology Drive & Versioning (March 27)

| Feature | Config |
|---|---|
| Team Folders | Activated on all shared folders except system folders |
| Versioning | 8 versions max, 30-day rotation, oldest-first deletion |
| Scope | All protocols (SMB + Drive) once Team Folder is active |
| File Locking | Drive client only — optional, not activated — SMB clients cannot see locks |
| Downloads / Watermark | Disabled (internal team) |

> Versioning applies to **all protocols** once a folder is a Synology Drive Team Folder. File locking is Drive-client only.

---

## Phase 2c — Groups, Users & Permissions (March 27–30)

Principle: deny all, allow specific. A Deny on **any** group overrides Allow from any other group.

### Groups

| Group | Type | Members | Role |
|---|---|---|---|
| `administrators` | System | 3 admins | Full DSM admin |
| `org_manager` | Custom | 2 senior consultants | Senior consultants |
| `org_staff` | Custom | 14 members | Org A team |
| `team_b` | Custom | 9 members | Org B team |
| `org_guest` | Custom | (empty) | External / per-project |

### Users

27 users + 1 test account. Convention: `firstname.lastname` — all created in DSM.

2FA enforced for all users at first connection.

### SANDBOX ACLs

Per-user subfolders created for 27 users. Verified via `synoacltool` on all 27 subfolders.
Each subfolder has **2 ACL entries**: user (RW) + `administrators` (RW).
No parent inheritance.

### Access Methods

| Method | Groups |
|---|---|
| File Station (DSM web) | `administrators` only |
| SMB | All groups except `org_guest`. Use `\\celnas.<tailnet-dns>.ts.net` |
| Synology Drive Client | All groups except `org_guest`. Versioning + file locking optional. |
| Synology Drive Mobile | All groups. Requires Tailscale when off-LAN. |

SMB setting: **Hide shared folders from users without permission** — enabled.

---

CELNAS is only accessible via the tailnet. Devices must be pre-registered before they can connect. The chosen method is **auth key**. One reusable key can be used to register all devices.

---

## Open Items

- [ ] Tailscale + CELNAS onboarding — pilot team and full team
- [ ] Refine initial shared folder structure per team needs
- [ ] Docs as code
- [ ] Hyper Backup to Google Cloud Platform — 3-2-1 backup strategy
- [ ] Git repo with all NAS configs
- [ ] Container Manager utilization and microservices
