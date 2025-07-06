class User {
  User({
    required this.name,
    required this.uid,
    this.profilePic,
    required this.isOnline,
    required this.phoneNumber,
    required this.groupId,
    this.fcmToken, // 👈 yeni alan
  });

  final String name;
  final String uid;
  final String? profilePic;
  final bool isOnline;
  final String phoneNumber;
  final List<String> groupId;
  final String? fcmToken; // 👈 yeni alan

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'uid': uid,
      'profilePic': profilePic,
      'isOnline': isOnline,
      'phoneNumber': phoneNumber,
      'groupId': groupId,
      'fcmToken': fcmToken, // 👈 ekledik
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      uid: map['uid'] as String,
      profilePic:
      map['profilePic'] != null ? map['profilePic'] as String : null,
      isOnline: map['isOnline'] as bool,
      phoneNumber: map['phoneNumber'] as String,
      groupId: (map['groupId'] as List).map((e) => e.toString()).toList(),
      fcmToken: map['fcmToken'] as String?, // 👈 ekledik
    );
  }

  @override
  String toString() {
    return 'User(name: $name, uid: $uid, profilePic: $profilePic, isOnline: $isOnline, phoneNumber: $phoneNumber, groupId: $groupId, fcmToken: $fcmToken)';
  }
}
