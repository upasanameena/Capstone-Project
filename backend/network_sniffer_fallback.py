import os
import csv
import re
import signal
import time
from datetime import datetime, timezone

try:
    from scapy.all import sniff, TCP, UDP, IP, Raw
except Exception as exc:  # pragma: no cover
    raise SystemExit(
        f"[FATAL] scapy is required for fallback sniffer. Install with: pip install scapy\nError: {exc}"
    )


# Get BACKEND_ROOT from environment, or use script's directory
BACKEND_ROOT = os.environ.get("BACKEND_ROOT")
if not BACKEND_ROOT:
    # Default to the directory where this script is located
    BACKEND_ROOT = os.path.abspath(os.path.dirname(__file__))
else:
    BACKEND_ROOT = os.path.abspath(BACKEND_ROOT)

ALLOWED_CSV = os.path.join(BACKEND_ROOT, "network_allowed.csv")
BLOCKED_CSV = os.path.join(BACKEND_ROOT, "network_blocked.csv")


SUSPICIOUS_PORTS = {
    23,     # telnet
    2323,   # alternative telnet
    3389,   # RDP
    445,    # SMB
    1433,   # MSSQL
    1521,   # Oracle
    3306,   # MySQL
    5432,   # PostgreSQL
    5900,   # VNC
}

PAYLOAD_PATTERNS = [
    re.compile(rb"(union\s+select|or\s+1=1|sleep\()", re.I),
    re.compile(rb"(<script|onerror=|javascript:)", re.I),
    re.compile(rb"(\bwget\b|\bcurl\b|/bin/sh|;\s*nc\b)", re.I),
]


def ensure_csv(path: str) -> None:
    if not os.path.exists(path):
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow([
                "timestamp",
                "src_ip",
                "dst_ip",
                "protocol",
                "src_port",
                "dst_port",
                "length",
                "decision",
                "reason",
            ])


def log_row(path: str, row: list[str]) -> None:
    with open(path, "a", newline="", encoding="utf-8") as f:
        csv.writer(f).writerow(row)


def classify_packet(pkt) -> tuple[str, str]:
    """Return (decision, reason). decision in {ALLOW, BLOCK}."""
    ip = pkt.getlayer(IP)
    if ip is None:
        return "ALLOW", "non-ip"

    length = len(pkt)
    proto = "OTHER"
    sport = dport = 0

    reason_parts: list[str] = []

    if TCP in pkt:
        proto = "TCP"
        sport = int(pkt[TCP].sport)
        dport = int(pkt[TCP].dport)

        if dport in SUSPICIOUS_PORTS:
            reason_parts.append(f"suspicious_port:{dport}")

        # Look for payload-based indicators
        raw = pkt[Raw].load if Raw in pkt else b""
        if raw:
            for rgx in PAYLOAD_PATTERNS:
                if rgx.search(raw):
                    reason_parts.append(f"payload:{rgx.pattern.decode(errors='ignore')[:24]}")
                    break

    elif UDP in pkt:
        proto = "UDP"
        sport = int(pkt[UDP].sport)
        dport = int(pkt[UDP].dport)

        if dport in SUSPICIOUS_PORTS:
            reason_parts.append(f"suspicious_port:{dport}")

    decision = "BLOCK" if reason_parts else "ALLOW"
    reason = ",".join(reason_parts) if reason_parts else "baseline"
    return decision, reason


def handle_packet(pkt) -> None:
    now = datetime.now(timezone.utc).isoformat()
    ip = pkt.getlayer(IP)
    src_ip = ip.src if ip else "-"
    dst_ip = ip.dst if ip else "-"
    proto = "TCP" if TCP in pkt else ("UDP" if UDP in pkt else "OTHER")
    sport = int(pkt[TCP].sport) if TCP in pkt else (int(pkt[UDP].sport) if UDP in pkt else 0)
    dport = int(pkt[TCP].dport) if TCP in pkt else (int(pkt[UDP].dport) if UDP in pkt else 0)
    length = len(pkt)

    decision, reason = classify_packet(pkt)

    row = [now, src_ip, dst_ip, proto, str(sport), str(dport), str(length), decision, reason]

    if decision == "BLOCK":
        log_row(BLOCKED_CSV, row)
    else:
        log_row(ALLOWED_CSV, row)


def main() -> None:
    os.makedirs(BACKEND_ROOT, exist_ok=True)
    ensure_csv(ALLOWED_CSV)
    ensure_csv(BLOCKED_CSV)

    print("\n================ Network Sniffer (Fallback) ================")
    print(f"Writing allowed   => {ALLOWED_CSV}")
    print(f"Writing blocked   => {BLOCKED_CSV}")
    print("This mode DOES NOT DROP packets. It simulates a network layer")
    print("decision and logs to CSV so your UI can visualize in real-time.")
    print("Run with sudo for best capture rates. Press Ctrl+C to stop.\n")

    def _graceful_exit(signum, frame):  # noqa: ARG001
        print("\nStopping sniffer...")
        raise SystemExit(0)

    signal.signal(signal.SIGINT, _graceful_exit)
    signal.signal(signal.SIGTERM, _graceful_exit)

    # Default interface: scapy picks one. You can set IFACE env to override
    iface = os.environ.get("IFACE")
    bpf_filter = os.environ.get("BPF", "ip")  # sniff only IP by default

    # Start sniffing
    sniff(
        iface=iface,
        filter=bpf_filter,
        prn=handle_packet,
        store=False,
    )


if __name__ == "__main__":
    main()


