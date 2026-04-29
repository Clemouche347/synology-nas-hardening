# Synology NAS — Self-Hosted Infrastructure for a Consulting Firm

On-premise NAS infrastructure project for a supply chain analytics firm (~25 users) across two entities, deployed and managed **remotely from France to Ho Chi Minh City, Vietnam**.

---

## Overview

Designed, deployed, and documented a Synology NAS as the central file server and services platform. All remote access secured via Tailscale (WireGuard mesh VPN). No port forwarding, no public exposure.

**Context:** small company, two orgs sharing one office, no IT department. The NAS had been running with default settings, QuickConnect relay (~160 KB/s), no firewall, no 2FA, default admin account enabled.

**Result:** zero-trust remote access (×62 speed improvement), 27 user accounts with group-based RBAC, Btrfs snapshots with immutable retention, Synology Drive versioning, containerized wiki (Outline), and full operational documentation for handover.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Remote clients (France, HCMC, field)                   │
│  Laptops (tag:admin / tag:member) + phones              │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────▼─────────────┐
          │  Tailscale mesh VPN      │
          │  WireGuard · MagicDNS    │
          │  TUN mode · Device auth  │
          └────────────┬─────────────┘
                       │
          ┌────────────▼─────────────┐
          │  DSM Firewall            │
          │  LAN + Tailscale only    │
          │  deny all else           │
          └────────────┬─────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│  Synology NAS — DS925+                                  │
│  2×12TB RAID1 Btrfs · 20GB ECC RAM · DSM 7.3.2         │
│                                                         │
│  ┌─────────┐ ┌───────────────┐ ┌──────────────┐        │
│  │  SMB    │ │ Synology Drive│ │ File Station │        │
│  │ :445    │ │ :6690         │ │ :5001 HTTPS  │        │
│  └─────────┘ └───────────────┘ └──────────────┘        │
│                                                         │
│  Shared folders:                                        │
│  ARCHIVE · INTERNAL · MEDIA · PROJECTS · SANDBOX        │
│                                                         │
│  ┌─────────────────────────────────────────────┐        │
│  │  Container Manager (Docker)                 │        │
│  │  Outline + PostgreSQL 15 + Redis 7 + Dex    │        │
│  └─────────────────────────────────────────────┘        │
│                                                         │
│  Btrfs snapshots (hourly, immutable)                    │
│  Drive versioning (8 versions, 30-day retention)        │
│  Let's Encrypt TLS (auto-renewal via Tailscale)         │
└─────────────────────────────────────────────────────────┘
```

---

## What was done

### Phase 1 — Security hardening (March 21–25)

- Tailscale VPN replacing QuickConnect (160 KB/s → 10 MB/s)
- ACL policies: `admin→NAS` all ports, `member→NAS` restricted to 5 ports, default deny
- DSM firewall: LAN + Tailscale only
- Let's Encrypt TLS via `tailscale cert`, monthly auto-renewal
- 2FA (TOTP) enforced for all users
- Default `admin` + `guest` accounts deactivated
- Password policy: 12 chars, special chars, 90-day expiry
- Auto-block: 10 fails / 5 min → IP ban
- Tailscale updated v1.58.2 → v1.96.4
- DSM boot tasks: TUN kernel module + Tailscale restart (avoid DERP fallback)

### Phase 2 — Data integrity, structure, permissions (March 26–30)

- Btrfs checksums on all shared folders + monthly scrub
- Snapshot schedule: 24 hourly · 7 daily · 4 weekly · 3 monthly + immutable
- 6 shared folders with group-based permissions (5 groups, least privilege)
- 27 user accounts (`firstname.lastname` convention)
- Per-user SANDBOX subfolders with individual ACLs verified via `synoacltool`
- Synology Drive Team Folders: 8-version retention, 30-day rotation
- SMB configured with hidden folders for unauthorized users

### Phase 3 — Containerized services (April 2026)

- Outline wiki deployed via Container Manager (Docker)
- Stack: Outline + PostgreSQL 15 + Redis 7 + Dex (OIDC)
- SMTP integration for magic-link authentication
- 8 deployment issues documented with root causes and fixes

---

## Technical decisions

| Decision | Why |
|---|---|
| Tailscale over QuickConnect | ×62 speed, zero-trust, WireGuard encryption, no Synology relay dependency |
| Auth keys over SSO login | Devices registered once, no user interaction with tailnet credentials |
| Btrfs over ext4 | Checksums, snapshots, RAID1 self-heal on bit rot |
| Immutable snapshots | Ransomware protection — snapshots can't be deleted even by admin |
| Group-based ACLs over per-user | Scalable, auditable, less error-prone |
| SMB as primary protocol | Universal compatibility, Drive versioning works on all protocols anyway |
| Dex for Outline auth | Lightweight OIDC, static passwords, no external IdP dependency |
| HTTP for internal services | Tailscale already encrypts everything; HTTPS without matching cert causes issues |

---

## Documentation

| Document | Audience | Covers |
|---|---|---|
| [Admin Guide](docs/NAS_Admin_Guide.md) | IT admin | Device onboarding, user management, permissions, snapshots, maintenance |
| [First Connection Guide](docs/NAS_User_First_Connection_Guide.md) | End users | Tailscale install, first login, 2FA setup, troubleshooting |
| [Auth Key Guide](docs/NAS_Auth_Key_Guide.md) | Tailnet owner | Key generation, device registration, security practices |
| [Tailnet Reference](docs/NAS_Tailnet_Reference.md) | IT admin | ACL policy, machines, users, tags, scheduled tasks, cert |
| [Implementation Report](docs/NAS_Implementation_Report.md) | Stakeholders | Phase-by-phase build log with status and decisions |
| [SANDBOX ACL Verification](docs/NAS_SANDBOX_ACL_Verification.md) | IT admin | ACL audit log for all 27 user subfolders |

---

## Tools & Stack

- **Platform:** Synology DSM 7.3.2, Container Manager, Synology Drive Server, Snapshot Replication
- **Networking:** Tailscale (WireGuard), MagicDNS, Let's Encrypt
- **Containers:** Outline, PostgreSQL 15, Redis 7, Dex v2.38
- **Scripting:** Bash (NAS ops, sed, synoacltool), Python (openpyxl, bcrypt, log analysis)
- **Planned:** Hyper Backup to GCS (Coldline), n8n, Uptime Kuma

---

## Status

| Phase | Status |
|---|---|
| Security hardening | ✅ Complete |
| Data integrity + snapshots | ✅ Complete |
| Folder structure + permissions | ✅ Complete |
| User accounts + groups | ✅ Complete |
| Outline wiki | ✅ Deployed |
| Team onboarding (Tailscale + NAS) | 🔄 Pilot phase |
| Hyper Backup to GCS (Coldline) | ⬜ Planned |
| Additional containers (n8n, Uptime Kuma) | ⬜ Planned |
| Project handover | ⬜ Planned |
