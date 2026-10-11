# Production Linux System Health Monitor & Security Audit Engine

A modular, lightweight Bash-based system monitoring and auditing daemon designed to evaluate compute utilization, disk consumption, critical service uptime, and unauthorized authentication attempts across Linux host instances.

## 📌 Architecture & Design Principles

* **Zero External Dependencies:** Built natively using POSIX-compliant Bash syntax and standard core utilities (`awk`, `free`, `systemctl`, `journalctl`).
* **Defensive Shell Scripting:** Configured with `set -euo pipefail` to guarantee strict error-handling, prevent silent failures, and catch unbound variables.
* **Non-Root Graceful Degradation:** Dynamically detects `/var/log/` permissions, automatically falling back to local working directories for unprivileged user execution.
* **Standardized Audit Logging:** Emits RFC-compliant timestamped status levels (`INFO`, `WARN`, `CRITICAL`, `SECURITY`) compatible with log forwarders (FluentBit, Promtail).

---

## ⚙️ Monitored Metrics & Thresholds

| Metric | Source Mechanism | Default Threshold | Escalation Level |
| :--- | :--- | :--- | :--- |
| **CPU Usage** | `top` idle snapshot computation | ≥ 80% | `CRITICAL` |
| **Memory Buffer** | Memory calculation via `free -m` | ≥ 85% | `WARNING` |
| **Disk Storage** | Root partition block audit via `df` | ≥ 80% | `CRITICAL` |
| **Service Daemon** | Systemd unit state validation | State != `active` | `WARN` |
| **Auth Failures** | SSH journal parsing over rolling hour | > 5 attempts | `SECURITY` |

---

## 🚀 Deployment & Installation

### 1. Clone Repository & Grant Permissions
```bash
git clone [https:/iamsalmanpkty-art/github.com//linux-system-monitor-automation.git](https://github.com/iamsalmanpkty-art/linux-system-monitor-automation.git)
cd linux-system-monitor-automation
chmod +x system_health_check.sh
