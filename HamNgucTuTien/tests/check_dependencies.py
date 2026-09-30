from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
errors=[]
for p in root.rglob('*.lua'):
 if 'tests' in p.parts: continue
 text=p.read_text(encoding='utf-8-sig')
 for name in re.findall(r'SetStateGraph\s*(?:\(|)\s*[\"\x27](SG[^\"\x27]+)',text):
  if name.startswith(('SGhn_','SGhh_')) and not (root/'scripts/stategraphs'/f'{name}.lua').exists(): errors.append(f'{p.name}: missing stategraph {name}')
 for build in re.findall(r'SetBuild\s*\(\s*[\"\x27](hn_[^\"\x27]+)',text): errors.append(f'{p.name}: namespaced animation build needs asset verification: {build}')
assert not errors, '\n'.join(errors)
print('PASS local stategraph closure and animation names')
