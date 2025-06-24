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
      // Check if directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: $directoryPath');
        return false;
      }
      
      final configPath = path.join(directoryPath, '.git', 'config');
      final configFile = File(configPath);
      
      if (!await configFile.exists()) {
        debugPrint('Git config file not found: $configPath');
        return false;
      }
      
      String content = await configFile.readAsString();
      debugPrint('Reading Git config from: $configPath');
      
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
        Uri uri;
        try {
          uri = Uri.parse(currentUrl);
        } catch (e) {
          debugPrint('Error parsing URL: $e');
          return false;
        }
        
        final String domain = '${uri.host}${uri.path}';
        
        // Create new URL with credentials
        final newUrl = 'https://$username:$token@$domain';
        debugPrint('New URL: https://$username:****@$domain');
        
        // Replace the URL in the config
        final updatedContent = content.replaceFirst(
          RegExp('url\\s*=\\s*' + RegExp.escape(currentUrl)),
          'url = $newUrl'
        );
        
        await configFile.writeAsString(updatedContent);
        debugPrint('Git config updated successfully');
        return true;
      }
      
      // Try alternative format
      final alternativeRegex = RegExp(
        r'\[remote\s+"origin"\][\s\S]*?url\s*=\s*(https?:\/\/[^\s]+)',
        multiLine: true,
      );
      
      final alternativeMatch = alternativeRegex.firstMatch(content);
      
      if (alternativeMatch != null) {
        final currentUrl = alternativeMatch.group(1)!;
        debugPrint('Found URL (alternative format): $currentUrl');
        
        // Extract the domain part
        final String domain = currentUrl.replaceFirst(RegExp(r'^https?:\/\/'), '');
        
        // Create new URL with credentials
        final newUrl = 'https://$username:$token@$domain';
        debugPrint('New URL: https://$username:****@$domain');
        
        // Replace the URL in the config
        final updatedContent = content.replaceFirst(
          RegExp('url\\s*=\\s*' + RegExp.escape(currentUrl)),
          'url = $newUrl'
        );
        
        await configFile.writeAsString(updatedContent);
        debugPrint('Git config updated successfully (alternative format)');
        return true;
      }
      
      // Try manual search for URL
      final urlRegex = RegExp(r'url\s*=\s*(https?:\/\/[^\s]+)', multiLine: true);
      final urlMatch = urlRegex.firstMatch(content);
      
      if (urlMatch != null) {
        final currentUrl = urlMatch.group(1)!;
        debugPrint('Found URL (manual search): $currentUrl');
        
        // Extract the domain part
        String domain;
        if (currentUrl.contains('@')) {
          domain = currentUrl.split('@')[1];
        } else {
          domain = currentUrl.replaceFirst(RegExp(r'^https?:\/\/'), '');
        }
        
        // Create new URL with credentials
        final newUrl = 'https://$username:$token@$domain';
        debugPrint('New URL: https://$username:****@$domain');
        
        // Replace the URL in the config
        final updatedContent = content.replaceFirst(
          RegExp('url\\s*=\\s*' + RegExp.escape(currentUrl)),
          'url = $newUrl'
        );
        
        await configFile.writeAsString(updatedContent);
        debugPrint('Git config updated successfully (manual search)');
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