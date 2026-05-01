import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/media_repository.dart';
import '../../providers.dart';

/// Loaded once per app launch and kept alive forever so flipping between
/// tabs (Home/Movies/TV/Anime/Sports/My List) or visiting Settings/Search
/// never re-fetches the catalog.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  ref.keepAlive();
  return ref.watch(mediaRepositoryProvider).homeFeed();
});
