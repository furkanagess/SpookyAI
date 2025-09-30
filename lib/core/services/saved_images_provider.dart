import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'image_storage_service.dart';

class SavedImagesProvider extends ChangeNotifier {
  List<SavedImage> _images = <SavedImage>[];
  final Map<String, Uint8List> _imageBytesCache = <String, Uint8List>{};
  bool _isLoading = false;

  List<SavedImage> get images => _images;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _images = await ImageStorageService.getSavedImages();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> addSavedImage({
    required Uint8List imageBytes,
    required String prompt,
    bool isImageToImage = false,
    String? originalImagePath,
  }) async {
    await ImageStorageService.saveImage(
      imageBytes: imageBytes,
      prompt: prompt,
      isImageToImage: isImageToImage,
      originalImagePath: originalImagePath,
    );
    _imageBytesCache.removeWhere((_, __) => true); // invalidate cache
    await load();
  }

  Future<void> deleteById(String imageId) async {
    final ok = await ImageStorageService.deleteImage(imageId);
    if (ok) {
      _imageBytesCache.remove(imageId);
      await load();
    }
  }

  Future<Uint8List?> getImageBytes(String imageId, String filePath) async {
    if (_imageBytesCache.containsKey(imageId)) {
      return _imageBytesCache[imageId];
    }
    final bytes = await ImageStorageService.getImageBytes(filePath);
    if (bytes != null) {
      _imageBytesCache[imageId] = bytes;
    }
    return bytes;
  }
}
