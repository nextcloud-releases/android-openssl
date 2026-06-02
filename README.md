### 1. Configure the Repository

Add the JitPack repository to your root `settings.gradle` or `settings.gradle.kts` file under the `dependencyResolutionManagement` block.

#### `settings.gradle.kts`

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
}

```

#### `settings.gradle`

```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}

```

### 2. Add the Dependency

Choose the method that matches your project setup.

#### Version Catalog

Add the following configuration to your `gradle/libs.versions.toml` file:

```toml
[versions]
androidOpenssl = "3.5.6"

[libraries]
android-openssl = { module = "com.github.nextcloud-releases:android-openssl", version.ref = "androidOpenssl" }

```

Then, reference it in your app-level `build.gradle.kts`:

```kotlin
dependencies {
    implementation(libs.android.openssl)
}

```

#### `app/build.gradle.kts`

```kotlin
dependencies {
    implementation("com.github.nextcloud-releases:android-openssl:3.5.6")
}

```

#### `app/build.gradle`

```groovy
dependencies {
    implementation 'com.github.nextcloud-releases:android-openssl:3.5.6'
}

```

---

## Technical Specifications

### Minimum Requirements

* **Minimum API Level:** 28
* **Target NDK Version:** 29
* **Supported ABIs:** `arm64-v8a`, `x86_64`

### AAR Architecture & Contents

The package includes precompiled binaries alongside Prefab metadata to allow direct C/C++ linking in your CMake or ndk-build workflows.

| Artifact Path | Description |
| --- | --- |
| `jni/{abi}/libcrypto.so` | Compiled OpenSSL libcrypto binary |
| `jni/{abi}/libssl.so` | Compiled OpenSSL libssl binary |
| `prefab/modules/crypto/` | Prefab metadata and headers for native `crypto` linking |
| `prefab/modules/ssl/` | Prefab metadata and headers for native `ssl` linking |

---

## Compilation & Build Instructions

### On GitHub CI

1. Navigate to the **Actions** tab of the repository.
2. Select the **Build Android OpenSSL AAR** workflow.
3. Click the **Run workflow** dropdown menu.
4. Input your target OpenSSL version (e.g., `3.5.6`) and trigger the execution.

### Local Environment

Ensure your local machine has `curl`, `make`, and `python3` installed, and that your Android SDK/NDK path is exported.

```bash
# Execute the build script with the target version string
./build-android.sh 3.5.6

```
