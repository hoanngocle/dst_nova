const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
let passed = 0;
let failed = 0;

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`PASS ${name}`);
  } catch (error) {
    failed += 1;
    console.error(`FAIL ${name}: ${error.message}`);
  }
}

function tableValue(source, prefab) {
  const escaped = prefab.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = source.match(new RegExp(`\\b${escaped}\\s*=\\s*(\\d+)\\s*,`));
  assert.ok(match, `missing numeric entry for ${prefab}`);
  return Number(match[1]);
}

function scaledUnitValue(baseUnits, percent) {
  return Math.max(1, Math.floor(baseUnits * Math.max(0, Math.min(1, percent))));
}

test("mod metadata requires every client and Tu Tien", () => {
  const source = read("modinfo.lua");
  assert.match(source, /dst_compatible\s*=\s*true/);
  assert.match(source, /all_clients_require_mod\s*=\s*true/);
  assert.match(source, /client_only_mod\s*=\s*false/);
  assert.match(source, /\[\"workshop-3721846643\"\]\s*=\s*true/);
});

test("pricing uses half-stone integers for common and rare examples", () => {
  const source = read("scripts/nova_lingshi_pricing.lua");
  assert.equal(tableValue(source, "cutgrass"), 1);
  assert.equal(tableValue(source, "log"), 2);
  assert.equal(tableValue(source, "gears"), 6);
  assert.equal(tableValue(source, "deerclops_eyeball"), 20);
  assert.equal(tableValue(source, "alterguardianhatshard"), 40);
});

test("durability scaling rounds down and never values an accepted item below half a stone", () => {
  assert.equal(scaledUnitValue(20, 1), 20);
  assert.equal(scaledUnitValue(20, 0.49), 9);
  assert.equal(scaledUnitValue(6, 0), 1);
  assert.equal(scaledUnitValue(1, 0.2), 1);
});

test("pricing guards currency, nested storage, protected items, and profitable recipe outputs", () => {
  const source = read("scripts/nova_lingshi_pricing.lua");
  assert.match(source, /\^xd_lingshi%d\+\$/);
  assert.match(source, /components\.container/);
  assert.match(source, /IsEmpty\(\)/);
  assert.match(source, /PROTECTED\[prefab\]/);
  assert.match(source, /recipe\.numtogive/);
  assert.match(source, /output_units\s*>\s*input_units/);
});

test("stack and durability are applied in the safe order", () => {
  const source = read("scripts/nova_lingshi_pricing.lua");
  assert.match(source, /unit_value\s*=\s*ApplyDurability/);
  assert.match(source, /units\s*=\s*unit_value\s*\*\s*count/);
  assert.equal(scaledUnitValue(6, 0.5) * 4, 12);
});

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) {
  process.exit(1);
}
