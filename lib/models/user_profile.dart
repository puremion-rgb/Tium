import '../utils/level.dart';

/// Firestore: users/{uid}
class UserProfile {
  const UserProfile({
    required this.uid,
    this.nickname = '틔움이',
    this.totalXp = 0,
    this.city = '서울',
    this.morningAlarm = true,
    this.streak = 0,
    this.bestStreak = 0,
  });

  final String uid;
  final String nickname;
  final int totalXp;
  final String city;
  final bool morningAlarm;

  /// 연속으로 하나 이상 완료한 날 수
  final int streak;
  final int bestStreak;

  LevelInfo get level => levelInfo(totalXp);

  UserProfile copyWith({String? nickname, int? totalXp, String? city, bool? morningAlarm, int? streak, int? bestStreak}) =>
      UserProfile(
        uid: uid,
        nickname: nickname ?? this.nickname,
        totalXp: totalXp ?? this.totalXp,
        city: city ?? this.city,
        morningAlarm: morningAlarm ?? this.morningAlarm,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
      );

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'totalXp': totalXp,
        'city': city,
        'morningAlarm': morningAlarm,
        'streak': streak,
        'bestStreak': bestStreak,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) => UserProfile(
        uid: uid,
        nickname: map['nickname'] as String? ?? '틔움이',
        totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
        city: map['city'] as String? ?? '서울',
        morningAlarm: map['morningAlarm'] as bool? ?? true,
        streak: (map['streak'] as num?)?.toInt() ?? 0,
        bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      );
}
