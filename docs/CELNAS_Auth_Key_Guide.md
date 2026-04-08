# CELNAS — Auth Key Guide

**Audience:** Tailnet Owner or Tailnet User with Admin privilege
**Context:** CELNAS is only accessible through the Tailscale tailnet. Devices must be pre-registered to access CELNAS. The method chosen is **auth key**. This guide covers auth key generation and device registration.

One single reusable key can be used to register all devices.

---

## 1. Generate an auth key (if you don't already have one)

1. Go to https://login.tailscale.com/admin/settings/keys
2. Click **Generate auth key**
3. Configure the key:
   - **Reusable:** Yes
   - **Expiry:** 90 days (max). After expiry, already-connected devices stay connected. You just need to generate a new key for future onboardings.
   - **Tags:** `tag:member` (this auto-applies ACL restrictions)
   - **Pre-approved:** No. As an additional security layer, any device registered with the auth key will still require manual approval by a Tailnet Owner from the Tailscale admin console.
4. Click **Generate key** and copy it immediately. It won't be shown again.

> **Store the key securely.** A stolen reusable key lets anyone join your tailnet. If compromised, revoke it immediately from the admin console.

---

## 2. Register a device

### Desktop (Windows / macOS)

The desktop Tailscale app does not have an auth key option in the GUI. You need command-line access.

1. On the user's machine, open a terminal (PowerShell as administrator on Windows, Terminal on macOS)
2. Run:

**Windows:**
```
tailscale up --auth-key=tskey-auth-xxxxxxxxxxxx
```

**macOS:**
```
sudo tailscale up --auth-key=tskey-auth-xxxxxxxxxxxx
```

Security note: the auth key will appear in shell history.

On Windows you can clear it with:
```
clear-History
```

Or better, use an environment variable:
```
$env:TS_AUTH_KEY = "tskey-auth-xxxxxxxxxxxx"
tailscale up --auth-key=$env:TS_AUTH_KEY
Remove-Item Env:TS_AUTH_KEY
```

### After registration (all devices)

3. If Device Approval is enabled and the key is not pre-approved, Tailnet Owner must go to admin console > Machines and approve the device
4. Verify the device has `tag:member` applied. If not, assign it manually from the admin console
5. On the device entry, **disable key expiry** so the device doesn't need to re-authenticate

---

## 3. Security

**Auth keys are sensitive secrets.**

Avoid: unencrypted email, Slack/Teams in clear text, SMS, shared text file on Drive.
Preferred methods: in-person, password manager shared vault, or encrypted messaging.

> **Note:** Auth keys are only used to register a device on the tailnet for the first time. Once the device is registered, the auth key can expire or be deleted — the device will remain registered.
