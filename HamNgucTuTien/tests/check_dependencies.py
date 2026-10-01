from pathlib import Path
import re
import struct
import zipfile
root=Path(__file__).resolve().parents[1]
errors=[]
scripts=root/'scripts'
runtime=[p for p in root.rglob('*.lua') if 'tests' not in p.parts]
texts={p:p.read_text(encoding='utf-8-sig') for p in runtime}
# Prefab factories declare names in table keys or make(name,...), as well as Prefab(name,...).
prefabs=set()
for p,text in texts.items():
 if p.parent.name=='prefabs':
  prefabs.update(re.findall(r'(?:Prefab|make|corpse)\s*\(\s*["\x27](hn_[^"\x27]+)',text))
for name in ['boss_defs','extra_boss_defs','ice_defs']:
 text=(scripts/'hn_dungeon'/f'{name}.lua').read_text(encoding='utf-8-sig')
 prefabs.update(re.findall(r'["\x27](hn_[^"\x27]+)["\x27]\s*\]\s*=',text))
 prefabs.update(re.findall(r'\b(hn_\w+)\s*=definition',text))
for p,text in texts.items():
 for dep in re.findall(r'\brequire\s*\(?\s*["\x27]([^"\x27]+)',text):
  if dep.startswith(('hn_','brains/hn_','components/hn_','stategraphs/SGhn_')) and not (scripts/(dep+'.lua')).exists():
   errors.append(f'{p.name}: missing require {dep}')
  if dep.startswith(('utils/hh_','enums/hh_','brains/hh_')): errors.append(f'{p.name}: leaked Solo dependency {dep}')
 for dep in re.findall(r'SpawnPrefab\s*\(?\s*["\x27](hn_[^"\x27]+)',text):
  if dep not in prefabs: errors.append(f'{p.name}: missing prefab {dep}')
# Guardian constructs its FX ids as prefix + suffix. Audit that dynamic edge explicitly.
guardian=(scripts/'stategraphs/SGhn_minotau.lua').read_text(encoding='utf-8-sig')
for suffix in re.findall(r"fx\(inst,'([^']+)'",guardian):
 if 'hn_minotau_'+suffix not in prefabs: errors.append(f'Guardian: missing FX {suffix}')
for name in ['beetle_pig','dual_wield_pig','minotau']:
 if not (scripts/'stategraphs'/f'SGhn_{name}.lua').exists(): errors.append(f'missing SGhn_{name}')
builds=set()
for archive in (root/'anim').glob('*.zip'):
 with zipfile.ZipFile(archive) as z:
  if 'build.bin' not in z.namelist(): continue
  data=z.read('build.bin')
  assert data[:4]==b'BILD' and len(data)>=20, f'{archive.name}: invalid build header'
  length=struct.unpack_from('<I',data,16)[0]
  assert 0<length<=len(data)-20, f'{archive.name}: invalid build name length'
  builds.add(data[20:20+length].decode('utf-8'))
for p in root.rglob('*.lua'):
 if 'tests' in p.parts: continue
 text=p.read_text(encoding='utf-8-sig')
 for name in re.findall(r'SetStateGraph\s*(?:\(|)\s*[\"\x27](SG[^\"\x27]+)',text):
  if name.startswith(('SGhn_','SGhh_')) and not (root/'scripts/stategraphs'/f'{name}.lua').exists(): errors.append(f'{p.name}: missing stategraph {name}')
 for build in re.findall(r'SetBuild\s*\(\s*[\"\x27](hn_[^\"\x27]+)',text):
  if build not in builds: errors.append(f'{p.name}: missing namespaced animation build: {build}')
assert not errors, '\n'.join(errors)
print('PASS local require/prefab/stategraph closure, Guardian dynamic FX, and animation names')
