import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final ChangePasswordUseCase changePasswordUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.changePasswordUseCase,
  }) : super(ProfileInitial()) {
    on<GetProfileEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<ChangePasswordEvent>(_onChangePassword);
    on<UploadPhotoEvent>(_onUploadPhoto);
    on<RefreshProfileEvent>(_onRefreshProfile);
  }

  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    final result = await getProfileUseCase(NoParams());
    
    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (user) => emit(ProfileLoaded(user: user)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    final result = await updateProfileUseCase(UpdateProfileParams(
      name: event.name,
      phone: event.phone,
      photoUrl: event.photoUrl,
    ));
    
    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (user) => emit(ProfileUpdated(user: user)),
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    final result = await changePasswordUseCase(ChangePasswordParams(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    ));
    
    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (_) => emit(const PasswordChanged()),
    );
  }

  Future<void> _onUploadPhoto(
    UploadPhotoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    // TODO: Implement photo upload use case
    emit(const ProfileError(message: 'Photo upload not implemented yet'));
  }

  Future<void> _onRefreshProfile(
    RefreshProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    add(const GetProfileEvent());
  }
}
