import '../../data/repositories/media_repository.dart';

class GetTrending {
  const GetTrending(this._repository);

  final MediaRepository _repository;

  Future<HomeFeed> call() => _repository.homeFeed();
}
