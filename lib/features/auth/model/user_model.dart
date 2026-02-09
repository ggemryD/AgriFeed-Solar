class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.farmName,
    this.location,
    this.machineId,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String? farmName;
  final String? location;
  final String? machineId;
  final String? photoUrl;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? farmName,
    String? location,
    String? machineId,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      machineId: machineId ?? this.machineId,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
