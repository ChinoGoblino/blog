---
title: "Homelab"
date: 2026-05-25T15:12:07+10:00
draft: false
---
This page outlines the system I run at home for my homelab. I don't quite feel comfortable making the repository public as, although I don't have any secrets committed, there are occasional snippets of personally identifiable information such as location variables. Security through obscurity 👍. The format of this page is inspired by [Shane Dowling's Homelab page](https://shanedowling.com/homelab/), which I will likewise keep updated to reflect any continual changes I make. The repository exists as a private GitHub repository, but also as a Forgejo mirror on my own infrastructure.

---

# Hardware

My current setup exists in a rack-mounted configuration (20 RU) within my living room. From top to bottom of the rack I have:

{{% details "**Router** — Intel N100 mini PC" %}}
Ordered from Aliexpress, my mini PC runs OPNsense with 8 GB RAM and 256 GB storage. This machine is completely overkill for routing but I hope to set it aside for a future Proxmox node to learn kubeadm, run a home testing environment, and host learning environments for the rest of my university subcommittee.
{{% /details %}}

{{% details "**Access Point** — Unifi 6" %}}
PoE-powered from the switch below. Managed via Unifi Controller running on the cluster. It *barely* provides a Wi-Fi connection to the rest of my house with the occasional dropouts in my room.
{{% /details %}}

{{% details "**Switch** — 8-port GbE unmanaged" %}}
Provides PoE to the AP and Ethernet to the rest of the rack.
{{% /details %}}

{{% details "**Compute Node** — ATX Box" %}}
The main k3s node, built from my old server's hardware.

- **CPU** - 12th Gen Intel Core i7-12700K (12 cores). Integrated graphics handle Jellyfin hardware transcoding.
- **Memory** - 64 GiB DDR4. Overkill for most of the workloads I run, but very helpful for my modded Minecraft servers.
- **Storage** - 14 TB across salvaged drives from the old NAS, configured as a BTRFS RAID1 pool for mirrored redundancy.
{{% /details %}}

{{% details "**UPS**" %}}
A Cyberpower OLS1000ERT2Ua mounted at the bottom of the rack, connected via USB to the main k3s node. NUT and a NUT prometheus exporter were set up via Ansible to handle a graceful shutdown on power loss and also feeding data to the monitoring stack as mentioned later in the blog.
{{% /details %}}

--- 

# Storage
Storage sits in its own section intentionally as it's an area I expect to build upon significantly. The current setup is quite simple: around six drives in a BTRFS RAID1 pool on the k3s compute node, mounted at `/mnt/payload`. All applications use `local-path` storage rather than persistent volume claims, which keeps things straightforward for now but limits flexibility.

The longer-term plan involves a proper JBOD or SAN setup with block storage and storage class management. This will allow me to support things like CNPG for database management and pave the way for a multi-node configuration. More on that in [What I Want to Work On Next](#what-i-want-to-work-on-next).

---

# Cluster Architecture

The cluster runs as a single-node Kubernetes setup using k3s, with Ansible playbooks to simplify system updates and document node bootstrapping.

## Secrets

Bitnami Sealed Secrets manages most secrets. Encrypted secrets are stored directly in the repository alongside the rest of the configuration, and are decrypted server-side using a private key that is not committed to Git. Having version-controlled secrets alongside everything else is appealing as recovery from a cluster meltdown only requires restoring that private key.

## Renovate

Renovate runs periodically against the GitHub repository to check for image updates. PRs are reviewed and approved manually before the new tags are applied and manifests are pushed to the cluster. Fully automated updates are tempting, but the risk of breaking changes has kept it manual for now.

## Ingress
The cluster uses Istio as the service mesh and reverse proxy via the Kubernetes Gateway API. This replaced Istio VirtualServices, which were less portable as the new API is now in a stable enough state that fit all my use-cases.

## SSO
Most services support SSO via SAML or OIDC. Authentik handles the specific flows I need well enough, though Ory is on the radar as version-controlled client definitions are a really appealing idea.

## Remote Access
Tailscale works reliably across all my devices. Self-hosting Headscale gives me control over the tailnet's coordination server and integrates with the SSO setup. The OPNsense router runs the Tailscale plugin as an exit node for LAN access, while a separate Tailscale exit node (routed through a Gluetun/Mullvad deployment) provides a more private browsing option.

---

# Services

## Infrastructure
- ForgeJo
- Adguard Home
- Cert-manager
- Multus - Required for Unifi Controller and AdGuard

## Media
- Immich
- Navidrome and Beets
- SearXNG

## Productivity
- Outline
- Memos
- Grist
- Vaultwarden
- Radicale

## Automation and Communication
- n8n
- ntfy
- Tuwunel
- Home assistant

## Monitoring
Monitoring deserves it's own explanation as its a bit of its own ecosystem. 

### Metrics
Prometheus scrapes metrics cluster-wide, with Grafana providing dashboards and visualisations. As someone who enjoys data and its presentation, this is one of the more satisfying parts of the setup.

### Logs
Loki handles log aggregation, with Grafana Alloy running as a `DaemonSet`, collecting both metrics and logs from across the cluster.

### Traces
Planned. Tempo will be added here once the rest of the observability stack is more settled to complete the LGTM stack. Distributed tracing should complement the existing metrics and log data nicely.

### External Data Collection
Various exporters exist within the cluster to scrape information such as SearXNG performances or my music listening habits.

Additionally, an Apollo Air-1 monitors room air quality over ESPHome and exports readings to Prometheus. A Home Assistant automation opens the room's ventilation when CO₂ crosses 1000 ppm.

---

# What I Want To Work On Next
- **Storage overhaul**: A JBOD system or SAN with block storage and proper storage class management would unlock things like CNPG for database management and make multi-node expansion viable. Alongside this, an encrypted buddy backup arrangement with a friend would address the lack of any meaningful automated backup. Currently photos go to Google Photos and application storage is occasionally copied to an external drive by hand.
- **Managed switch and VLANs**: Network segmentation for guest or untrusted devices would improve isolation.
- **Observability improvements**: Adding Tempo for distributed tracing (see above) and wiring up Alertmanager to ntfy would give faster visibility into service outages.
