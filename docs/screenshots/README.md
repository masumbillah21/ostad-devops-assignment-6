# Screenshots Guide & Checklist

This directory contains the proof screenshots required for **DevOps Batch 14 — Assignment: Server Monitoring, Logging & CI Pipeline**.

Each screenshot must be captured from your active Ubuntu environment and saved here as a `.png` file.

---

## Required Screenshots Checklist

| # | Filename | Description | Source URL / Location |
|---|----------|-------------|-----------------------|
| 1 | `01-prometheus-targets-up.png` | Prometheus Targets page showing `node_exporter` as **UP** (1/1) | `http://<SERVER_IP>:9090/targets` |
| 2 | `02-prometheus-query-metrics.png` | Prometheus query/graph page showing Node Exporter metric results | `http://<SERVER_IP>:9090/graph` query `node_cpu_seconds_total` |
| 3 | `03-node-exporter-metrics.png` | Node Exporter raw metrics page | `http://<SERVER_IP>:9100/metrics` |
| 4 | `04-grafana-prometheus-datasource.png` | Grafana Prometheus datasource with green success banner | Grafana -> Connections -> Data Sources -> Prometheus -> "Save & test" |
| 5 | `05-grafana-monitoring-dashboard.png` | Grafana Dashboard showing CPU, RAM, Disk, and Network panels | Grafana -> Dashboards -> "DevOps Batch 14 - Server Monitoring" |
| 6 | `06-grafana-loki-datasource.png` | Grafana Loki datasource with green success banner | Grafana -> Connections -> Data Sources -> Loki -> "Save & test" |
| 7 | `07-grafana-loki-explore-logs.png` | Grafana Explore view querying Loki system logs | Grafana -> Explore -> Data source: Loki -> Query: `{job="varlogs"}` |
| 8 | `08-github-runner-online.png` | GitHub Actions runner showing green **Idle / Online** status | GitHub Repo -> Settings -> Actions -> Runners |
| 9 | `09-github-actions-workflow-success.png` | GitHub Actions CI run showing Build → Test → Artifact passing | GitHub Repo -> Actions -> Click latest successful run |
| 10 | `10-github-actions-artifacts-uploaded.png` | GitHub Actions Artifacts section with uploaded `build-artifact` | GitHub Repo -> Actions -> Run summary page -> Artifacts table |

---

## How to Capture and Replace Placeholders

1. Take your screenshot on your host machine (or inside the VM).
2. Save it directly to this folder (`docs/screenshots/`) with the matching `.png` extension (e.g. `01-prometheus-targets-up.png`).
3. The main `README.md` references these filenames and will automatically display your live screenshots!
