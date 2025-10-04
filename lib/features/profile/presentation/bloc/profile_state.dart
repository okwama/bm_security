import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;

  const ProfileLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}

class ProfileUpdated extends ProfileState {
  final UserEntity user;

  const ProfileUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

class PasswordChanged extends ProfileState {
  const PasswordChanged();
}

class PhotoUploaded extends ProfileState {
  final String photoUrl;

  const PhotoUploaded({required this.photoUrl});

  @override
  List<Object> get props => [photoUrl];
}
