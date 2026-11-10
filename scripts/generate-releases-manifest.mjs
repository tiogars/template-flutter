// Generates releases/manifest.json describing the downloadable application builds.
// Usage: node generate-releases-manifest.mjs <releases-dir>
// Expected layout: <releases-dir>/<platform>/<artifact> + optional build-info.json.
import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const platforms = ['android', 'linux', 'windows'];
const root = process.argv[2];
if (!root) {
  console.error('Usage: node generate-releases-manifest.mjs <releases-dir>');
  process.exit(64);
}

function readBuildInfo(directory) {
  const file = join(directory, 'build-info.json');
  if (!existsSync(file)) return {};
  return JSON.parse(readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
}

const artifacts = platforms.flatMap((platform) => {
  const directory = join(root, platform);
  if (!existsSync(directory)) return [];
  const buildInfo = readBuildInfo(directory);
  return readdirSync(directory)
    .filter((name) => !name.startsWith('.') && name !== 'build-info.json')
    .filter((name) => statSync(join(directory, name)).isFile())
    .sort()
    .map((name) => {
      const content = readFileSync(join(directory, name));
      return {
        platform,
        fileName: name,
        path: `${platform}/${name}`,
        size: content.length,
        sha256: createHash('sha256').update(content).digest('hex'),
        version: buildInfo.version ?? null,
        apiBaseUrl: buildInfo.apiBaseUrl ?? null,
        builtAt: buildInfo.builtAt ?? null,
      };
    });
});

const manifest = { generatedAt: new Date().toISOString(), artifacts };
writeFileSync(join(root, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(`Wrote ${artifacts.length} artifact(s) to ${join(root, 'manifest.json')}`);
