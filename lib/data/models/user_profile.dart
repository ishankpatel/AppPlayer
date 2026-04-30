class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarColor = '#FF4F2E',
    this.preferredSubtitleLanguage = 'en',
    this.preferredAudioLanguage = 'en',
  });

  final String id;
  final String displayName;
  final String avatarColor;
  final String preferredSubtitleLanguage;
  final String preferredAudioLanguage;
}
