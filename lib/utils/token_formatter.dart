class TokenFormatter {
  // Format token to show only first 8 characters
  static String obscureToken(String token) {
    if (token.isEmpty) return '';
    
    if (token.length <= 8) return token;
    return '${token.substring(0, 8)}${List.filled(token.length - 8, '•').join()}';
  }
}