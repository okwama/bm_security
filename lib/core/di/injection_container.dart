import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../utils/auth_config.dart';

// Core
import '../network/network_info.dart';

// Features - Auth
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Features - Requests
import '../../features/requests/data/datasources/requests_local_datasource.dart';
import '../../features/requests/data/datasources/requests_remote_datasource.dart';
import '../../features/requests/data/repositories/requests_repository_impl.dart';
import '../../features/requests/domain/repositories/requests_repository.dart';
import '../../features/requests/domain/usecases/get_requests_usecase.dart';
import '../../features/requests/domain/usecases/update_request_status_usecase.dart';
import '../../features/requests/presentation/bloc/requests_bloc.dart';

// Features - SOS
import '../../features/sos/data/datasources/sos_remote_datasource.dart';
import '../../features/sos/data/repositories/sos_repository_impl.dart';
import '../../features/sos/domain/repositories/sos_repository.dart';
import '../../features/sos/domain/usecases/send_sos_usecase.dart';
import '../../features/sos/presentation/bloc/sos_bloc.dart';

// Features - Cash Count
import '../../features/cash_count/data/datasources/cash_count_remote_datasource.dart';
import '../../features/cash_count/data/repositories/cash_count_repository_impl.dart';
import '../../features/cash_count/domain/repositories/cash_count_repository.dart';
import '../../features/cash_count/domain/usecases/submit_cash_count_usecase.dart';
import '../../features/cash_count/presentation/bloc/cash_count_bloc.dart';

// Features - Teams
import '../../features/teams/data/datasources/teams_remote_datasource.dart';
import '../../features/teams/data/repositories/teams_repository_impl.dart';
import '../../features/teams/domain/repositories/teams_repository.dart';
import '../../features/teams/domain/usecases/get_my_team_usecase.dart';
import '../../features/teams/domain/usecases/get_team_by_id_usecase.dart';
import '../../features/teams/domain/usecases/get_team_members_usecase.dart';
import '../../features/teams/presentation/bloc/teams_bloc.dart';

// Features - Profile
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/domain/usecases/change_password_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// Features - Location
import '../../features/location/data/datasources/location_local_datasource.dart';
import '../../features/location/data/datasources/location_remote_datasource.dart';
import '../../features/location/data/repositories/location_repository_impl.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/location/domain/usecases/update_location_usecase.dart';
import '../../features/location/domain/usecases/get_location_history_usecase.dart';
import '../../features/location/presentation/bloc/location_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(storage: sl()),
  );

  //! Features - Requests
  // Bloc
  sl.registerFactory(
    () => RequestsBloc(
      getRequestsUseCase: sl(),
      updateRequestStatusUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetRequestsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRequestStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<RequestsRepository>(
    () => RequestsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<RequestsRemoteDataSource>(
    () => RequestsRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<RequestsLocalDataSource>(
    () => RequestsLocalDataSourceImpl(storage: sl()),
  );

  //! Features - SOS
  // Bloc
  sl.registerFactory(
    () => SOSBloc(
      sendSOSUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendSOSUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SOSRepository>(
    () => SOSRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<SOSRemoteDataSource>(
    () => SOSRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Cash Count
  // Bloc
  sl.registerFactory(
    () => CashCountBloc(
      submitCashCountUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SubmitCashCountUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CashCountRepository>(
    () => CashCountRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<CashCountRemoteDataSource>(
    () => CashCountRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Teams
  // Bloc
  sl.registerFactory(
    () => TeamsBloc(
      getMyTeamUseCase: sl(),
      getTeamByIdUseCase: sl(),
      getTeamMembersUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMyTeamUseCase(sl()));
  sl.registerLazySingleton(() => GetTeamByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetTeamMembersUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TeamsRepository>(
    () => TeamsRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<TeamsRemoteDataSource>(
    () => TeamsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Profile
  // Bloc
  sl.registerFactory(
    () => ProfileBloc(
      getProfileUseCase: sl(),
      updateProfileUseCase: sl(),
      changePasswordUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Location
  // Bloc
  sl.registerFactory(
    () => LocationBloc(
      updateLocationUseCase: sl(),
      getLocationHistoryUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => UpdateLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetLocationHistoryUseCase(sl()));

  // Repository
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  //! External
  final storage = const FlutterSecureStorage();
  sl.registerLazySingleton(() => storage);

  final dio = Dio();
  dio.options.baseUrl = ApiConfig.baseUrl;
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);
  
  // Add interceptors
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  sl.registerLazySingleton(() => dio);
  
  // HTTP client for requests
  sl.registerLazySingleton(() => http.Client());
}
