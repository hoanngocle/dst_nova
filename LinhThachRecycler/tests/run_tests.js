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
  assert.match(source, /mod_dependencies\s*=\s*{\s*{\s*workshop\s*=\s*"workshop-3721846643"\s*},?\s*}/);
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
  assert.match(source, /components\.container\.onopenfn\s*=\s*OnOpen/);
  assert.match(source, /components\.container\.onclosefn\s*=\s*OnClose/);
  assert.doesNotMatch(source, /SetOnOpenFn|SetOnCloseFn/);
});

test("high value confirmation is tied to the current container revision", () => {
  const source = read("scripts/prefabs/nova_lingshi_recycler.lua");
  assert.match(source, /CONFIRM_UNITS\s*=\s*10/);
  assert.match(source, /quote\.units\s*>=\s*CONFIRM_UNITS\s*\*\s*quote\.count/);
  assert.match(source, /if\s+requires_confirmation\s+then/);
  assert.doesNotMatch(source, /if\s+total_units\s*>=\s*CONFIRM_UNITS\s+then/);
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
  assert.match(source, /local safe_pcall = pcall/);
  assert.doesNotMatch(source, /\bGLOBAL\b/);
  assert.match(source, /SpawnPrefab\("xd_lingshi1"\)/);
  assert.match(source, /old_ignorefull\s*=\s*inventory\.ignorefull/);
  assert.match(source, /inventory\.ignorefull\s*=\s*true/);
  assert.match(source, /safe_pcall\(inventory\.GiveItem,\s*inventory,\s*stone\)/);
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

test("integration registers a nine-slot container without discarding earlier mod wrappers", () => {
  const source = read("modmain.lua");
  assert.match(source, /local containers = require\("containers"\)/);
  assert.doesNotMatch(source, /GLOBAL\.require/);
  assert.match(source, /PrefabFiles\s*=\s*{\s*"nova_lingshi_recycler"\s*}/);
  assert.match(source, /containers_widgetsetup_base\s*=\s*containers\.widgetsetup/);
  assert.match(source, /containers_widgetsetup_base\(container,\s*prefab,\s*data/);
  assert.match(source, /for\s+y\s*=\s*2,\s*0,\s*-1\s+do/);
  assert.match(source, /containers\.MAXITEMSLOTS\s*=\s*math\.max/);
});

test("client UI exposes live refine, confirmation, withdrawal, balance, preview, and status", () => {
  const source = read("modmain.lua");
  assert.match(source, /AddClassPostConstruct\("widgets\/containerwidget"/);
  assert.match(source, /SendModRPCToServer\(_G\.MOD_RPC\[RPC_NAMESPACE\]\.Refine,\s*container\)/);
  assert.match(source, /SendModRPCToServer\(_G\.MOD_RPC\[RPC_NAMESPACE\]\.Withdraw,\s*container\)/);
  assert.match(source, /_nova_confirm:value\(\)/);
  assert.match(source, /_nova_balance:value\(\)/);
  assert.match(source, /_nova_preview:value\(\)/);
  assert.match(source, /_nova_status:value\(\)/);
  assert.match(source, /"Luyện hóa"/);
  assert.match(source, /"Xác nhận"/);
  assert.match(source, /"Rút"/);
});

test("RPC handlers validate prefab, range, open ownership, and inventory before mutation", () => {
  const source = read("modmain.lua");
  assert.match(source, /AddModRPCHandler\(RPC_NAMESPACE,\s*"Refine"/);
  assert.match(source, /AddModRPCHandler\(RPC_NAMESPACE,\s*"Withdraw"/);
  assert.match(source, /machine\.prefab\s*~=\s*"nova_lingshi_recycler"/);
  assert.match(source, /GetDistanceSqToInst\(machine\)\s*>\s*MAX_RPC_DISTANCE_SQ/);
  assert.match(source, /container:IsOpenedBy\(player\)/);
  assert.match(source, /player\.components\.inventory\s*==\s*nil/);
  assert.match(source, /machine:TryRefine\(player\)/);
  assert.match(source, /machine:TryWithdraw\(player\)/);
});

test("recipe uses the approved Alchemy Engine ingredients", () => {
  const source = read("modmain.lua");
  assert.match(source, /AddRecipe2\(\s*"nova_lingshi_recycler"/);
  assert.match(source, /_G\.Ingredient\("cutstone",\s*4\)/);
  assert.match(source, /_G\.Ingredient\("boards",\s*4\)/);
  assert.match(source, /_G\.Ingredient\("goldnugget",\s*2\)/);
  assert.match(source, /_G\.Ingredient\("gears",\s*1\)/);
  assert.match(source, /_G\.TECH\.SCIENCE_TWO/);
  assert.doesNotMatch(source, /(?:^|[^._A-Za-z])TECH\.SCIENCE_TWO/);
  assert.match(source, /"STRUCTURES"/);
  assert.match(source, /nova_lingshi_recycler_placer/);
});

test("README documents installation and manual acceptance checks", () => {
  const source = read("README.md");
  assert.match(source, /3721846643/);
  assert.match(source, /Luyện hóa/);
  assert.match(source, /Rút/);
  assert.match(source, /2 cỏ/i);
  assert.match(source, /túi đầy/i);
  assert.match(source, /lưu.*tải/i);
});

test("dedicated-server behavior harness covers transactions and persistence", () => {
  const source = read("tests/runtime_server_test.lua");
  assert.match(source, /two grass must equal one stone/);
  assert.match(source, /curated Tu Tien rare value must apply/);
  assert.match(source, /durability must be applied before stack multiplication/);
  assert.match(source, /profitable multi-output recipes must be rejected/);
  assert.match(source, /first high-value action must arm confirmation without consuming/);
  assert.match(source, /slot changes must invalidate a pending confirmation/);
  assert.match(source, /leave rejected slots untouched/);
  assert.match(source, /save\/load must preserve fractional credit/);
  assert.match(source, /full inventory must keep credit/);
  assert.match(source, /successful withdrawal must charge only delivered stones/);
  assert.match(source, /\[LTR TEST\] PASS/);
});

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) {
  process.exit(1);
}
