const assert = require('node:assert/strict');
const fs = require('node:fs');
const { execFileSync } = require('node:child_process');
const html = fs.readFileSync('index.html', 'utf8');
const baseline = execFileSync('git', ['show', 'before-preview-features-20261119:index.html'], { encoding: 'utf8' });
function protectedBlocks(text) {
  text = text.replace(/\r\n/g, '\n');
  return [text.match(/<section class="section hero"[\s\S]*?<\/section>/)[0], ...text.matchAll(/<article class="featured-product launch-banner[\s\S]*?<\/article>/g)].map(item => typeof item === 'string' ? item : item[0]);
}
assert.deepEqual(protectedBlocks(html), protectedBlocks(baseline), 'Hero and launch banners must stay unchanged');
for (const match of baseline.matchAll(/(?:src|data-full)="(sunshine-assets-audit\/[^"\s]*banner[^"\s]*)"/g)) {
  const old = execFileSync('git', ['show', `before-preview-features-20261119:${match[1]}`], { maxBuffer: 20 * 1024 * 1024 });
  assert.deepEqual(fs.readFileSync(match[1]), old, `Banner asset ${match[1]} unchanged`);
}
assert.match(html, /src="sunshine-assets-audit\/oleodeacai.jpeg"/);
assert.doesNotMatch(html, /exclusive-blends-title|Blends Exclusivos|Potência Indígena|cXJ1kMPq-11.webp/);
assert.match(html, /<li class="tag">Açaí<\/li>/);
assert.match(html, /id="product-carousel-root"/);
assert.match(html, /product-enhancements.css/);
assert.doesNotMatch(html, /preview.css|glossy.css|noindex/);
for (const match of html.matchAll(/(?:src|href|data-full)="([^"#]+)"/g)) {
  if (/^(https?:|mailto:|tel:)/.test(match[1])) continue;
  assert.ok(fs.existsSync(match[1].split('?')[0]), `Missing ${match[1]}`);
}
const css = fs.readFileSync('product-enhancements.css', 'utf8');
assert.match(css, /backdrop-filter/);
assert.match(css, /\.products-footer[\s\S]*clamp\(1.15rem, 2vw, 1.45rem\)/);
assert.doesNotMatch(css, /\.site-header|\.hero\s*\{|\.launch-banner/);
console.log('PASS: preserved banners/hero, assets, removed product, copy, carousel and scoped styles');
