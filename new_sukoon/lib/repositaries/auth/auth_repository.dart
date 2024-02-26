import 'package:dio/dio.dart';
import '../../models/app_response.dart';
import '../../models/requests/login_request.dart';
import '../../models/requests/register_request.dart';
import '../../models/user_model.dart';
import '../../utils/dio_client/dio_client.dart';
import '../core/endpoints.dart';
import 'base_auth_repository.dart';

class AuthRepository extends BaseAuthRepository {
  AuthRepository({
    Dio? dioClient,
  }) : _dioClient = dioClient ?? DioClient().instance;

  final Dio _dioClient;

  @override
  Future<AppResponse<AuthUser?>> login(LoginRequest request) async {
    final response = await _dioClient.post(
      Endpoints.login,
      data: request.toJson(),
    );

    return AppResponse<AuthUser?>.fromJson(
      response.data,
      (dynamic json) => response.data['success'] && json != null
          ? AuthUser.fromJson(json)
          : null,
    );
  }

  @override
  Future<AppResponse<UserEntity?>> loginWithToken() async {
    final response = await _dioClient.post(
      Endpoints.loginWithToken,
    );

    return AppResponse<UserEntity?>.fromJson(
      response.data,
      (dynamic json) => response.data['success'] && json != null
          ? UserEntity.fromJson(json)
          : null,
    );
  }

  @override
  Future<AppResponse> logout() async {
    final response = await _dioClient.get(
      Endpoints.logout,
    );

    return AppResponse.fromJson(
      response.data,
      (dynamic json) => null,
    );
  }

  @override
  Future<AppResponse<AuthUser?>> register(RegisterRequest request) async {
    final response = await _dioClient.post(
      Endpoints.register,
      data: request.toJson(),
    );

    return AppResponse<AuthUser?>.fromJson(
      response.data,
      (dynamic json) => response.data['success'] && json != null
          ? AuthUser.fromJson(json)
          : null,
    );
  }
}