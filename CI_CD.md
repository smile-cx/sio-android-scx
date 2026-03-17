# CI/CD Pipeline Documentation

This document explains the continuous integration and deployment pipeline for the prefixed Socket.IO client.

## Pipeline Overview

```
┌──────────────┐
│ Push/PR      │
│ to main      │
└──────┬───────┘
       │
       ├─────────────────────────────────┐
       │                                 │
       ▼                                 ▼
┌─────────────────┐            ┌────────────────┐
│ Test Build      │            │ Security Scan  │
│ Workflow        │            │ (Optional)     │
└─────────────────┘            └────────────────┘


┌──────────────┐
│ Push Tag     │
│ v*           │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ Build and Release Workflow                  │
├─────────────────────────────────────────────┤
│ 1. Checkout                                  │
│ 2. Setup JDK & Android SDK                   │
│ 3. Download & Patch Upstream                 │
│ 4. Build Prefixed AAR                        │
│ 5. Verify Prefixing                          │
│ 6. Create GitHub Release                     │
│ 7. Upload AAR Artifact                       │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ GitHub Release Created                       │
│ - Tag: v{version}                            │
│ - Asset: sio-android-scx-release.aar         │
│ - Checksum: *.sha256                         │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ JitPack Build (on first request)            │
├─────────────────────────────────────────────┤
│ 1. Clone repository at tag                  │
│ 2. Download prebuilt AAR from Release       │
│ 3. Extract JAR & native libraries            │
│ 4. Run Shadow plugin (package relocation)   │
│ 5. Reassemble final AAR                      │
│ 6. Publish to JitPack Maven                  │
└─────────────────────────────────────────────┘
```

## Workflows

### 1. Test Build Workflow (`.github/workflows/test-build.yml`)

**Trigger**: Push or PR to `main` or `develop` branches

**Purpose**: Validate that the build process works correctly

**Steps**:
1. Checkout code
2. Setup JDK 11 and Android SDK
3. Cache Gradle packages and upstream source
4. Run full build from source
5. Verify package prefixing
6. Upload build artifacts (7-day retention)

**Outputs**: Test build AAR (artifact)

**Duration**: ~30-45 minutes (includes upstream compilation)

### 2. Build and Release Workflow (`.github/workflows/build-release.yml`)

**Trigger**:
- Push tag matching `v*` pattern
- Manual workflow dispatch with version input

**Purpose**: Build production AAR and create GitHub Release

**Steps**:
1. **Checkout**: Clone repository
2. **Setup**: Install JDK 11, Android SDK
3. **Cache**: Restore Gradle and upstream source caches
4. **Build**: Execute `scripts/build-release.sh`
   - Download upstream Socket.IO source
   - Apply native prefixing patches
   - Build upstream AAR
   - Extract JAR and native libraries
   - Run Shadow plugin for Java relocation
   - Reassemble final AAR
5. **Verify**: Check AAR contents
   - Verify prefixed packages (`cx.smile.*`)
   - Verify no unprefixed classes remain
   - List native libraries (if any)
6. **Release**: Create GitHub Release
   - Extract version from tag
   - Generate release notes
   - Create release on GitHub
7. **Upload**: Attach artifacts to release
   - `sio-android-scx-release.aar`
   - `sio-android-scx-release.aar.sha256`

**Outputs**:
- GitHub Release with AAR
- Build artifacts (30-day retention)

**Duration**: ~45-60 minutes

### 3. JitPack Build (configured via `jitpack.yml`)

**Trigger**: First request for a specific version via JitPack

**Purpose**: Fast AAR assembly for Maven distribution

**Strategy**:
- Download prebuilt AAR from GitHub Releases
- Skip native compilation (already done in CI)
- Only run Shadow + reassembly (~5 minutes)

**Fallback**: If prebuilt not found, build from source

**Steps**:
1. `before_install`: Download prebuilt AAR
2. `install`: Run Shadow plugin and reassemble
3. JitPack publishes to Maven repository

**Duration**: ~5 minutes (with prebuilt) or ~45 minutes (from source)

## Caching Strategy

### Gradle Cache
```yaml
~/.gradle/caches
~/.gradle/wrapper
```
**Key**: Hash of `*.gradle*` and `gradle-wrapper.properties`

**Purpose**: Avoid re-downloading dependencies

### Upstream Source Cache
```yaml
upstream-source/
```
**Key**: Upstream version number

**Purpose**: Avoid re-cloning Socket.IO repository

## Environment Variables

### Build Configuration
- `UPSTREAM_VERSION`: Socket.IO version to build (default: `2.1.0`)
- `WORKSPACE`: Build workspace directory
- `GRADLE_OPTS`: JVM options for Gradle

### GitHub Actions Secrets
- `GITHUB_TOKEN`: Automatically provided by GitHub for releases

## Release Process

### Automatic Release (Recommended)

1. **Update version** in `gradle.properties`:
   ```properties
   VERSION_NAME=2.1.0
   ```

2. **Commit changes**:
   ```bash
   git add gradle.properties
   git commit -m "Bump version to 2.1.0"
   git push
   ```

3. **Create and push tag**:
   ```bash
   git tag v2.1.0
   git push origin v2.1.0
   ```

4. **Wait for CI**: GitHub Actions builds and creates release automatically

5. **Verify release**: Check [Releases](../../releases) page

### Manual Release

Trigger workflow manually:

1. Go to **Actions** → **Build and Release**
2. Click **Run workflow**
3. Enter version (e.g., `2.1.0`)
4. Click **Run workflow**

## Verification

### Post-Build Checks

After each build, the workflow verifies:

1. **Package Prefixing**:
   ```bash
   unzip -p sio-android-scx-release.aar classes.jar | jar tf - | grep "cx/smile"
   ```
   Should show classes under `cx.smile.io.socket.*`

2. **No Unprefixed Classes**:
   ```bash
   unzip -p sio-android-scx-release.aar classes.jar | jar tf - | grep "^io/socket"
   ```
   Should return empty (or error)

3. **Native Libraries**:
   ```bash
   unzip -l sio-android-scx-release.aar | grep ".so$"
   ```
   Should show `` files (if native code exists)

### Manual Verification

Download AAR and inspect:

```bash
# Download from release
wget https://github.com/smile-cx/sio-android-scx/releases/download/v2.1.0/sio-android-scx-release.aar

# Extract
unzip sio-android-scx-release.aar -d extracted/

# Check classes
jar tf extracted/classes.jar | grep "cx/smile"

# Check native libraries
ls extracted/jni/*/
```

## Troubleshooting

### Build Failures

**Symptom**: Build fails during upstream compilation

**Solutions**:
- Check upstream version exists
- Verify Android SDK version compatibility
- Review patch application logs

### Missing Artifacts

**Symptom**: AAR not uploaded to release

**Solutions**:
- Check `build/outputs/` directory in logs
- Verify `build-release.sh` completed successfully
- Check GitHub Actions permissions

### JitPack Failures

**Symptom**: JitPack build times out or fails

**Solutions**:
- Verify GitHub Release exists with AAR
- Check `jitpack.yml` configuration
- Review JitPack build logs at `https://jitpack.io/com/github/smile-cx/sio-android-scx/{version}/build.log`

### Cache Issues

**Symptom**: Build uses stale dependencies

**Solutions**:
- Clear GitHub Actions cache manually
- Update cache key in workflow
- Use `workflow_dispatch` with cache bypass

## Monitoring

### Build Status

Check workflow status:
- Repository → **Actions** tab
- Green checkmark = success
- Red X = failure
- Yellow circle = in progress

### Build Logs

View detailed logs:
1. Go to **Actions**
2. Click on workflow run
3. Click on job name
4. Expand step to see logs

### Release Status

Check releases:
- Repository → **Releases** tab
- Should show tag, AAR, and checksum

### JitPack Status

Check JitPack build:
- Visit: `https://jitpack.io/com/github/smile-cx/sio-android-scx/{version}/build.log`
- Green badge = success
- Red badge = failure

## Performance

### Build Times

| Stage | Duration | Cached |
|-------|----------|--------|
| Checkout & Setup | ~2 min | N/A |
| Upstream Build | ~30 min | ~5 min |
| Shadow Processing | ~3 min | ~1 min |
| AAR Assembly | ~2 min | ~1 min |
| **Total (fresh)** | **~40 min** | **~10 min** |

### Optimization Tips

1. **Use caching**: Enable for Gradle and upstream source
2. **Parallel builds**: Already configured in `gradle.properties`
3. **Prebuilt AAR**: JitPack downloads from releases (fast)
4. **Incremental builds**: Only recompile changed modules

## Security

### Supply Chain Security

- **Dependency verification**: Gradle verifies checksums
- **Source integrity**: Clone from official Socket.IO repository
- **Artifact signing**: Add GPG signing for production
- **Checksum verification**: SHA-256 checksums provided

### Access Control

- **Releases**: Only maintainers can create tags
- **Workflows**: Protected by GitHub Actions permissions
- **Secrets**: Use GitHub Secrets for sensitive data

## Maintenance

### Update Upstream Version

1. Update `gradle.properties`:
   ```properties
   UPSTREAM_VERSION=2.2.0
   ```

2. Test locally:
   ```bash
   ./scripts/build-release.sh
   ```

3. Create new release as described above

### Update Dependencies

1. Update plugin versions in `build.gradle.kts`
2. Test build locally
3. Update documentation
4. Create release

### Rotate Secrets

If credentials are compromised:
1. Update in **Settings** → **Secrets**
2. Re-run failed workflows
3. Review access logs

## Best Practices

1. **Always test locally** before creating tags
2. **Use semantic versioning**: `v{major}.{minor}.{patch}` (match upstream Socket.IO version)
3. **Keep upstream version** in sync with tag
4. **Document breaking changes** in release notes
5. **Archive old releases** after 1 year
6. **Monitor build times** and optimize caching
7. **Review security alerts** from GitHub
