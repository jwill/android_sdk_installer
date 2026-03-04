# Android SDK Installer

A command-line tool to automate the setup of Android Command Line Tools. This script fetches the latest tools from the official Android Developers site, handles downloading, and extracts them to the appropriate platform-specific directory.

## Features

- **Automated Discovery**: Scrapes the latest Command Line Tools URL for your platform.
- **Component Setup**: Automatically installs NDK (28.2.x), Build Tools (36.0.0), Platforms (Android 36), System Images, and more via `sdkmanager`.
- **Platform Support**: Optimized for **macOS** and **Linux**. While it recognizes Windows, many features currently rely on `bash` (e.g., license acceptance, SDKMAN, AVD creation), so Windows support is limited unless a Unix-like environment is available.
- **Smart Extraction**: Automatically nests files in `cmdline-tools/latest` for compatibility with `sdkmanager`.
- **Dynamic Architecture Detection**: Automatically detects CPU architecture (`arm64-v8a` for M-series/ARM or `x86_64` for Intel/AMD) to ensure the correct Android system image is installed.
- **Auto-Executable Tooling**: Automatically checks and sets the executable bit for `sdkmanager` on macOS and Linux, ensuring smooth installation even if permissions are missing.
- **Play Store Images**: Specifically targets `google_apis_playstore` variants for better application testing support.
- **Interactive**: Prompts for confirmation of Android SDK installation, target directory, optional Java setup, automatic PATH configuration, AVD creation, and **Flutter integration**.
- **Flutter Support**: Automatically informs Flutter of the new Android SDK location using `flutter config --android-sdk` and runs `flutter doctor` for status verification.
- **AVD Management**: Automatically creates an Android Virtual Device (AVD) with the latest system image and enables the hardware keyboard for better usability.
- **Java Management**: Integrated SDKMAN support for installing Amazon Corretto Java versions (Java 11 recommended).

## Getting started

Ensure you have Dart or Flutter installed on your system.

## Usage

1. Clone the repository.
2. Run `dart pub get` to install dependencies.
3. Execute the installer script:

```bash
dart run lib/android_sdk_installer.dart
```

4. Follow the interactive prompts to confirm your Android SDK root directory.

## Post-Installation

After the script finishes, add the binary path to your shell configuration (e.g., `.zshrc` or `.bashrc`):

```bash
# Example for macOS/Linux
export PATH="$HOME/Library/Android/Sdk/cmdline-tools/latest/bin:$PATH"
```

## Additional information

This tool is designed to simplify the initial setup of Android SDKs for developers using Flutter or pure Android development.
