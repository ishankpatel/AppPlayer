import 'package:flutter_test/flutter_test.dart';
import 'package:streamvault/data/datasources/torrentio_remote.dart';
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

  test('torrent sources expose 4K quality and key audio languages', () {
    final source = TorrentioStream.fromJson({
      'name': 'Torrentio 4K',
      'title':
          'Example Movie 2160p WEB-DL Dual Audio Hindi English Gujarati\n'
          '👤 42 💾 12.4 GB ⚙️ TorrentGalaxy',
      'infoHash': 'ABCDEF123456',
      'behaviorHints': {'filename': 'Example.2160p.HIN.ENG.GUJ.mkv'},
    });

    expect(source.qualityLabel, '4K');
    expect(
      source.audioLanguages,
      containsAll(['Hindi', 'English', 'Gujarati']),
    );
    expect(source.audioLabel, 'Audio: Hindi, Gujarati, English');
    expect(source.seedLabel, '42 seeders');
  });
}
