class ProfileLink {
  const ProfileLink({
    required this.id,
    required this.seniorId,
    required this.guardianId,
  });

  final String id;
  final String seniorId;
  final String guardianId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'seniorId': seniorId,
        'guardianId': guardianId,
      };

  factory ProfileLink.fromJson(Map<String, dynamic> json) => ProfileLink(
        id: json['id'] as String,
        seniorId: json['seniorId'] as String,
        guardianId: json['guardianId'] as String,
      );
}
