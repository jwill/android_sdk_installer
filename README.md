# Android SDK Installer

A command-line tool to automate the setup of Android Command Line Tools. This script fetches the latest tools from the official Android Developers site, handles downloading, and extracts them to the appropriate platform-specific directory.

## Features

- **Automated Discovery**: Scrapes the latest Command Line Tools URL for your platform.
- **Platform Support**: Works on macOS, Linux, and Windows.
- **Smart Extraction**: Automatically nests files in `cmdline-tools/latest` for compatibility with `sdkmanager`.
- **Interactive**: Prompts for confirmation of the installation directory and optional Java installation.
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
