const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('==================================================');
console.log('       DevOps Batch 14 - Application Build        ');
console.log('==================================================');

const rootDir = __dirname;
const distDir = path.join(rootDir, 'dist');
const srcDir = path.join(rootDir, 'src');

// 1. Clean existing dist directory
if (fs.existsSync(distDir)) {
  console.log('[BUILD] Cleaning previous dist directory...');
  fs.rmSync(distDir, { recursive: true, force: true });
}
fs.mkdirSync(distDir, { recursive: true });
fs.mkdirSync(path.join(distDir, 'src'), { recursive: true });

// 2. Copy source files to dist/src
console.log('[BUILD] Copying source files to dist/src...');
const srcFiles = fs.readdirSync(srcDir);
srcFiles.forEach(file => {
  const srcFile = path.join(srcDir, file);
  const destFile = path.join(distDir, 'src', file);
  fs.copyFileSync(srcFile, destFile);
  console.log(`  -> Copied: src/${file}`);
});

// 3. Extract Git commit hash if in a git repository
let gitCommit = 'standalone';
try {
  gitCommit = execSync('git rev-parse --short HEAD 2>/dev/null', { encoding: 'utf8', cwd: rootDir }).trim();
} catch (e) {
  gitCommit = process.env.GITHUB_SHA ? process.env.GITHUB_SHA.substring(0, 7) : 'standalone';
}
if (!gitCommit) {
  gitCommit = process.env.GITHUB_SHA ? process.env.GITHUB_SHA.substring(0, 7) : 'initial-dev';
}

// 4. Generate build metadata
const pkg = require('./package.json');
const buildInfo = {
  name: pkg.name,
  version: pkg.version,
  buildTime: new Date().toISOString(),
  gitCommit: gitCommit,
  nodeVersion: process.version,
  platform: process.platform,
  arch: process.arch,
  ciEnvironment: process.env.GITHUB_ACTIONS ? 'GitHub Actions Self-Hosted' : 'Local Runner',
  artifactType: 'Production Bundle'
};

fs.writeFileSync(
  path.join(distDir, 'build-info.json'),
  JSON.stringify(buildInfo, null, 2),
  'utf8'
);
console.log('[BUILD] Generated dist/build-info.json');

// 5. Generate production package.json without devDependencies
const prodPkg = {
  name: pkg.name,
  version: pkg.version,
  description: pkg.description,
  main: 'src/server.js',
  scripts: {
    start: 'node src/server.js'
  },
  dependencies: pkg.dependencies,
  license: pkg.license
};

fs.writeFileSync(
  path.join(distDir, 'package.json'),
  JSON.stringify(prodPkg, null, 2),
  'utf8'
);
console.log('[BUILD] Generated production dist/package.json');

console.log('==================================================');
console.log('✓ BUILD COMPLETED SUCCESSFULLY');
console.log(`✓ Output directory: ${distDir}`);
console.log('==================================================');
