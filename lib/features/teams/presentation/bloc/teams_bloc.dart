import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_team_usecase.dart';
import '../../domain/usecases/get_team_by_id_usecase.dart';
import '../../domain/usecases/get_team_members_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import 'teams_event.dart';
import 'teams_state.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  final GetMyTeamUseCase getMyTeamUseCase;
  final GetTeamByIdUseCase getTeamByIdUseCase;
  final GetTeamMembersUseCase getTeamMembersUseCase;

  TeamsBloc({
    required this.getMyTeamUseCase,
    required this.getTeamByIdUseCase,
    required this.getTeamMembersUseCase,
  }) : super(TeamsInitial()) {
    on<GetMyTeamEvent>(_onGetMyTeam);
    on<GetTeamByIdEvent>(_onGetTeamById);
    on<GetAllTeamsEvent>(_onGetAllTeams);
    on<CreateTeamEvent>(_onCreateTeam);
    on<UpdateTeamEvent>(_onUpdateTeam);
    on<DeleteTeamEvent>(_onDeleteTeam);
    on<AddMemberToTeamEvent>(_onAddMemberToTeam);
    on<RemoveMemberFromTeamEvent>(_onRemoveMemberFromTeam);
    on<RefreshTeamsEvent>(_onRefreshTeams);
    on<GetTeamMembersEvent>(_onGetTeamMembers);
  }

  Future<void> _onGetMyTeam(
    GetMyTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    final result = await getMyTeamUseCase(NoParams());
    
    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (teams) => emit(TeamsLoaded(teams: teams)),
    );
  }

  Future<void> _onGetTeamById(
    GetTeamByIdEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    final result = await getTeamByIdUseCase(GetTeamByIdParams(teamId: event.teamId));
    
    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (team) => emit(TeamLoaded(team: team)),
    );
  }

  Future<void> _onGetAllTeams(
    GetAllTeamsEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    // TODO: Implement GetAllTeamsUseCase
    emit(const TeamsError(message: 'Get all teams not implemented yet'));
  }

  Future<void> _onCreateTeam(
    CreateTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    // TODO: Implement CreateTeamUseCase
    emit(const TeamsError(message: 'Create team not implemented yet'));
  }

  Future<void> _onUpdateTeam(
    UpdateTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    // TODO: Implement UpdateTeamUseCase
    emit(const TeamsError(message: 'Update team not implemented yet'));
  }

  Future<void> _onDeleteTeam(
    DeleteTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    // TODO: Implement DeleteTeamUseCase
    emit(const TeamsError(message: 'Delete team not implemented yet'));
  }

  Future<void> _onAddMemberToTeam(
    AddMemberToTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    // TODO: Implement AddMemberToTeamUseCase
    emit(const TeamsError(message: 'Add member not implemented yet'));
  }

  Future<void> _onRemoveMemberFromTeam(
    RemoveMemberFromTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());
    
    // TODO: Implement RemoveMemberFromTeamUseCase
    emit(const TeamsError(message: 'Remove member not implemented yet'));
  }

  Future<void> _onRefreshTeams(
    RefreshTeamsEvent event,
    Emitter<TeamsState> emit,
  ) async {
    add(const GetMyTeamEvent());
  }

  Future<void> _onGetTeamMembers(
    GetTeamMembersEvent event,
    Emitter<TeamsState> emit,
  ) async {
    // Don't emit loading here to avoid overwriting the TeamsLoaded state
    // emit(TeamsLoading());
    
    final result = await getTeamMembersUseCase(GetTeamMembersParams(teamId: event.teamId));
    
    result.fold(
      (failure) {
        emit(TeamsError(message: failure.message));
      },
      (members) {
        emit(TeamMembersLoaded(teamId: event.teamId, members: members));
      },
    );
  }
}
