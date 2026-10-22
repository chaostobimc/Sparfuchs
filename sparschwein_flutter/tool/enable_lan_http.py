#!/usr/bin/env python3
"""Allow HTTP only for the app's configured private-LAN sync endpoint."""

from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

manifest_path = Path("android/app/src/main/AndroidManifest.xml")
if not manifest_path.exists():
    sys.exit("Android runner not found. Run flutter create for Android first.")

source = manifest_path.read_text(encoding="utf-8")
attribute = re.compile(r'\bandroid:usesCleartextTraffic\s*=\s*"[^"]*"')
if attribute.search(source):
    updated = attribute.sub('android:usesCleartextTraffic="true"', source, count=1)
else:
    updated, replacements = re.subn(
        r"<application(?=\s|>)",
        '<application android:usesCleartextTraffic="true"',
        source,
        count=1,
    )
    if replacements != 1:
        sys.exit("The Android manifest has no <application> element.")

ET.fromstring(updated)
manifest_path.write_text(updated, encoding="utf-8")
print(f"Enabled LAN HTTP for {manifest_path}")
