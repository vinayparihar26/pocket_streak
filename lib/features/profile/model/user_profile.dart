/// User profile data stored in Hive.
class UserProfile {
  UserProfile({
    required this.name,
    required this.bio,
    required this.monthlyGoal,
    this.avatarBase64,
  });

  /// Display name shown in the dashboard greeting.
  String name;

  /// Short bio / tagline.
  String bio;

  /// Monthly savings goal (₹).
  double monthlyGoal;

  /// Base64-encoded profile photo bytes. Null = no photo set.
  String? avatarBase64;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory UserProfile.empty() => UserProfile(
        name: '',
        bio: '',
        monthlyGoal: 5000,
        avatarBase64: null,
      );

  factory UserProfile.fromMap(Map<String, String> map) => UserProfile(
        name: map['name'] ?? '',
        bio: map['bio'] ?? '',
        monthlyGoal: double.tryParse(map['monthlyGoal'] ?? '') ?? 5000,
        avatarBase64: map['avatarBase64'],
      );

  Map<String, String> toMap() => {
        'name': name,
        'bio': bio,
        'monthlyGoal': monthlyGoal.toString(),
        if (avatarBase64 != null) 'avatarBase64': avatarBase64!,
      };

  UserProfile copyWith({
    String? name,
    String? bio,
    double? monthlyGoal,
    String? avatarBase64,
  }) {
    return UserProfile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
    );
  }
}
