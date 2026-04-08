# CELNAS — First Connection Guide

---

## Overview

Your account has been created on CELNAS, the company file server at the HCMC office.

**CELNAS address:** `celnas.<tailnet-dns>.ts.net`

To access the NAS from outside the office, you need Tailscale (a VPN).

---

## What you need

- Your NAS username (`firstname.lastname`)
- Your temporary password (provided by your admin)
- Tailscale installed on your device (see below)
- An authenticator app on your phone (Google Authenticator, Microsoft Authenticator, Synology Secure SignIn, etc.)

---

## Step 1 — Install Tailscale

1. Download Tailscale from https://tailscale.com/download
2. Install and launch the application
3. Your admin will provide you with an auth key and handle the registration of your device on the company network
4. Once connected, you should see the Tailscale icon in your system tray (Windows) or menu bar (macOS) showing a connected state

## Step 2 — First login

5. Open your browser and go to: `https://celnas.<tailnet-dns>.ts.net`
6. Enter your username and temporary password
7. You may be asked to change your password. If so, choose a strong password:
   - Minimum 12 characters
   - At least 1 special character
   - Cannot be a commonly used password
   - Password expires every 90 days

## Step 3 — Set up two-factor authentication (2FA)

2FA is mandatory. You will be prompted to set it up during your first login.

8. DSM displays a QR code on screen
9. Download or open your authenticator app and scan the QR code
10. Enter the 6-digit code from the app to confirm
11. Save your backup codes somewhere safe. If you lose your phone and don't have backup codes, an admin will need to reset your 2FA.

---

## Troubleshooting

**Cannot reach the NAS**
- Check that Tailscale is connected (icon in system tray should be active)
- Use the hostname `celnas.<tailnet-dns>.ts.net`, not an IP address

**2FA code not accepted**
- Make sure your phone clock is set to automatic (Settings > Date & Time)
- Codes rotate every 30 seconds — try the next one
- Contact your admin if it keeps failing
