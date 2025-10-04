import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserEntity>> getProfile();
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  });
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Either<Failure, String>> uploadPhoto(String imagePath);
}
