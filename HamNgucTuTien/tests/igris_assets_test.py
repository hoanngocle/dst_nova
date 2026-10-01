"""Igris asset contract: independent skin with unchanged animation/texture data."""
from pathlib import Path
import hashlib
import re
import struct
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = "hn_igris_build"


class IgrisAssetsTest(unittest.TestCase):
    def test_unique_build_preserves_symbols_frames_and_texture(self):
        with zipfile.ZipFile(ROOT / "anim/igris_dungeon.zip") as archive:
            self.assertIsNone(archive.testzip())
            build = archive.read("build.bin")
            self.assertEqual(build[:4], b"BILD")
            size = struct.unpack_from("<I", build, 16)[0]
            self.assertEqual(build[20:20 + size].decode("utf-8"), BUILD)
            expected = {
                "header": "bd8a51e77bb31f941d2b6e6b8bf058de164b9780f31f300976fd4e59618f01a1",
                "symbols and frames": "72d41e2103fbf1e39f6e97ad99eac07d29a4d98da6eaecb7e731814c2fe342e3",
                "texture": "46e59265bb53f140a26c83330f81a77c4b92576a4a904a49675babec8a45d91a",
                "animation": "f18318ad26e02d5e98d62494140142d6bbb1f39741e63eec2ba92d38e2e0fb25",
            }
            parts = {"header": build[:16], "symbols and frames": build[20 + size:],
                     "texture": archive.read("atlas-0.tex"), "animation": archive.read("anim.bin")}
            for name, data in parts.items():
                self.assertEqual(hashlib.sha256(data).hexdigest(), expected[name], name)

    def test_boss_and_independent_corpse_use_the_custom_build(self):
        boss = (ROOT / "scripts/hn_dungeon/boss_defs.lua").read_text(encoding="utf-8")
        boss = boss.split('["hn_igris"] =', 1)[1]
        corpse = (ROOT / "scripts/prefabs/hn_corpses.lua").read_text(encoding="utf-8")
        self.assertIn('SetBuild("' + BUILD + '")', boss)
        self.assertRegex(corpse, r"corpse\('hn_corpse_igris','boarrior','" + BUILD + r"','death2'\)")
        for source in (boss, corpse):
            for asset in ("anim/igris_dungeon.zip", "anim/lavaarena_boarrior_basic.zip"):
                self.assertRegex(source, r"Asset\(['\"]ANIM['\"],\s*['\"]" + re.escape(asset) + r"['\"]\)")


if __name__ == "__main__":
    unittest.main()
