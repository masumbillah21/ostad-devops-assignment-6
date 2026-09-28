const fs = require('fs');
const path = require('path');

const targetDir = path.join(__dirname, '..', 'docs', 'screenshots');
fs.mkdirSync(targetDir, { recursive: true });

const screenshots = [
  {
    filename: '01-prometheus-targets-up.svg',
    title: 'Prometheus Targets: Node Exporter UP',
    subtitle: 'http://localhost:9090/targets showing node_exporter state UP (1/1)',
    category: 'PROMETHEUS'
  },
  {
    filename: '02-prometheus-query-metrics.svg',
    title: 'Prometheus Query & Graph',
    subtitle: 'Expression query (e.g. node_cpu_seconds_total) showing scraped metrics',
    category: 'PROMETHEUS'
  },
  {
    filename: '03-node-exporter-metrics.svg',
    title: 'Node Exporter /metrics Endpoint',
    subtitle: 'http://localhost:9100/metrics raw system metrics output',
    category: 'NODE EXPORTER'
  },
  {
    filename: '04-grafana-prometheus-datasource.svg',
    title: 'Grafana Prometheus Datasource Verified',
    subtitle: 'Connection test green banner: "Successfully queried the Prometheus API"',
    category: 'GRAFANA'
  },
  {
    filename: '05-grafana-monitoring-dashboard.svg',
    title: 'Grafana System Metrics Dashboard',
    subtitle: 'Full dashboard featuring CPU, Memory, Disk, and Network usage panels',
    category: 'GRAFANA'
  },
  {
    filename: '06-grafana-loki-datasource.svg',
    title: 'Grafana Loki Datasource Verified',
    subtitle: 'Connection test green banner: "Data source connected and labels received"',
    category: 'LOKI'
  },
  {
    filename: '07-grafana-loki-explore-logs.svg',
    title: 'Grafana Explore: Loki Logs Stream',
    subtitle: 'LogQL query {job="varlogs"} displaying system log streams',
    category: 'LOKI'
  },
  {
    filename: '08-github-runner-online.svg',
    title: 'GitHub Actions Self-Hosted Runner Online',
    subtitle: 'Repo Settings > Actions > Runners showing green "Idle / Online" status',
    category: 'GITHUB ACTIONS'
  },
  {
    filename: '09-github-actions-workflow-success.svg',
    title: 'GitHub Actions CI Workflow Execution',
    subtitle: 'Build → Test → Artifact Generation stages passing with green checkmarks',
    category: 'GITHUB ACTIONS'
  },
  {
    filename: '10-github-actions-artifacts-uploaded.svg',
    title: 'GitHub Actions Artifacts Section',
    subtitle: 'Artifacts table displaying uploaded build-artifact bundle',
    category: 'GITHUB ACTIONS'
  }
];

screenshots.forEach((item, idx) => {
  const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540" viewBox="0 0 960 540">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0f172a" />
      <stop offset="100%" stop-color="#1e293b" />
    </linearGradient>
    <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#38bdf8" />
      <stop offset="100%" stop-color="#818cf8" />
    </linearGradient>
  </defs>
  <rect width="960" height="540" fill="url(#bg)" rx="16" />
  <rect x="30" y="30" width="900" height="480" fill="none" stroke="#334155" stroke-width="2" stroke-dasharray="8 8" rx="12" />
  
  <rect x="60" y="60" width="180" height="32" rx="16" fill="#38bdf8" fill-opacity="0.15" />
  <text x="150" y="81" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" font-weight="700" fill="#38bdf8" text-anchor="middle" letter-spacing="1.5">${item.category}</text>
  
  <text x="60" y="150" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="28" font-weight="700" fill="#f8fafc">Proof #${idx + 1}: ${item.title}</text>
  <text x="60" y="190" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="16" fill="#94a3b8">${item.subtitle}</text>
  
  <g transform="translate(60, 240)">
    <rect width="840" height="220" fill="#0b1120" rx="8" stroke="#1e293b" stroke-width="1.5" />
    <circle cx="28" cy="24" r="6" fill="#ef4444" />
    <circle cx="48" cy="24" r="6" fill="#eab308" />
    <circle cx="68" cy="24" r="6" fill="#22c55e" />
    <line x1="0" y1="44" x2="840" y2="44" stroke="#1e293b" stroke-width="1.5" />
    <text x="420" y="125" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="18" font-weight="600" fill="#64748b" text-anchor="middle">📸 Capture &amp; replace with your actual screenshot</text>
    <text x="420" y="155" font-family="monospace" font-size="13" fill="#38bdf8" text-anchor="middle">Save file as: docs/screenshots/${item.filename.replace('.svg', '.png')}</text>
  </g>
</svg>`;

  fs.writeFileSync(path.join(targetDir, item.filename), svgContent, 'utf8');
});

console.log('✓ Generated 10 screenshot placeholder SVGs in docs/screenshots/');
