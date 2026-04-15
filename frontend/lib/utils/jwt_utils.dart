import 'dart:convert';

/// Decodes a JWT token's payload section (base64url-encoded JSON).
/// Does NOT verify the signature — safe when token is received over HTTPS
/// directly from the OAuth2 provider.
Map<String, dynamic> decodeJwtPayload(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) throw const FormatException('Invalid JWT format');
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  final decoded = utf8.decode(base64Url.decode(normalized));
  return jsonDecode(decoded) as Map<String, dynamic>;
}
