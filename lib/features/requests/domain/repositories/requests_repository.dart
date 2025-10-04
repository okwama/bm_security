import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/request_entity.dart';

abstract class RequestsRepository {
  Future<Either<Failure, List<RequestEntity>>> getRequests({
    int? status,
    int? teamId,
    int? staffId,
  });

  Future<Either<Failure, bool>> updateRequestStatus({
    required int requestId,
    required int newStatus,
    int? staffId,
    double? latitude,
    double? longitude,
  });
}
