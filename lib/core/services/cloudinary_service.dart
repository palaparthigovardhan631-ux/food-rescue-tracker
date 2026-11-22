import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class CloudinaryUploadResult {
  final String publicId;
  final String secureUrl;
  final String thumbnailUrl;
  final String webpUrl;

  CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.thumbnailUrl,
    required this.webpUrl,
  });
}

class CloudinaryService {
  /// Uploads an image file to Cloudinary using an unsigned upload preset.
  /// Automatically generates WebP-compressed and responsive thumbnail URLs.
  static Future<CloudinaryUploadResult> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(AppConstants.cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      request.fields['folder'] = 'food_listings';
      
      // Attach the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String publicId = data['public_id'];
        final String secureUrl = data['secure_url'];

        // Automatic WebP compression and thumbnail transformations
        // Cloudinary URL transformation format: .../image/upload/{transforms}/{public_id}.{format}
        final String webpUrl = _buildTransformedUrl(
          secureUrl,
          'f_webp,q_auto:good',
        );
        final String thumbnailUrl = _buildTransformedUrl(
          secureUrl,
          'c_fill,w_350,h_350,f_webp,q_auto:low',
        );

        return CloudinaryUploadResult(
          publicId: publicId,
          secureUrl: secureUrl,
          thumbnailUrl: thumbnailUrl,
          webpUrl: webpUrl,
        );
      } else {
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload food photo: $e');
    }
  }

  /// Injects Cloudinary transformation tags into the URL.
  static String _buildTransformedUrl(String originalUrl, String transformation) {
    if (!originalUrl.contains('/upload/')) return originalUrl;
    return originalUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}
