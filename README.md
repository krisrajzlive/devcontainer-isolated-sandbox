# devcontainer-isolated-sandbox

A minimal dev container whose file operations stay **inside** the container and which has **no internet access** at runtime. Useful for running untrusted code, AI-agent tooling, or experiments without exposing the host's files or network.

[![verify-isolation](../../actions/workflows/verify.yml/badge.svg)](../../actions/workflows/verify.yml)

## How the isolation works

| Guarantee | Mechanism (`.devcontainer/docker-compose.yml`) |
|---|---|
| No internet, no LAN, no DNS | Network declared `internal: true` — no gateway, no route out |
| Host files unreachable | No bind mounts; work lives in Docker **named volumes** |
| No inbound access | No `ports:` published |
| Immutable system | `read_only: true` root filesystem; only `/tmp` (tmpfs), `/workspace` and `/home/dev` are writable |
| Least privilege | Non-root user, `cap_drop: ALL`, `no-new-privileges` |
| Resource limits | `pids_limit`, `mem_limit`, `cpus` |

Seed code (`app/`, `scripts/`) is baked into the image and copied into the volume on first create, so nothing is mounted from your machine.

## Prerequisites

Windows, macOS or Linux with Docker Desktop (Compose v2). VS Code with the Dev Containers extension is optional.

## Quick start (hands-free)

One command builds the sandbox, seeds it, runs the isolation checks and the workload, and leaves it running so you can inspect it in Docker Desktop:

```powershell
.
un.ps1            # Windows PowerShell
```
```bash
./run.sh             # macOS / Linux / Git Bash
```

Flags: `-Clean` / `--clean` removes it afterwards, `-Shell` / `--shell` drops you into a shell inside, `-Down` / `--down` removes it later.

## Usage

### Option A — VS Code

1. Open the folder, run **Dev Containers: Reopen in Container**.
2. `postCreateCommand` seeds `/workspace` and runs the isolation checks automatically.

### Option B — plain Docker (no VS Code)

```bash
docker compose -f .devcontainer/docker-compose.yml up -d --build
docker compose -f .devcontainer/docker-compose.yml exec workspace sh -c "cp -rn /opt/seed/. /workspace/"
docker compose -f .devcontainer/docker-compose.yml exec workspace python scripts/verify_isolation.py
docker compose -f .devcontainer/docker-compose.yml exec workspace python app/file_ops.py
docker compose -f .devcontainer/docker-compose.yml exec workspace bash   # interactive shell
```

Expected output of the verification:

```
[PASS] no outbound network / DNS
[PASS] root filesystem is read-only
[PASS] workspace volume is writable
[PASS] no host bind mounts
[PASS] running as non-root user
[PASS] all Linux capabilities dropped
```

### Cleanup (deletes all sandbox data)

```bash
docker compose -f .devcontainer/docker-compose.yml down -v
```

## Moving files in and out

Because nothing is mounted, transfer is explicit:

```bash
docker compose -f .devcontainer/docker-compose.yml cp ./local-file.txt workspace:/workspace/
docker compose -f .devcontainer/docker-compose.yml cp workspace:/workspace/output ./output
```

## Caveats

- The **build** step needs internet (to pull the base image). Only the **running** sandbox is offline.
- With no network, installing packages from inside is impossible by design. Add dependencies to the `Dockerfile` and rebuild.
- VS Code installs its server and extensions into the container from the host side; marketplace extensions that need internet at runtime will not work.
- This is container-level isolation, not a VM. For hostile workloads, add gVisor/Kata or run Docker Desktop with Enhanced Container Isolation.

## Layout

```
.devcontainer/   Dockerfile, docker-compose.yml, devcontainer.json
app/             workload that performs file operations in the sandbox
scripts/         verify_isolation.py — asserts the guarantees from inside
.github/         CI that builds the sandbox and runs the checks
```

## License

MIT
