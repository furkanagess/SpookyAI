import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class SavedImage {
  final String id;
  final String prompt;
  final DateTime createdAt;
  final String filePath;
  final bool isImageToImage;
  final String? originalImagePath;

  SavedImage({
    required this.id,
    required this.prompt,
    required this.createdAt,
    required this.filePath,
    this.isImageToImage = false,
    this.originalImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'filePath': filePath,
      'isImageToImage': isImageToImage,
      'originalImagePath': originalImagePath,
    };
  }

  factory SavedImage.fromJson(Map<String, dynamic> json) {
    return SavedImage(
      id: json['id'],
      prompt: json['prompt'],
      createdAt: DateTime.parse(json['createdAt']),
      filePath: json['filePath'],
      isImageToImage: json['isImageToImage'] ?? false,
      originalImagePath: json['originalImagePath'],
    );
  }
}

class ImageStorageService {
  static const String _imagesKey = 'saved_images';
  static const String _imagesDirectory = 'spooky_ai_images';

  /// Save an image to local storage and gallery
  static Future<String> saveImage({
    required Uint8List imageBytes,
    required String prompt,
    bool isImageToImage = false,
    String? originalImagePath,
  }) async {
    try {
      // Best-effort permissions:
      // - We always save to app documents (no permission required)
      // - Gallery export is attempted opportunistically; if permission is
      //   denied or platform restriction occurs, we continue without failing
      //   the overall save.
      try {
        if (Platform.isIOS) {
          await Permission.photosAddOnly.request();
        } else if (Platform.isAndroid) {
          // On Android 13+ READ_MEDIA_IMAGES is managed by the gallery plugin.
          // For older versions, request legacy storage if available.
          await Permission.storage.request();
        }
      } catch (_) {
        // Ignore permission request errors; we will still save locally below.
      }

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/$_imagesDirectory');

      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'spooky_creation_$timestamp.png';
      final filePath = '${imagesDir.path}/$filename';

      // Save image to local storage
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Try to save to gallery (non-fatal on failure)
      try {
        await Gal.putImageBytes(imageBytes, name: filename);
      } catch (_) {
        // Ignore gallery failures; image is still saved locally.
      }

      // Create saved image record
      final savedImage = SavedImage(
        id: timestamp.toString(),
        prompt: prompt,
        createdAt: DateTime.now(),
        filePath: filePath,
        isImageToImage: isImageToImage,
        originalImagePath: originalImagePath,
      );

      // Save metadata to SharedPreferences
      await _saveImageMetadata(savedImage);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Get all saved images
  static Future<List<SavedImage>> getSavedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_imagesKey) ?? [];

      return imagesJson.map((json) {
        final data = jsonDecode(json);
        return SavedImage.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete an image
  static Future<bool> deleteImage(String imageId) async {
    try {
      final images = await getSavedImages();
      final imageIndex = images.indexWhere((img) => img.id == imageId);

      if (imageIndex == -1) return false;

      final image = images[imageIndex];

      // Delete file from storage
      final file = File(image.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from metadata
      images.removeAt(imageIndex);
      await _saveImagesMetadata(images);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get image bytes from file path
  static Future<Uint8List?> getImageBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Share an image
  static Future<bool> shareImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Note: share_plus will be used in the UI layer
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save image metadata to SharedPreferences
  static Future<void> _saveImageMetadata(SavedImage image) async {
    final images = await getSavedImages();
    images.insert(0, image); // Add to beginning for newest first
    await _saveImagesMetadata(images);
  }

  /// Save all images metadata to SharedPreferences
  static Future<void> _saveImagesMetadata(List<SavedImage> images) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = images.map((img) => jsonEncode(img.toJson())).toList();
    await prefs.setStringList(_imagesKey, imagesJson);
  }

  /// Clear all saved images
  static Future<void> clearAllImages() async {
    try {
      // Delete all files
      final images = await getSavedImages();
      for (final image in images) {
        final file = File(image.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear metadata
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imagesKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get storage usage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final images = await getSavedImages();
      int totalSize = 0;

      for (final image in images) {
        final file = File(image.filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return {
        'count': images.length,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {'count': 0, 'totalSize': 0, 'totalSizeMB': '0.00'};
    }
  }
}
