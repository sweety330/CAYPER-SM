# Build CAYPER SM APK on GitHub

This repository includes `.github/workflows/android-apk.yml`.

1. Upload/push the project files to a GitHub repository, keeping the `.github/workflows` folder.
2. Push to `main` or `android`, or open **Actions** → **Build CAYPER SM Android APK** → **Run workflow**.
3. Wait for the workflow to finish successfully.
4. Open that workflow run and download **CAYPER-SM-Android-APK** from **Artifacts**.
5. Extract the downloaded artifact ZIP; it contains `CAYPER-SM.apk`.

The workflow uses Godot 4.3 and exports a debug-signed APK for testing/installing on Android. It is not a Play Store release-signed build. A successful workflow proves that export completed; test the APK on a real phone before sharing it.
