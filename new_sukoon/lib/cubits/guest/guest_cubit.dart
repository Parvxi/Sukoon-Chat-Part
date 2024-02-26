import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/requests/login_request.dart';
import '../../models/requests/register_request.dart';
import '../../repositaries/auth/auth_repository.dart';

part 'guest_state.dart';
part 'guest_cubit.freezed.dart';

class GuestCubit extends Cubit<GuestState> {
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;

  GuestCubit({
    required AuthRepository authRepository,
    required AuthBloc authBloc,
  })  : _authRepository = authRepository,
        _authBloc = authBloc,
        super(
          const GuestState.initial(),
        );

  Future<String?> signIn(LoginData data) async {
    final response = await _authRepository.login(
      LoginRequest(email: data.name, password: data.password),
    );
    if (response.success) {
      _authBloc.add(Authenticated(
        isAuthenticated: true,
        token: response.data!.token,
        user: response.data!.user,
      ));

      return null;
    }

    return response.message;
  }

  Future<String?> signUp(SignupData data) async {
    final response = await _authRepository.register(
      RegisterRequest(
          email: data.name!,
          password: data.password!,
          passwordConfirmation: data.password!),
    );
    if (response.success) {
      _authBloc.add(Authenticated(
        isAuthenticated: true,
        token: response.data!.token,
        user: response.data!.user,
      ));

      return null;
    }

    return response.message;
  }

  Future<void> signOut() async {
    _authRepository.logout();
    _authBloc.add(const Authenticated(
      isAuthenticated: false,
      user: null,
      token: null,
    ));
  }
}