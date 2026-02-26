import '../constants/api_constants.dart';

class UrlUtil {
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    try {
      final apiUri = Uri.parse(ApiConstants.baseUrl);
      
      // If it's a relative path, prepend the base storage URL
      if (!url.startsWith('http')) {
        // Find the base domain/IP from baseUrl
        final base = "${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}";
        // Assuming Laravel's /storage link
        return '$base/storage/$url';
      }

      final imageUri = Uri.parse(url);
      
      // If the image URL points to a loopback address or emulator address, 
      // replace it with the actual API host/IP
      if (imageUri.host == '127.0.0.1' || 
          imageUri.host == 'localhost' || 
          imageUri.host == '10.0.2.2') {
        
        return imageUri.replace(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.hasPort ? apiUri.port : null,
        ).toString();
      }
    } catch (e) {
      // If parsing fails, return the original
    }

    return url;
  }
}
