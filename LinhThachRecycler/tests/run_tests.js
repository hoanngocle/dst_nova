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
  assert.equal(tableValue(source, "xd_bysp"), 20);
  assert.equal(tableValue(source, "xd_baihu_skin"), 24);
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
  assert.match(source, /type\(ingredient\.type\)\s*~=\s*"string"/);
});

test("stack and durability are applied in the safe order", () => {
  const source = read("scripts/nova_lingshi_pricing.lua");
  assert.match(source, /unit_value\s*=\s*ApplyDurability/);
  assert.match(source, /units\s*=\s*unit_value\s*\*\s*count/);
  assert.equal(scaledUnitValue(6, 0.5) * 4, 12);
});

test("machine owns replicated integer state and persists a clamped balance", () => {
  const source = read("scripts/prefabs/nova_lingshi_recycler.lua");
  assert.match(source, /net_uint\(/);
  assert.match(source, /_nova_balance/);
  assert.match(source, /_nova_preview/);
  assert.match(source, /_nova_rejected/);
  assert.match(source, /_nova_status/);
  assert.match(source, /_nova_confirm/);
  assert.match(source, /nova_balance_units\s*=\s*inst\._balance_units/);
  assert.match(source, /math\.max\(0,\s*math\.floor\(tonumber\(data\.nova_balance_units\)\s*or\s*0\)\)/);
});

test("high value confirmation is tied to the current container revision", () => {
  const source = read("scripts/prefabs/nova_lingshi_recycler.lua");
  assert.match(source, /CONFIRM_UNITS\s*=\s*10/);
  assert.match(source, /inst\._content_revision\s*=\s*inst\._content_revision\s*\+\s*1/);
  assert.match(source, /inst\._confirm_revision\s*==\s*inst\._content_revision/);
  assert.match(source, /inst\._confirm_userid\s*==\s*UserKey\(player\)/);
  assert.match(source, /ClearConfirmation\(inst\)/);
});

test("refinement removes only server-requoted accepted slots", () => {
  const source = read("scripts/prefabs/nova_lingshi_recycler.lua");
  assert.match(source, /for\s+slot\s*=\s*1,\s*SLOT_COUNT\s+do/);
  assert.match(source, /pricing\.GetItemQuote\(item,\s*AllRecipes\)/);
  assert.match(source, /if\s+quote\.accepted\s+then/);
  assert.match(source, /RemoveItemBySlot\(entry\.slot\)/);
  assert.match(source, /removed\s*==\s*entry\.item/);
  assert.match(source, /removed:Remove\(\)/);
  assert.match(source, /inst\._busy/);
});

test("withdrawal suppresses full-inventory drops and charges only accepted stones", () => {
  const source = read("scripts/prefabs/nova_lingshi_recycler.lua");
  assert.match(source, /SpawnPrefab\("xd_lingshi1"\)/);
  assert.match(source, /old_ignorefull\s*=\s*inventory\.ignorefull/);
  assert.match(source, /inventory\.ignorefull\s*=\s*true/);
  assert.match(source, /pcall\(inventory\.GiveItem,\s*inventory,\s*stone\)/);
  assert.match(source, /inventory\.ignorefull\s*=\s*old_ignorefull/);
  assert.match(source, /if\s+not\s+ok\s+or\s+not\s+accepted\s+then[\s\S]*stone:Remove\(\)[\s\S]*break/);
  assert.match(source, /inst\._balance_units\s*=\s*inst\._balance_units\s*-\s*2/);
});

test("machine cannot be hammered while either items or fractional credit remain", () => {
  const source = read("scripts/prefabs/nova_lingshi_recycler.lua");
  assert.match(source, /container:IsEmpty\(\)\s+and\s+inst\._balance_units\s*==\s*0/);
  assert.match(source, /workable:SetWorkable\(CanHammer\(inst\)\)/);
  assert.doesNotMatch(source, /AddComponent\("burnable"\)/);
});

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) {
  process.exit(1);
}
