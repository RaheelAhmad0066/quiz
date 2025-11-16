/// Leaderboard Model
class LeaderboardModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final int totalPoints;
  final int testsCompleted;
  final int matchesWon; // Number of matches won
  final DateTime lastUpdated;
  final bool isCurrentUser;

  LeaderboardModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.totalPoints,
    required this.testsCompleted,
    this.matchesWon = 0,
    required this.lastUpdated,
    this.isCurrentUser = false,
  });

  factory LeaderboardModel.fromJson(Map<dynamic, dynamic> json, String id, {String? currentUserId}) {
    return LeaderboardModel(
      userId: id,
      userName: json['userName']?.toString() ?? 'Unknown User',
      userEmail: json['userEmail']?.toString() ?? '',
      userAvatar: json['userAvatar']?.toString(),
      totalPoints: (json['totalPoints'] ?? 0) as int,
      testsCompleted: (json['testsCompleted'] ?? 0) as int,
      matchesWon: (json['matchesWon'] ?? 0) as int,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int)
          : DateTime.now(),
      isCurrentUser: currentUserId != null && id == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
      'totalPoints': totalPoints,
      'testsCompleted': testsCompleted,
      'matchesWon': matchesWon,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  LeaderboardModel copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userAvatar,
    int? totalPoints,
    int? testsCompleted,
    int? matchesWon,
    DateTime? lastUpdated,
    bool? isCurrentUser,
  }) {
    return LeaderboardModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
      totalPoints: totalPoints ?? this.totalPoints,
      testsCompleted: testsCompleted ?? this.testsCompleted,
      matchesWon: matchesWon ?? this.matchesWon,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

