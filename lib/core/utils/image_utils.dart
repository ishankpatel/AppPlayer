import '../constants/api_constants.dart';

class ImageUtils {
  const ImageUtils._();

  static String? tmdbPoster(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConstants.tmdbImageBaseUrl}/$size$path';
  }

  static String? tmdbBackdrop(String? path, {String size = 'w1280'}) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConstants.tmdbImageBaseUrl}/$size$path';
  }
}
