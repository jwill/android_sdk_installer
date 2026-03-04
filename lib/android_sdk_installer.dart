import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:interact/interact.dart';
import 'package:path/path.dart' as p;

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

  final url = 'https://developer.android.com/studio';
  print('Fetching $url...');

  try {
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
  } catch (e) {
    print('\nAn error occurred during installation: $e');
  }
}