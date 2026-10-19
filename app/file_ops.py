"""Small workload that exercises file operations inside the sandbox."""
from pathlib import Path

WORKSPACE = Path("/workspace")


def main() -> None:
    out = WORKSPACE / "output"
    out.mkdir(exist_ok=True)
    target = out / "report.txt"
    target.write_text("written inside the sandbox volume\n")
    print(f"wrote {target} ({target.stat().st_size} bytes)")
    print("workspace contents:", sorted(p.name for p in WORKSPACE.iterdir()))


if __name__ == "__main__":
    main()
