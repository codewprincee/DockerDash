# DockerDash

A native macOS Docker dashboard — containers, images, volumes, networks, and compose projects in one window.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Dashboard** — System info, container/image/volume counts, running containers list
- **Containers** — List (running/stopped/all), start/stop/restart/remove, live logs, info, labels, mounts
- **Images** — List all images with size, pull/remove
- **Volumes** — List/remove volumes
- **Networks** — List networks with connected container count
- **Compose** — Auto-detects Docker Compose projects, grouped view
- **Command Palette** — `⌘K` quick navigation
- **Live Polling** — Dashboard auto-refreshes every 3 seconds

## Requirements

- macOS 14.0+
- Docker Desktop running

## Build & Run

```bash
git clone https://github.com/codewprincee/DockerDash.git
cd DockerDash
open DockerDash.xcodeproj
# ⌘R in Xcode
```

## Architecture

Talks directly to Docker Engine API via Unix socket (`/var/run/docker.sock`) using `curl`. No external dependencies.

## License

MIT
