import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GetProfileEvent extends ProfileEvent {
  const GetProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? phone;
  final String? photoUrl;

  const UpdateProfileEvent({
    this.name,
    this.phone,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [name, phone, photoUrl];
}

class ChangePasswordEvent extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

class UploadPhotoEvent extends ProfileEvent {
  final String imagePath;

  const UploadPhotoEvent({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}

class RefreshProfileEvent extends ProfileEvent {
  const RefreshProfileEvent();
}
