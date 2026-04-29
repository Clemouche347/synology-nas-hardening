# Synology NAS — Admin Guide

**Device Onboarding, User Management & Permissions**

**Audience:** admin

---

## Architecture overview

The NAS is a Synology DS925+ (2×12TB RAID1, Btrfs, 20GB ECC RAM, DSM 7.3.2) at the HCMC office.

DSM = DiskStation Manager is Synology's web-based operating system / console that runs on the NAS.

Remote access goes through Tailscale.
Local access also Tailscale recommended.

### Network

- **Hostname DNS:** `nas.<tailnet-dns>.ts.net`
- **Tailnet:** `<org>.github`
- **Firewall:** LAN + Tailscale only. Everything else denied.

### Tailscale ACL summary

Three rules, everything else denied by default:

- `tag:admin → tag:nas` — all ports
- `tag:member → tag:nas` — ports 443, 445, 5000, 5001, 6690 only
- `tag:admin → tag:admin` — all ports (admin-to-admin)

Devices without a tag are completely isolated. Always assign tags.

### Tailnet users

- **User A** (github-user-a) — Owner
- **User B** (github-user-b) — Admin (temporary)

---

## Adding a new device to the tailnet

This is the procedure to onboard a team member's desktop device so they can access the NAS.

For office users also, connecting via Tailscale hostname is the recommended approach. Tailscale establishes a direct WireGuard tunnel over LAN (no DERP relay), and you get encrypted + identity-verified + ACL-enforced access. No reason to bypass it by using raw local IP — that would actually be less secure with zero speed gain worth mentioning.

### Prerequisites

- Tailscale installed on the device
- Tailnet activated by auth key on the device (auth key provided by Tailnet Owner)
- Only connect devices using auth keys, not tailnet user credentials

### Desktop onboarding (Windows / macOS)

The desktop Tailscale app does NOT have an auth key option in the GUI. You need command-line access.

1. On the user's machine, open a terminal
2. Run (as admin):

**Windows:**
```
tailscale up --auth-key=tskey-auth-xxxxxxxxxxxx
```

**macOS:**
```
sudo tailscale up --auth-key=tskey-auth-xxxxxxxxxxxx
```

3. Device Approval is enabled and the key is not pre-approved, tailscale owner to go to the admin console > Machines and approve the device
4. Owner to verify the device has `tag:member` applied. If not, assign it manually from the admin console
5. Owner to disable key expiry on the device

**Security note:** the auth key will appear in shell history. On Windows you can clear it with:

```
clear-History
```

Or better, use an environment variable:

```
$env:TS_AUTH_KEY = "tskey-auth-xxxxxxxxxxxx"
tailscale up --auth-key=$env:TS_AUTH_KEY
Remove-Item Env:TS_AUTH_KEY
```

### Mobile onboarding (iOS / Android) — Not allowed

---

## NAS user management

### User accounts

Convention: `firstname.lastname`. All accounts created in DSM Control Panel > User & Group.

Current groups:

- **administrators** — 3 admins. Full DSM admin.
- **org_manager** — 2 senior consultants.
- **org_staff** — 14 team members (Org A).
- **team_b** — 9 team members (Org B).
- **org_guest** — empty. For external per-project access.

### Creating a new user (administrators privilege)

1. DSM > Control Panel > User & Group > User > Create
2. Username: `firstname.lastname`
3. Set a temporary password and communicate it to the user securely
4. Assign to the appropriate group(s)
5. Create their SANDBOX subfolder: `/volume1/SANDBOX/firstname.lastname`
6. Set ACLs on the SANDBOX subfolder

### 2FA enforcement

2FA (OTP) is enforced for all users from first connection. If a user loses their authenticator:

1. DSM > Control Panel > User & Group > select user > Edit
2. Under the 2FA tab, reset their 2FA
3. User will be prompted to set up 2FA again on next login

---

## Permissions reference

### Critical rules

Deny on ANY group overrides Allow from another group.

- **administrators group:** always set explicit Read/Write on every shared folder. Leaving it blank = deny, which overrides other groups Allow.
- **users system group:** never set explicit No Access, or it blocks everyone.

- Subfolder created entails inherited permissions by default. Can be configured in Properties.
- Read permission on a folder means you can open it (= navigate into it) and see its contents.
- To set permissions only use DSM (the NAS web console), or SSH for advanced admin user.
- Avoid permission complexity. For example a shared folder with permissions, and subfolders with different permissions.
- Avoid permission per user, instead create a group, give permission to group, add user to group.
- Avoid changing permissions too frequently.
- Follow **Least privilege principle**: Each group receives the minimum level of access required to perform its role.

### Initial shared folder permissions summary

| Folder | administrators | org_mgr | org_staff | team_b | org_guest |
|---|---|---|---|---|---|
| ARCHIVE | RW | Read | No Access | No Access | No Access |
| INTERNAL | RW | Read | Read | No Access | No Access |
| MEDIA | RW | Read | Read | Read | No Access |
| PROJECTS | RW | Read | Read | Read | No Access |
| SANDBOX | RW | Read | Read | Read | No Access |
| TEAM_B | RW | No Access | No Access | RW | No Access |

- **SANDBOX:** RW for administrators. Read-Only at shared folder level for manager/staff/team_b groups. Per-user Read/Write overrides on individual subfolders with inheritance unchecked.
- **PROJECTS:** per-subfolder overrides for staff/team_b or other groups as needed.
- Entertainment subfolder under MEDIA: Read/Write for org_staff and org_manager.

---

## SMB access

- Always connect via `\\nas.<tailnet-dns>.ts.net`
- "Hide shared folders from users without permission" is enabled on DSM
- To disconnect a sticky SMB connection, try:

```
cmdkey /delete:nas.<tailnet-dns>.ts.net
```

Verify with:

```
cmdkey /list
```

---

## Synology Drive

This is an application layer that can be activated on any shared folder. It especially activates file versioning and the possibility to access the files via a Synology Drive Client software with Sync features.

- When a shared folder is created, you need to add it as "Team Folder" on Synology Drive DSM Console if you want the file versioning and other advanced features activated.
- Unlike SMB, the user can access a replication of the files on his/her own machine. To simplify, only SMB access is advertised.
- Versioning: 8 versions max, 30-day retention, oldest-first deletion.
- Versioning works on ALL protocols (SMB + Drive) once the folder is a Team Folder.
- File Locking is Drive-client only. An SMB user won't see that a file is locked and can overwrite it.

---

## Snapshots on shared folders

- Schedule: hourly, every day.
- Retention: 24 hourly, 7 daily, 4 weekly, 3 monthly + 5 latest.
- Immutable snapshots enabled (ransomware protection).
- Scope: all shared folders on Volume 1.

To restore a file from snapshot: DSM > Snapshot Replication > select folder > Recovery > browse snapshots.

---

## Tailscale maintenance

### DSM scheduled tasks

Three boot-time tasks run as root:

**1. TUN Module** — Loads the TUN kernel module so Tailscale runs in direct tunnel mode instead of relay (DERP). Without this, connections route through Tailscale's servers with added latency.

```
insmod /lib/modules/tun.ko
mkdir -p /dev/net
mknod /dev/net/tun c 10 200 2>/dev/null
chmod 0666 /dev/net/tun
```

**2. Tailscale Restart** — Restarts Tailscale after boot so it picks up the TUN device. Without this, it may silently fall back to relay mode.

```
/var/packages/Tailscale/target/bin/tailscale down
sleep 2
/var/packages/Tailscale/target/bin/tailscale up
```

**3. Certificate Renewal (monthly)** — Renews the Let's Encrypt TLS cert. Certs expire every 90 days; monthly run ensures timely renewal.

```
/var/packages/Tailscale/target/bin/tailscale configure synology-cert
```

> ⚠️ **This has to be monitored! Not sure it works!**

### Device removal (loss/theft)

1. Go to Tailscale admin console > Machines
2. Find the device and delete it
3. The device loses all tailnet access immediately

### Auth key revocation

If a reusable auth key is compromised:

1. Go to Tailscale admin console > Settings > Keys
2. Revoke the key. Already-registered devices stay connected.
3. Generate a new key for future onboardings.

---

## Contacts

- **Admin A** — admin-a@example.com (remote, France)
- **Admin B** — admin-b@example.com (HCMC)
