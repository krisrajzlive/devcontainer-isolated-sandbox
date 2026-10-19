"""Assert the sandbox guarantees from the inside. Exit code 0 means all hold."""
import os
import socket
import sys
from pathlib import Path


def no_internet() -> bool:
    for host in ("1.1.1.1", "8.8.8.8"):
        try:
            socket.create_connection((host, 443), timeout=3).close()
            return False
        except OSError:
            pass
    try:
        socket.gethostbyname("example.com")
        return False
    except OSError:
        return True


def root_fs_read_only() -> bool:
    try:
        Path("/etc/.probe").write_text("x")
        return False
    except OSError:
        return True


def workspace_writable() -> bool:
    probe = Path("/workspace/.probe")
    try:
        probe.write_text("x")
        probe.unlink()
        return True
    except OSError:
        return False


def no_host_mounts() -> bool:
    mounts = Path("/proc/mounts").read_text().splitlines()
    markers = ("/run/desktop", "/host_mnt", "/mnt/host", "9p", "virtiofs", "drvfs")
    return not any(m in line for line in mounts for m in markers)


def not_root() -> bool:
    return os.geteuid() != 0


def no_capabilities() -> bool:
    for line in Path("/proc/self/status").read_text().splitlines():
        if line.startswith("CapEff:"):
            return int(line.split()[1], 16) == 0
    return False


CHECKS = [
    ("no outbound network / DNS", no_internet),
    ("root filesystem is read-only", root_fs_read_only),
    ("workspace volume is writable", workspace_writable),
    ("no host bind mounts", no_host_mounts),
    ("running as non-root user", not_root),
    ("all Linux capabilities dropped", no_capabilities),
]

if __name__ == "__main__":
    failed = 0
    for name, check in CHECKS:
        ok = check()
        failed += not ok
        print(f"[{'PASS' if ok else 'FAIL'}] {name}")
    sys.exit(1 if failed else 0)
