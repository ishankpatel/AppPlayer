import 'package:flutter_test/flutter_test.dart';
import 'package:streamvault/data/models/media_item.dart';

void main() {
  test('ships with mock media for offline-first boot', () {
    expect(MediaItem.samples.length, greaterThanOrEqualTo(50));
    expect(MediaItem.samples.first.backdropUrl, isNotNull);
  });

  test('catalog includes anime and TV episodes for detail browsing', () {
    final anime = MediaItem.samples.where(
      (item) => item.tags.contains('anime'),
    );
    final seriesWithEpisodes = MediaItem.samples.where(
      (item) =>
          item.mediaType == MediaType.tv && item.availableSeasons.isNotEmpty,
    );
    final theBoys = MediaItem.samples.firstWhere(
      (item) => item.title == 'The Boys',
    );

    expect(anime.length, greaterThanOrEqualTo(10));
    expect(seriesWithEpisodes.length, greaterThanOrEqualTo(20));
    expect(
      seriesWithEpisodes.first.availableSeasons.first.episodes,
      isNotEmpty,
    );
    expect(
      theBoys.availableSeasons.first.episodes.length,
      greaterThanOrEqualTo(8),
    );
    expect(theBoys.availableSeasons.length, greaterThanOrEqualTo(3));
  });

  test('sample catalog avoids duplicate visible titles', () {
    final titles = MediaItem.samples.map((item) => item.title).toList();
    expect(titles.toSet().length, titles.length);
  });
}
