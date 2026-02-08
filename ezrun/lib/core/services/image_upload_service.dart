import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';

/// Image upload service using ImageKit
class ImageUploadService {
  /// Upload an image file to ImageKit and return the URL
  Future<String> uploadImage(
    File imageFile, {
    String? fileName,
    String folder = '/ezrun/profiles/',
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.imageKitEndpoint),
      );

      // Add authentication
      final authString = base64Encode(
        utf8.encode('${ApiConstants.imageKitPrivateKey}:'),
      );
      request.headers['Authorization'] = 'Basic $authString';

      final ext = p
          .extension(imageFile.path)
          .toLowerCase()
          .replaceFirst('.', '');
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final resolvedFileName =
          fileName ??
          'profile_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

      // Add file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: resolvedFileName,
        contentType: _mediaTypeForExtension(safeExt),
      );

      request.files.add(multipartFile);

      // ImageKit requires fileName as a separate parameter even when uploading multipart
      request.fields['fileName'] = resolvedFileName;

      // Add folder for organization
      request.fields['folder'] = folder;

      // Add other parameters
      request.fields['useUniqueFileName'] = 'true';

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['url'] as String;
      } else {
        final message =
            _tryExtractMessage(responseBody) ??
            'Upload failed (${response.statusCode}). Please try again.';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Delete an image from ImageKit using its URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file ID from ImageKit URL
      // ImageKit URLs typically look like: https://ik.imagekit.io/{imageKitId}/{path}/{filename}
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        throw Exception('Invalid ImageKit URL format');
      }

      // The file ID is usually the last segment (filename without extension)
      final fileName = pathSegments.last;
      final fileId = fileName
          .split('.')
          .first; // Remove extension to get file ID

      // ImageKit delete API endpoint
      final deleteUrl = 'https://api.imagekit.io/v1/files/$fileId';

      // Create authenticated request
      final authString = base64Encode(
        utf8.encode('${ApiConstants.imageKitPrivateKey}:'),
      );

      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {'Authorization': 'Basic $authString'},
      );

      if (response.statusCode == 204) {
        // 204 No Content is success for delete
        return;
      } else if (response.statusCode == 404) {
        // File not found - consider it already deleted
        return;
      } else {
        final message =
            _tryExtractMessage(response.body) ??
            'Delete failed (${response.statusCode}). Please try again.';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Validate image file (size, type, etc.)
  bool validateImage(File imageFile) {
    // Check file size (max 5MB)
    final maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (imageFile.lengthSync() > maxSize) {
      throw Exception('Image size must be less than 5MB');
    }

    // Check file extension
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    final extension = imageFile.path.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      throw Exception('Only JPG, PNG, and GIF images are allowed');
    }

    return true;
  }

  MediaType _mediaTypeForExtension(String ext) {
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  String? _tryExtractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // ignore
    }
    return null;
  }
}
