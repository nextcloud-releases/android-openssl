## Usage in Android projects

`settings.gradle`:
```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

`app/build.gradle`:
```groovy
dependencies {
    implementation 'com.github.nextcloud-deps:nextcloud-openssl:openssl-3.5.6'
}
```

Replace `openssl-3.5.6` with the desired [release tag](https://github.com/nextcloud-deps/nextcloud-openssl/releases).

---

## AAR contents

| | |
|---|---|
| `jni/{abi}/libcrypto.so` | OpenSSL libcrypto |
| `jni/{abi}/libssl.so` | OpenSSL libssl |
| `prefab/modules/crypto/` | Prefab metadata + headers for NDK linking |
| `prefab/modules/ssl/` | Prefab metadata + headers for NDK linking |

ABIs: **arm64-v8a**, **x86_64** · Min API: **28** · NDK: **29**

---

## Building the AAR

### On GitHub CI (recommended)

- Go to **Actions → Build Android OpenSSL AAR**
- Click **Run workflow**
- Enter the OpenSSL version (e.g. `3.5.6`) and confirm
- The resulting AAR is attached to the workflow run and published as a GitHub Release on tagged pushes

### Locally

Prerequisites: Android SDK with NDK `29.0.14206865` (auto-installed if `sdkmanager` is in PATH), `curl`, `make`, `python3`.

```bash
./build-android.sh 3.5.6
```

The AAR is written to `openssl-3.5.6.aar`.

---

## License

- **Build scripts in this repo:** [Apache-2.0](LICENSE)
- **OpenSSL** (compiled binaries): [Apache-2.0](https://github.com/openssl/openssl/blob/master/LICENSE.txt)
