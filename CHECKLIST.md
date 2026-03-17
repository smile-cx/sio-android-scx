# Setup Checklist

Use this checklist to ensure your SCX Socket.IO Client build pipeline is properly configured.

## Initial Setup

- [ ] Repository created on GitHub
- [ ] Local clone exists
- [ ] Scripts are executable (`chmod +x scripts/*.sh gradlew`)

## Configuration

- [ ] Updated `gradle.properties` with correct versions
  - [ ] `VERSION_NAME` set (e.g., `2.1.0`)
  - [ ] `UPSTREAM_VERSION` matches Socket.IO version
  - [ ] Prefixes configured correctly

- [ ] Updated `README.md`
  - [ ] Replaced `smile-cx` with actual GitHub username
  - [ ] Updated JitPack URLs
  - [ ] Added badges (optional)

- [ ] Updated GitHub Actions workflows
  - [ ] `.github/workflows/build-release.yml`
  - [ ] `.github/workflows/test-build.yml`
  - [ ] Repository references correct

- [ ] Updated `scripts/download-prebuilt.sh`
  - [ ] Default repo set to your username

## Testing

- [ ] Local build successful
  ```bash
  ./scripts/build-release.sh
  ```

- [ ] AAR file generated
  - [ ] Location: `build/outputs/sio-android-scx-release.aar`
  - [ ] File exists and is valid ZIP

- [ ] Package prefixing verified
  ```bash
  unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
      jar tf - | grep "cx/smile" | wc -l
  ```
  - [ ] Shows prefixed classes (> 0)

- [ ] No unprefixed classes remain
  ```bash
  unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
      jar tf - | grep "^io/socket/" | wc -l
  ```
  - [ ] Returns 0 (no unprefixed classes)

- [ ] Native libraries verified (if applicable)
  ```bash
  unzip -l build/outputs/sio-android-scx-release.aar | grep ".so$"
  ```

## Git and GitHub

- [ ] Initial commit created
- [ ] Pushed to GitHub
  ```bash
  git push origin main
  ```

- [ ] First tag created
  ```bash
  git tag v2.1.0
  git push origin v2.1.0
  ```

- [ ] GitHub Actions enabled
  - [ ] Workflows visible in Actions tab
  - [ ] Build and Release workflow triggered

- [ ] Build workflow completed successfully
  - [ ] Green checkmark in Actions
  - [ ] No errors in logs

- [ ] GitHub Release created
  - [ ] Release visible in Releases page
  - [ ] AAR artifact attached
  - [ ] Checksum file attached

## JitPack

- [ ] JitPack URL tested
  - Visit: `https://jitpack.io/#smile-cx/sio-android-scx`
  - [ ] Repository found

- [ ] Version visible on JitPack
  - [ ] Tag appears in version list

- [ ] JitPack build triggered
  - [ ] Click "Get it" on your version
  - [ ] Build starts

- [ ] JitPack build successful
  - [ ] Green badge appears
  - [ ] Build log shows success

- [ ] Test dependency in sample app
  ```gradle
  implementation 'com.github.smile-cx:sio-android-scx:v2.1.0'
  ```

## Documentation

- [ ] README.md complete
  - [ ] Installation instructions
  - [ ] Usage examples
  - [ ] All links work

- [ ] BUILD_GUIDE.md reviewed
  - [ ] Accurate for your setup

- [ ] USAGE.md reviewed
  - [ ] API examples correct

- [ ] CI_CD.md reviewed
  - [ ] Pipeline description accurate

- [ ] LICENSE files present
  - [ ] LICENSE (your license)
  - [ ] UPSTREAM_LICENSE (Socket.IO license)

## Optional Enhancements

- [ ] Status badges added to README
  ```markdown
  [![](https://jitpack.io/v/smile-cx/sio-android-scx.svg)](https://jitpack.io/#smile-cx/sio-android-scx)
  [![Build](https://github.com/smile-cx/sio-android-scx/workflows/Build%20and%20Release/badge.svg)](https://github.com/smile-cx/sio-android-scx/actions)
  ```

- [ ] Branch protection rules configured
  - [ ] Require PR reviews for main
  - [ ] Require status checks to pass

- [ ] Security scanning enabled
  - [ ] Dependabot alerts
  - [ ] Code scanning

- [ ] Issue templates created
  - [ ] Bug report template
  - [ ] Feature request template

- [ ] Contributing guidelines added
  - [ ] CONTRIBUTING.md

- [ ] Code of conduct added
  - [ ] CODE_OF_CONDUCT.md

- [ ] Maven Central publishing configured (advanced)
  - [ ] GPG signing setup
  - [ ] OSSRH credentials
  - [ ] Publishing workflow

## Maintenance Tasks

- [ ] Subscribe to Socket.IO releases
  - Watch: https://github.com/socketio/socket.io-client-java

- [ ] Set up notification for GitHub Actions failures
  - [ ] Email notifications enabled

- [ ] Document custom patches (if any)
  - [ ] In `patches/` directory
  - [ ] Update `patches/README.md`

- [ ] Plan update schedule
  - [ ] How often to update upstream version?
  - [ ] Who is responsible?

## Pre-Release Checklist

Before creating each new release:

- [ ] Update `UPSTREAM_VERSION` in gradle.properties
- [ ] Update `VERSION_NAME` in gradle.properties
- [ ] Test build locally
- [ ] Verify all tests pass
- [ ] Update CHANGELOG (if you maintain one)
- [ ] Create and push tag
- [ ] Wait for CI to complete
- [ ] Verify GitHub Release
- [ ] Test JitPack build
- [ ] Update documentation if API changed

## Verification Commands

Copy and run these commands to verify everything:

```bash
# 1. Check build
./scripts/build-release.sh

# 2. Verify AAR exists
ls -lh build/outputs/sio-android-scx-release.aar

# 3. Check prefixed packages
unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
    jar tf - | grep "cx/smile" | head -20

# 4. Ensure no unprefixed classes
unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
    jar tf - | grep "^io/socket/" || echo "✓ Success: No unprefixed classes"

# 5. List AAR contents
unzip -l build/outputs/sio-android-scx-release.aar

# 6. Check native libraries (if any)
unzip -l build/outputs/sio-android-scx-release.aar | grep ".so$" || echo "No native libraries"

# 7. Verify checksum
cd build/outputs && sha256sum -c sio-android-scx-release.aar.sha256

# 8. Check Gradle configuration
./gradlew projects

# 9. Validate workflows
yamllint .github/workflows/*.yml || echo "yamllint not installed"

# 10. Check JitPack configuration
cat jitpack.yml
```

## Success Criteria

Your setup is complete when:

✅ Local build produces valid AAR
✅ All classes are prefixed (`cx.smile.*`)
✅ No unprefixed classes remain
✅ GitHub Actions builds successfully
✅ GitHub Release is created with AAR
✅ JitPack builds successfully
✅ Sample app can use the library via JitPack
✅ Documentation is accurate and complete

## Need Help?

If any checklist item fails:

1. Check the relevant documentation:
   - Build issues: [BUILD_GUIDE.md](BUILD_GUIDE.md)
   - CI/CD issues: [CI_CD.md](CI_CD.md)
   - Usage issues: [USAGE.md](USAGE.md)

2. Review the logs:
   - Local: Terminal output
   - CI: GitHub Actions logs
   - JitPack: Build log URL

3. Common fixes:
   - Clean build: `./gradlew clean && rm -rf upstream-source extracted`
   - Update dependencies: `./gradlew --refresh-dependencies`
   - Check versions: Ensure compatibility

4. Open an issue on GitHub if stuck

---

**All checked?** Congratulations! Your prefixed Socket.IO client is ready to use! 🎉
