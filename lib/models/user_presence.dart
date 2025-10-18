class UserPresence {
  final String userId;
  final String status; // 'online', 'offline', 'away'
  final DateTime? lastSeen;
  final DateTime? lastActive;
  final List<String> socketIds;
  final Map<String, dynamic>? deviceInfo;
  final DateTime timestamp;

  UserPresence({
    required this.userId,
    required this.status,
    this.lastSeen,
    this.lastActive,
    this.socketIds = const [],
    this.deviceInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'offline',
      lastSeen:
          json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen']) : null,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'])
          : null,
      socketIds: List<String>.from(json['socketIds'] ?? []),
      deviceInfo: json['deviceInfo'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['deviceInfo'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'socketIds': socketIds,
      'deviceInfo':
          deviceInfo != null ? Map<String, dynamic>.from(deviceInfo!) : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Status getters
  bool get isOnline => status == 'online';
  bool get isAway => status == 'away';
  bool get isOffline => status == 'offline';

  // Display properties
  String get statusDisplay {
    switch (status) {
      case 'online':
        return 'Online';
      case 'away':
        return 'Away';
      case 'offline':
        return 'Offline';
      default:
        return 'Unknown';
    }
  }

  String get lastSeenText {
    if (lastSeen == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String get lastActiveText {
    if (lastActive == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastActive!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Copy with method
  UserPresence copyWith({
    String? userId,
    String? status,
    DateTime? lastSeen,
    DateTime? lastActive,
    List<String>? socketIds,
    Map<String, dynamic>? deviceInfo,
    DateTime? timestamp,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      lastActive: lastActive ?? this.lastActive,
      socketIds: socketIds ?? this.socketIds,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPresence && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserPresence(userId: $userId, status: $status, lastSeen: $lastSeen, lastActive: $lastActive, deviceInfo: ${deviceInfo != null ? 'present' : 'null'})';
  }
}
