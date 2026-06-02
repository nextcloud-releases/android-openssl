#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: Apache-2.0
#

import io
import json
import os
import subprocess
import zipfile

version     = os.environ["OPENSSL_VERSION"]
min_api     = int(os.environ["MIN_API"])
ndk_major   = int(os.environ["NDK_MAJOR"])
install_dir = os.environ["INSTALL_DIR"]
output_aar  = os.environ["OUTPUT_AAR"]
abis        = ["arm64-v8a", "x86_64"]

headers_root = os.path.join(install_dir, abis[0], "include", "openssl")

with zipfile.ZipFile(output_aar, "w", compression=zipfile.ZIP_DEFLATED) as z:

    # AndroidManifest.xml
    z.writestr("AndroidManifest.xml", (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    package="org.openssl.android">\n'
        '    <uses-sdk\n'
        '        android:minSdkVersion="' + str(min_api) + '"\n'
        '        android:targetSdkVersion="37" />\n'
        '</manifest>'
    ))

    # Empty classes.jar (required by AAR spec)
    jar_buf = io.BytesIO()
    with zipfile.ZipFile(jar_buf, "w"):
        pass
    z.writestr("classes.jar", jar_buf.getvalue())

    # Empty R.txt (required by AAR spec)
    z.writestr("R.txt", "")

    # jni/ – shared libraries for runtime loading
    for abi in abis:
        for lib in ("libcrypto.so", "libssl.so"):
            z.write(os.path.join(install_dir, abi, "lib", lib),
                    "jni/{}/{}".format(abi, lib))

    # prefab/prefab.json
    z.writestr("prefab/prefab.json", json.dumps({
        "schema_version": 2,
        "name": "openssl",
        "version": version,
        "dependencies": []
    }, indent=2))

    # prefab modules: crypto + ssl
    for module, lib_name, export_libs in [
        ("crypto", "libcrypto", []),
        ("ssl",    "libssl",    [":crypto"]),
    ]:
        z.writestr("prefab/modules/{}/module.json".format(module), json.dumps({
            "export_libraries": export_libs,
            "library_name": lib_name,
            "android": {}
        }, indent=2))

        # headers (architecture-independent)
        for fname in sorted(os.listdir(headers_root)):
            fpath = os.path.join(headers_root, fname)
            if os.path.isfile(fpath):
                z.write(fpath, "prefab/modules/{}/include/openssl/{}".format(module, fname))

        # per-ABI .so + abi.json
        for abi in abis:
            z.write(
                os.path.join(install_dir, abi, "lib", lib_name + ".so"),
                "prefab/modules/{}/libs/android.{}/{}.so".format(module, abi, lib_name)
            )
            z.writestr(
                "prefab/modules/{}/libs/android.{}/abi.json".format(module, abi),
                json.dumps({
                    "abi": abi,
                    "api": min_api,
                    "ndk": ndk_major,
                    "stl": "none",
                    "static": False
                }, indent=2)
            )

size = subprocess.check_output(["du", "-sh", output_aar]).decode().split()[0]
print("AAR: {} ({})".format(output_aar, size))
