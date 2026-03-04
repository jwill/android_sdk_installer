import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:interact/interact.dart';
import 'package:path/path.dart' as p;

/// Preferred Java version (major version number followed by a dot).
const String JAVA_VERSION_PREFERENCE = '11.';

/// Android SDK component versions
const String ANDROID_NDK_VERSION = '28.2.13676358';
const String ANDROID_API_LEVEL = '36';
const String ANDROID_BUILD_TOOLS_VERSION = '36.0.0';
const String ANDROID_CMAKE_VERSION = '4.1.2';
const String ANDROID_SYSTEM_IMAGE = 'system-images;android-$ANDROID_API_LEVEL;google_apis;arm64-v8a';

/// Script to install Android SDK components.
void main() async {
  String os = Platform.operatingSystem;
  String platformKey;
  String sdkRoot;

  if (Platform.isMacOS) {
    platformKey = 'mac';
    sdkRoot = p.join(Platform.environment['HOME']!, 'Library', 'Android', 'Sdk');
  } else if (Platform.isLinux) {
    platformKey = 'linux';
    sdkRoot = p.join(Platform.environment['HOME']!, 'Android', 'Sdk');
  } else if (Platform.isWindows) {
    platformKey = 'win';
    final localAppData = Platform.environment['LOCALAPPDATA'];
    sdkRoot = localAppData != null 
        ? p.join(localAppData, 'Android', 'Sdk')
        : 'C:\\Android\\Sdk';
  } else {
    print('Unsupported operating system: $os');
    return;
  }

  print('Current OS: $os (Platform key: $platformKey)');
  print('Target SDK Root: $sdkRoot');

  try {
    await installAndroidSdk(platformKey, sdkRoot);
    await installAndroidComponents(sdkRoot);
    await installJava();
  } catch (e) {
    print('\nAn error occurred during installation: $e');
  }
}

/// Fetches, downloads, and extracts the Android Command Line Tools.
Future<void> installAndroidSdk(String platformKey, String sdkRoot) async {
  final wantAndroid = Confirm(prompt: 'Do you want to install the Android Command Line Tools?').interact();
  if (!wantAndroid) return;

  final url = 'https://developer.android.com/studio';
  print('Fetching $url...');

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('Failed to load page: ${response.statusCode}');
    return;
  }

  final document = parser.parse(response.body);
  final links = document.querySelectorAll('a');
  
  String? downloadUrl;
  final pattern = RegExp('commandlinetools-$platformKey-.*_latest\\.zip');

  for (var link in links) {
    final href = link.attributes['href'];
    if (href != null && pattern.hasMatch(href)) {
      downloadUrl = href;
      break;
    }
  }

  if (downloadUrl == null) {
    print('Could not find command line tools URL for $platformKey');
    return;
  }

  print('Located command line tools URL: $downloadUrl');

  final sdkRootInput = Input(
    prompt: 'Enter the Android SDK root directory',
    defaultValue: sdkRoot,
  ).interact();
  sdkRoot = sdkRootInput;

  final fileName = p.basename(downloadUrl);
  final tempDir = Directory.systemTemp.createTempSync('android_sdk_installer');
  final zipFile = File(p.join(tempDir.path, fileName));

  print('Downloading $fileName...');
  final downloadResponse = await http.get(Uri.parse(downloadUrl));
  if (downloadResponse.statusCode != 200) {
    print('Failed to download file: ${downloadResponse.statusCode}');
    return;
  }
  await zipFile.writeAsBytes(downloadResponse.bodyBytes);
  print('Download complete.');

  // We want to extract into $sdkRoot/cmdline-tools/latest
  final targetPath = p.join(sdkRoot, 'cmdline-tools', 'latest');
  print('Extracting to $targetPath...');

  if (Directory(targetPath).existsSync()) {
    print('Cleaning up existing target path: $targetPath');
    Directory(targetPath).deleteSync(recursive: true);
  }
  Directory(targetPath).createSync(recursive: true);

  final archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());

  for (final file in archive) {
    final String filename = file.name;
    
    // The zip usually has a 'cmdline-tools/' root folder.
    // We want to strip that and put everything in $targetPath.
    String relativePath = filename;
    if (filename.startsWith('cmdline-tools/')) {
      relativePath = filename.substring('cmdline-tools/'.length);
    }
    
    if (relativePath.isEmpty) continue;

    final fullPath = p.join(targetPath, relativePath);
    
    if (file.isFile) {
      final outFile = File(fullPath);
      // Explicitly create parent directories
      outFile.parent.createSync(recursive: true);
      
      // Use writeAsBytesSync for simplicity if files are small,
      // or a stream for larger ones.
      final data = file.content as List<int>;
      outFile.writeAsBytesSync(data);
      print('  Extracting file: $relativePath');
    } else {
      Directory(fullPath).createSync(recursive: true);
      print('  Creating directory: $relativePath');
    }
  }
  print('Extraction complete.');

  // Cleanup
  tempDir.deleteSync(recursive: true);
  print('Temporary files cleaned up.');

  print('\nAndroid Command Line Tools successfully installed to $targetPath');
  print('Remember to add the following to your shell profile:');
  print('export PATH="$targetPath/bin:\$PATH"');

  await addToPath(targetPath);
}

/// Installs Android SDK components using sdkmanager.
Future<void> installAndroidComponents(String sdkRoot) async {
  final confirm = Confirm(prompt: 'Do you want to install Android SDK components (NDK, Build Tools, etc.)?').interact();
  if (!confirm) return;

  final sdkManagerPath = p.join(sdkRoot, 'cmdline-tools', 'latest', 'bin', 'sdkmanager');
  if (!File(sdkManagerPath).existsSync()) {
    print('Error: sdkmanager not found at $sdkManagerPath');
    return;
  }

  print('\nAccepting Android SDK licenses...');
  // Running yes | sdkmanager --licenses --sdk_root=$sdkRoot
  final licenseProcess = await Process.start('bash', ['-c', 'yes | "$sdkManagerPath" --licenses --sdk_root="$sdkRoot"']);
  await stdout.addStream(licenseProcess.stdout);
  await stderr.addStream(licenseProcess.stderr);
  await licenseProcess.exitCode;

  print('\nInstalling components:');
  print(' - NDK: $ANDROID_NDK_VERSION');
  print(' - Build Tools: $ANDROID_BUILD_TOOLS_VERSION');
  print(' - API: $ANDROID_API_LEVEL');
  print(' - System Image: $ANDROID_SYSTEM_IMAGE');
  print(' - Cmake: $ANDROID_CMAKE_VERSION');
  print(' - Platform Tools, Emulator');

  final components = [
    'ndk;$ANDROID_NDK_VERSION',
    'build-tools;$ANDROID_BUILD_TOOLS_VERSION',
    'platforms;android-$ANDROID_API_LEVEL',
    ANDROID_SYSTEM_IMAGE,
    'platform-tools',
    'emulator',
    'cmake;$ANDROID_CMAKE_VERSION',
  ];

  final installProcess = await Process.start(sdkManagerPath, [
    '--install',
    '--sdk_root=$sdkRoot',
    ...components,
  ]);

  await stdout.addStream(installProcess.stdout);
  await stderr.addStream(installProcess.stderr);

  final exitCode = await installProcess.exitCode;
  if (exitCode == 0) {
    print('\nAndroid components installed successfully.');
  } else {
    print('\nFailed to install Android components (exit code: $exitCode).');
  }
}

/// Installs Java using SDKMAN if requested.
Future<void> installJava() async {
  final wantJava = Confirm(prompt: 'Do you want to install Java?').interact();
  if (!wantJava) return;

  final home = Platform.environment['HOME']!;
  final sdkmanDir = p.join(home, '.sdkman');
  final sdkmanInit = p.join(sdkmanDir, 'bin', 'sdkman-init.sh');
  bool sdkmanExists = File(sdkmanInit).existsSync();

  if (!sdkmanExists) {
    print('SDKMAN not found. Installing SDKMAN...');
    // curl -s "https://get.sdkman.io" | bash
    final installProcess = await Process.start('bash', ['-c', 'curl -s "https://get.sdkman.io" | bash']);
    stdout.addStream(installProcess.stdout);
    stderr.addStream(installProcess.stderr);
    
    final exitCode = await installProcess.exitCode;
    if (exitCode != 0) {
      print('Failed to install SDKMAN.');
      return;
    }
    print('SDKMAN installed successfully.');
    sdkmanExists = true;
  }

  print('Querying available Java versions from SDKMAN...');
  final listResult = await Process.run('bash', [
    '-c',
    'source $sdkmanInit && sdk ls java'
  ]);

  if (listResult.exitCode != 0) {
    print('Failed to list Java versions: ${listResult.stderr}');
    return;
  }

  final output = listResult.stdout as String;
  final lines = output.split('\n');
  final amznVersions = <String>[];

  // Parse identifiers ending in amzn
  for (var line in lines) {
    if (line.contains('amzn') && line.contains('|')) {
      final parts = line.split('|').map((e) => e.trim()).toList();
      if (parts.length >= 6) {
        final identifier = parts[5]; // The Identifier column
        if (identifier.endsWith('amzn')) {
          amznVersions.add(identifier);
        }
      }
    }
  }

  if (amznVersions.isEmpty) {
    print('Could not find any Amazon Corretto Java versions in SDKMAN output.');
    return;
  }

  amznVersions.sort((a, b) => b.compareTo(a));

  final displayVersion = JAVA_VERSION_PREFERENCE.replaceAll('.', '');
  print('\nRecommendation: Java $displayVersion (e.g., ${JAVA_VERSION_PREFERENCE}x.x-amzn)');
  
  // Find the preferred Java version to recommend
  final preferredIndex = amznVersions.indexWhere((v) => v.startsWith(JAVA_VERSION_PREFERENCE));
  
  final selectionIndex = Select(
    prompt: 'Which version of Java would you like to install?',
    options: amznVersions,
    initialIndex: preferredIndex != -1 ? preferredIndex : 0,
  ).interact();

  final selectedVersion = amznVersions[selectionIndex];
  print('Installing Java $selectedVersion...');

  final installProcess = await Process.start('bash', [
    '-c',
    'source $sdkmanInit && sdk i java $selectedVersion'
  ]);

  stdout.addStream(installProcess.stdout);
  stderr.addStream(installProcess.stderr);

  final exitCode = await installProcess.exitCode;
  if (exitCode == 0) {
    print('\nJava $selectedVersion installed successfully via SDKMAN.');
  } else {
    print('\nFailed to install Java $selectedVersion.');
  }
}

/// Adds the SDK bin directory to the system PATH.
Future<void> addToPath(String targetPath) async {
  if (Platform.isWindows) {
    print('\nAutomatic PATH configuration is not yet supported on Windows.');
    print('Please add "$targetPath/bin" to your Environment Variables manually.');
    return;
  }

  final confirm = Confirm(prompt: 'Do you want to add the Android SDK to your PATH?').interact();
  if (!confirm) return;

  final home = Platform.environment['HOME'];
  if (home == null) {
    print('Could not find HOME environment variable.');
    return;
  }

  // Identify shell profile
  final shell = Platform.environment['SHELL'] ?? '';
  String profileName;
  if (shell.contains('zsh')) {
    profileName = '.zshrc';
  } else if (Platform.isMacOS) {
    profileName = '.bash_profile';
  } else {
    profileName = '.bashrc';
  }

  final profilePath = p.join(home, profileName);
  final exportCmd = '''

# Android SDK Command Line Tools
export PATH="$targetPath/bin:\$PATH"
''';

  try {
    final profileFile = File(profilePath);
    if (!profileFile.existsSync()) {
      print('Creating new profile: $profilePath');
      profileFile.createSync();
    }

    final content = profileFile.readAsStringSync();
    if (content.contains(targetPath)) {
      print('Path already exists in $profileName.');
    } else {
      profileFile.writeAsStringSync(exportCmd, mode: FileMode.append);
      print('Successfully added to $profilePath. Please restart your terminal or run:');
      print('source ~/$profileName');
    }
  } catch (e) {
    print('Failed to update $profileName: $e');
  }
}