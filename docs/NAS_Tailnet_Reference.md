# Tailnet / Tailscale Reference

---

## GitHub Organization

**URL:** `https://github.com/<org>`

| GitHub Display Name | Membership | Role |
|---|---|---|
| User A | Direct assignment | Owner |
| User B | Direct assignment | Owner |

---

## Tailnet

**Display name:** `<org>.github`
**DNS name:** `<tailnet-id>.ts.net`

### Nameservers

- **MagicDNS:** `<tailnet-id>.ts.net`
- **Global nameservers:** Override DNS → Cloudflare

---

## Machines

| Hostname | Tags | Tailscale IP |
|---|---|---|
| celnas | tag:admin, tag:nas | 100.x.x.x |
| desktop-user-a | tag:admin | 100.x.x.x |
| phone-user-a | tag:member | 100.x.x.x |
| laptop-user-b | tag:member | 100.x.x.x |

### Users

| User | Role |
|---|---|
| User A | Owner |
| User B | Member |

### Tags

`admin` · `nas` · `member`

---

## ACL Policy (JSON)

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["tag:nas:*"]
    },
    {
      "action": "accept",
      "src": ["tag:member"],
      "dst": ["tag:nas:443", "tag:nas:445", "tag:nas:5000", "tag:nas:5001", "tag:nas:6690"]
    },
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["tag:admin:*"]
    }
  ],
  "tagOwners": {
    "tag:admin":  ["autogroup:admin"],
    "tag:member": ["autogroup:admin"],
    "tag:nas":    ["autogroup:admin"]
  }
}
```

### Traffic Rules

**Rule 1 — Admin → NAS (full)**
Machines tagged `admin` can reach the NAS on all ports.

**Rule 2 — Member → NAS (restricted)**
Machines tagged `member` can reach the NAS on 5 ports only:
- 443 — HTTPS
- 445 — SMB file shares
- 5000 — DSM web console (HTTP)
- 5001 — DSM web console (HTTPS)
- 6690 — Synology Drive client sync

**Rule 3 — Admin ↔ Admin**
Admin machines can talk to each other on all ports.

**Default deny.** Members can't reach admin machines. Members can't reach each other. Untagged devices are completely isolated.

**Tag ownership:** Only tailnet Owners can assign tags. No one can escalate their own access.

> ⚠️ **DO NOT FORGET TO ASSIGN TAGS TO DEVICES — untagged devices are isolated by default.**

---

## Device Approval

- **Enabled** — new devices must be manually approved by admin/owner
- **Key expiry:** disabled for all devices

---

## HTTPS Certificate

- Issued via `tailscale cert celnas.<tailnet-dns>.ts.net` (Let's Encrypt, auto-provisioned by Tailscale for `*.ts.net` domains)
- Imported into DSM → Control Panel → Security → Certificate
- Renewal: 90 days
- HTTPS Certificates: **enabled** in Tailscale admin console

---

## DSM Scheduled Tasks

### 1. TUN Module (boot-up)

Enables the TUN kernel module for Tailscale direct tunnel mode. Without TUN, Tailscale falls back to userspace/DERP relay, adding latency and preventing direct TCP/ICMP. DSM 7 sandbox prevents Tailscale from creating TUN on its own.

**User:** root — **Trigger:** boot-up

```bash
insmod /lib/modules/tun.ko
mkdir -p /dev/net
mknod /dev/net/tun c 10 200 2>/dev/null
chmod 0666 /dev/net/tun
```

### 2. Tailscale Restart (boot-up)

Restarts Tailscale after boot so it picks up the TUN device from Task 1.

**User:** root — **Trigger:** boot-up

```bash
/var/packages/Tailscale/target/bin/tailscale down
sleep 2
/var/packages/Tailscale/target/bin/tailscale up
```

### 3. Certificate Renewal (monthly)

Generates and imports a Let's Encrypt TLS certificate into DSM. Monthly run ensures renewal well before the 90-day expiration.

**User:** root — **Trigger:** monthly

```bash
/var/packages/Tailscale/target/bin/tailscale configure synology-cert
```

> 🔍 **TO BE MONITORED** — verify cert renewal works as expected after first run.

---

## Version

Tailscale manually updated to **v1.96.4** on DSM.
