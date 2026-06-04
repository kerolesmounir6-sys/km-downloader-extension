"""Build and package Chrome/Edge Extension (MV3) as signed CRX.
Output ready for GitHub Pages / Cloudflare Pages.

Usage:
    python build_extension.py

Config:
    UPDATE_BASE_URL - change this to your GitHub Pages URL before uploading
"""

import hashlib
import io
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import cryptography
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

# ── CONFIG ──────────────────────────────────────────────────────
UPDATE_BASE_URL = "https://kerolesmounir6-sys.github.io/km-downloader-extension"
CRX_FILENAME = "km_extension.crx"
UPDATE_FILENAME = "update.xml"
EXTENSION_SRC = Path(__file__).parent / "chrome_extension"
OUT_DIR = Path(__file__).parent / "build"
PEM_PATH = Path.home() / ".km_downloader" / "keys" / "extension.pem"
# ────────────────────────────────────────────────────────────────


# ── Protobuf helpers (CRX v3 header) ────────────────────────────

def _varint(value):
    result = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            byte |= 0x80
        result.append(byte)
        if not value:
            break
    return bytes(result)


def _field(field_num, wire_type, payload):
    tag = (field_num << 3) | wire_type
    return _varint(tag) + payload


def _length_delimited(field_num, data):
    return _field(field_num, 2, _varint(len(data)) + data)


def _build_crx_header_rsa(public_key_der, signature):
    # AsymmetricKeyProof: field 1=public_key, field 2=signature
    proof = _length_delimited(1, public_key_der) + _length_delimited(2, signature)
    # CrxFileHeader: field 2=sha256_with_rsa (repeated)
    return _length_delimited(2, proof)


# ── Extension ID computation ────────────────────────────────────

def compute_extension_id(pem_path):
    with open(pem_path, "rb") as f:
        key = serialization.load_pem_private_key(f.read(), password=None)
    pub = key.public_key()
    der = pub.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    digest = hashlib.sha256(der).digest()[:16]
    hex_map = dict(zip("0123456789abcdef", "abcdefghijklmnop"))
    return "".join(hex_map[c] for c in digest.hex())


# ── PEM key generation ──────────────────────────────────────────

def ensure_pem_exists(pem_path):
    if pem_path.exists():
        return
    pem_path.parent.mkdir(parents=True, exist_ok=True)
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem_data = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    )
    pem_path.write_bytes(pem_data)
    print(f"  [CREATED] {pem_path}")


# ── Manifest helpers ────────────────────────────────────────────

REQUIRED_MANIFEST_KEYS = {"name", "version", "manifest_version", "description"}


def validate_manifest(ext_dir):
    mf_path = ext_dir / "manifest.json"
    if not mf_path.exists():
        print("ERROR: manifest.json not found")
        sys.exit(1)
    manifest = json.loads(mf_path.read_text(encoding="utf-8"))
    missing = REQUIRED_MANIFEST_KEYS - set(manifest.keys())
    if missing:
        print(f"ERROR: manifest.json missing keys: {', '.join(missing)}")
        sys.exit(1)
    if manifest.get("manifest_version") != 3:
        print(f"ERROR: manifest_version must be 3, got {manifest.get('manifest_version')}")
        sys.exit(1)
    if not re.match(r"^\d+(\.\d+)*$", manifest["version"]):
        print(f"ERROR: invalid version format: {manifest['version']}")
        sys.exit(1)
    return manifest


def bump_version(version):
    parts = version.split(".")
    parts[-1] = str(int(parts[-1]) + 1)
    return ".".join(parts)


def save_manifest(ext_dir, manifest):
    path = ext_dir / "manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


# ── CRX building ────────────────────────────────────────────────

def _try_chrome_pack(ext_dir, pem_path, output_path):
    candidates = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    ]
    chrome_exe = next((p for p in candidates if os.path.exists(p)), None)
    if not chrome_exe:
        return False
    try:
        result = subprocess.run(
            [chrome_exe, "--pack-extension=" + str(ext_dir), "--pack-extension-key=" + str(pem_path)],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            return False
        crx_src = ext_dir.with_suffix(".crx")
        if crx_src.exists():
            shutil.move(str(crx_src), str(output_path))
            return True
    except Exception:
        pass
    return False


def _create_zip(ext_dir):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(ext_dir.rglob("*")):
            if path.is_file():
                arcname = path.relative_to(ext_dir)
                zf.write(path, arcname)
    return buf.getvalue()


def _create_crx_python(zip_data, pem_path, output_path):
    with open(pem_path, "rb") as f:
        key = serialization.load_pem_private_key(f.read(), password=None)
    pub = key.public_key()
    pub_der = pub.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    signature = key.sign(zip_data, padding.PKCS1v15(), hashes.SHA256())
    header = _build_crx_header_rsa(pub_der, signature)
    with open(output_path, "wb") as f:
        f.write(b"Cr24")
        f.write(struct.pack("<I", 3))
        f.write(struct.pack("<I", len(header)))
        f.write(header)
        f.write(zip_data)


def build_crx(ext_dir, pem_path, output_path):
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if _try_chrome_pack(ext_dir, pem_path, output_path):
        print(f"  [PACKED] via Chrome ({output_path.name})")
        return
    zip_data = _create_zip(ext_dir)
    _create_crx_python(zip_data, pem_path, output_path)
    print(f"  [PACKED] via Python crypto ({output_path.name})")


# ── update.xml ──────────────────────────────────────────────────

def generate_update_xml(ext_id, version, output_path, codebase_url):
    output_path.parent.mkdir(parents=True, exist_ok=True)
    xml = (
        '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
        '<gupdate xmlns=\'http://www.google.com/update2/response\' protocol=\'2.0\'>\n'
        f'  <app appid=\'{ext_id}\'>\n'
        f'    <updatecheck codebase=\'{codebase_url}\' version=\'{version}\' />\n'
        '  </app>\n'
        '</gupdate>\n'
    )
    output_path.write_text(xml, encoding="utf-8")
    print(f"  [CREATED] {output_path.name}")


# ── Report ──────────────────────────────────────────────────────

def print_summary(report):
    print()
    print("=" * 55)
    print("  KM Extension Build Report")
    print("=" * 55)
    print(f"  Extension ID:  {report['extension_id']}")
    print(f"  Version:       {report['version']}")
    print(f"  CRX:           {report['crx_path']}")
    print(f"  Update URL:    {report['update_url']}")
    print(f"  Build time:    {report['build_time']}")
    print("=" * 55)
    print()
    print("  NEXT STEPS:")
    print("  1. Upload these 2 files to your GitHub Pages repo:")
    print(f"     - {report['crx_path']}")
    print(f"     - {os.path.join(os.path.dirname(report['crx_path']), UPDATE_FILENAME)}")
    print("  2. Set UPDATE_BASE_URL in build_extension.py to the real URL")
    print("  3. Run again to regenerate with the correct URL")
    print()


# ── Main ────────────────────────────────────────────────────────

def main():
    print("=" * 50)
    print("  KM Extension Builder")
    print("=" * 50)

    # 1. Validate manifest.json
    print("\n[1/6] Validating manifest.json...")
    manifest = validate_manifest(EXTENSION_SRC)
    print(f"  [OK] {EXTENSION_SRC / 'manifest.json'}")

    # 2. Ensure PEM key exists
    print("\n[2/6] Loading/creating PEM key...")
    ensure_pem_exists(PEM_PATH)
    print(f"  [USING] {PEM_PATH}")

    # 3. Compute Extension ID
    print("\n[3/6] Computing Extension ID...")
    ext_id = compute_extension_id(PEM_PATH)
    print(f"  Extension ID: {ext_id}")

    # 4. Auto-increment version
    print("\n[4/6] Bumping version...")
    old_ver = manifest["version"]
    new_ver = bump_version(old_ver)
    manifest["version"] = new_ver
    manifest["version_name"] = new_ver
    save_manifest(EXTENSION_SRC, manifest)
    print(f"  {old_ver} -> {new_ver}")

    # 5. Build CRX (Python method — full control)
    print("\n[5/6] Building CRX...")
    crx_path = OUT_DIR / CRX_FILENAME
    zip_data = _create_zip(EXTENSION_SRC)
    _create_crx_python(zip_data, PEM_PATH, crx_path)
    print(f"  [PACKED] {crx_path.name}")

    # 6. Generate update.xml + copy PEM + report
    print("\n[6/6] Generating update.xml and report...")
    codebase_url = f"{UPDATE_BASE_URL}/{CRX_FILENAME}"
    update_path = OUT_DIR / UPDATE_FILENAME
    generate_update_xml(ext_id, new_ver, update_path, codebase_url)

    # Copy index.html into build/ for GitHub Pages
    src_index = Path(__file__).parent / "index.html"
    if src_index.exists():
        shutil.copy2(src_index, OUT_DIR / "index.html")
        print(f"  [COPIED] index.html")

    out_pem = OUT_DIR / "extension.pem"
    shutil.copy2(PEM_PATH, out_pem)
    print(f"  [COPIED] extension.pem")

    report = {
        "extension_id": ext_id,
        "version": new_ver,
        "crx_path": str(crx_path.resolve()),
        "update_url": f"{UPDATE_BASE_URL}/{UPDATE_FILENAME}",
        "build_time": datetime.now(timezone.utc).isoformat(),
    }
    report_path = OUT_DIR / "build_report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"  [CREATED] build_report.json")

    print_summary(report)


if __name__ == "__main__":
    main()
