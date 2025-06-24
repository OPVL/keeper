import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class GitService {
  // Check if a directory is a valid Git repository
  static Future<bool> isValidGitRepository(String directoryPath) async {
    try {
      final gitDir = Directory(path.join(directoryPath, '.git'));
      final configFile = File(path.join(gitDir.path, 'config'));
      
      return await gitDir.exists() && await configFile.exists();
    } catch (e) {
      debugPrint('Error checking Git repository: $e');
      return false;
    }
  }
  
  // Update the Git config file with the new token
  static Future<bool> updateGitConfig(String directoryPath, String username, String token) async {
    try {
      final configPath = path.join(directoryPath, '.git', 'config');
      final configFile = File(configPath);
      
      if (!await configFile.exists()) {
        debugPrint('Git config file not found: $configPath');
        return false;
      }
      
      String content = await configFile.readAsString();
      debugPrint('Reading Git config: ${content.substring(0, min(100, content.length))}...');
      
      // Find the remote "origin" section with URL
      final RegExp remoteOriginRegex = RegExp(
        r'\[remote\s+"origin"\][\s\S]*?url\s*=\s*(https?:\/\/[^\s]+)',
        multiLine: true,
      );
      
      final match = remoteOriginRegex.firstMatch(content);
      
      if (match != null) {
        final currentUrl = match.group(1)!;
        debugPrint('Found URL: $currentUrl');
        
        // Extract the domain part without credentials
        final Uri uri = Uri.parse(currentUrl);
        final String domain = '${uri.host}${uri.path}';
        
        // Create new URL with credentials
        final newUrl = 'https://$username:$token@$domain';
        debugPrint('New URL: $newUrl');
        
        // Replace the URL in the config
        final updatedContent = content.replaceFirst(
          RegExp('url\\s*=\\s*$currentUrl'),
          'url = $newUrl'
        );
        
        await configFile.writeAsString(updatedContent);
        debugPrint('Git config updated successfully');
        return true;
      }
      
      debugPrint('Could not find remote "origin" section with URL in Git config');
      return false;
    } catch (e) {
      debugPrint('Error updating Git config: $e');
      return false;
    }
  }
  
  static int min(int a, int b) => a < b ? a : b;
}