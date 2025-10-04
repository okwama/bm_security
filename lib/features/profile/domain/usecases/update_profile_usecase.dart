import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      name: params.name,
      phone: params.phone,
      photoUrl: params.photoUrl,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? name;
  final String? phone;
  final String? photoUrl;

  const UpdateProfileParams({
    this.name,
    this.phone,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [name, phone, photoUrl];
}
