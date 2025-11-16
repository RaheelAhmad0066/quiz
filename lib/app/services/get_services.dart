import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class GetServicekey {
  Future<String> getServiceKeyToken() async {
    final scope = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];
    try {
      Map<String, dynamic> credentials;
      
      // Try multiple locations for service account key
      final currentDir = Directory.current;
      final appDocDir = await getApplicationDocumentsDirectory();
      
      // Find project root by looking for pubspec.yaml
      String? projectRoot;
      Directory? checkDir = currentDir;
      for (int i = 0; i < 5; i++) {
        final pubspecFile = File('${checkDir!.path}/pubspec.yaml');
        if (await pubspecFile.exists()) {
          projectRoot = checkDir.path;
          break;
        }
        checkDir = checkDir.parent;
        if (checkDir.path == checkDir.parent.path) break; // Reached root
      }
      
      List<String> possiblePaths = [
        // 1. Project root (if found)
        if (projectRoot != null) '$projectRoot/service_account_key.json',
        // 2. Assets directory in project root
        if (projectRoot != null) '$projectRoot/assets/service_account_key.json',
        // 3. Current directory
        '${currentDir.path}/service_account_key.json',
        // 4. Assets in current directory
        '${currentDir.path}/assets/service_account_key.json',
        // 5. Parent directory (if current is build dir)
        '${currentDir.path}/../service_account_key.json',
        // 6. Assets in parent directory
        '${currentDir.path}/../assets/service_account_key.json',
        // 7. Two levels up (if in build/app)
        '${currentDir.path}/../../service_account_key.json',
        // 8. Assets two levels up
        '${currentDir.path}/../../assets/service_account_key.json',
        // 9. App documents directory
        '${appDocDir.path}/service_account_key.json',
      ];
      
      // Remove duplicates
      possiblePaths = possiblePaths.toSet().toList();
      
      File? foundFile;
      for (var path in possiblePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            foundFile = file;
            print('✅ Found service account key at: $path');
            break;
          }
        } catch (e) {
          // Continue to next path
        }
      }
      
      // If not found in files, try from assets
      if (foundFile == null) {
        try {
          final contents = await rootBundle.loadString('assets/service_account_key.json');
          credentials = jsonDecode(contents) as Map<String, dynamic>;
          print('✅ Loaded service account key from assets');
        } catch (e) {
          print('⚠️ Service account key not found in assets: $e');
          throw Exception('Service account key file not found in any location.');
        }
      } else {
        final contents = await foundFile.readAsString();
        credentials = jsonDecode(contents) as Map<String, dynamic>;
      }
      
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(credentials),
        scope,
      );
      final accessServerKey = client.credentials.accessToken.data;
      print('✅ Successfully retrieved access token');
      return accessServerKey;
    } catch (e) {
      print('❌ Error retrieving access token: $e');
      return '';
    }
  }
}
