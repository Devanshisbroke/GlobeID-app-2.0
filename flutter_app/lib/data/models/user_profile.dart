class UserProfile {
  UserProfile({
    required this.userId,
    required this.name,
    required this.passportNumber,
    required this.nationality,
    required this.nationalityFlag,
    required this.verifiedStatus,
    required this.avatarUrl,
    required this.email,
    required this.memberSince,
    required this.identityScore,
  });

  final String userId;
  final String name;
  final String passportNumber;
  final String nationality;
  final String nationalityFlag;
  final String verifiedStatus; // verified | pending | unverified
  final String avatarUrl;
  final String email;
  final String memberSince;
  final int identityScore;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId: j['userId'] as String,
        name: j['name'] as String,
        passportNumber: (j['passportNumber'] as String?) ?? '',
        nationality: (j['nationality'] as String?) ?? '',
        nationalityFlag: (j['nationalityFlag'] as String?) ?? '🌍',
        verifiedStatus: (j['verifiedStatus'] as String?) ?? 'unverified',
        avatarUrl: (j['avatarUrl'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        memberSince: (j['memberSince'] as String?) ?? '',
        identityScore: (j['identityScore'] as num?)?.toInt() ?? 0,
      );

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    String? email,
    int? identityScore,
    String? verifiedStatus,
  }) =>
      UserProfile(
        userId: userId,
        name: name ?? this.name,
        passportNumber: passportNumber,
        nationality: nationality,
        nationalityFlag: nationalityFlag,
        verifiedStatus: verifiedStatus ?? this.verifiedStatus,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        email: email ?? this.email,
        memberSince: memberSince,
        identityScore: identityScore ?? this.identityScore,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'passportNumber': passportNumber,
        'nationality': nationality,
        'nationalityFlag': nationalityFlag,
        'verifiedStatus': verifiedStatus,
        'avatarUrl': avatarUrl,
        'email': email,
        'memberSince': memberSince,
        'identityScore': identityScore,
      };

  static UserProfile defaults() => UserProfile(
        userId: 'usr-001',
        name: 'GlobeID User',
        passportNumber: '',
        nationality: '',
        nationalityFlag: '🌍',
        verifiedStatus: 'unverified',
        avatarUrl: '',
        email: '',
        memberSince: '',
        identityScore: 0,
      );
}
