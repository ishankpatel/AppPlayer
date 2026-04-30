import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/media_repository.dart';
import '../../providers.dart';

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  return ref.watch(mediaRepositoryProvider).homeFeed();
});
