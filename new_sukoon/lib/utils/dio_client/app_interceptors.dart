import 'dart:io';

import 'package:dio/dio.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../models/app_response.dart';


class AppInterceptors extends Interceptor {
  static AppInterceptors? _singleton;

  AppInterceptors._internal();

  factory AppInterceptors() {
    return _singleton ??= AppInterceptors._internal();
  }
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    /// Tries to add Authorization header only if Authorization header not extisted
    if (!options.headers.containsKey(HttpHeaders.authorizationHeader)) {
      final state = AuthBloc().state;

      if (state.token != null) {
        options.headers[HttpHeaders.authorizationHeader] =
            'Bearer ${state.token}';
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    /// Maps custom response
    final responseData = mapResponseData(
      requestOptions: response.requestOptions,
      response: response,
    );

    return handler.resolve(responseData);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    /// Gets custom error message
    final errorMessage = getErrorMessage(err.type, err.response?.statusCode);

    /// Maps custom response
    final responseData = mapResponseData(
      requestOptions: err.requestOptions,
      response: err.response,
      customMessage: errorMessage,
      isErrorResponse: true,
    );

    return handler.resolve(responseData);
  }
}

String getErrorMessage(DioExceptionType errorType, int? statusCode) {
  String errorMessage = "";
  switch (errorType) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      errorMessage = DioErrorMessage.deadlineExceededException;
      break;
    case DioExceptionType.badResponse:
      switch (statusCode) {
        case 400:
          errorMessage = DioErrorMessage.badRequestException;
          break;
        case 401:
          errorMessage = DioErrorMessage.unauthorizedException;
          break;
        case 404:
          errorMessage = DioErrorMessage.notFoundException;
          break;
        case 409:
          errorMessage = DioErrorMessage.conflictException;
          break;
        case 500:
          errorMessage = DioErrorMessage.internalServerErrorException;
          break;
      }
      break;
    case DioExceptionType.cancel:
      break;
    case DioExceptionType.badCertificate:
      errorMessage = DioErrorMessage.badRequestException; // Handle this case
      break;
    case DioExceptionType.unknown:
      errorMessage = DioErrorMessage.unexpectedException;
      break;
    default:
      errorMessage = "An unexpected error occurred."; // Handle any other cases
  }
  return errorMessage;
}


class DioErrorMessage {
  static const badRequestException = "Invalid request";
  static const internalServerErrorException =
      "Unknown error occurred, please try again later.";
  static const conflictException = "Conflict occurred";
  static const unauthorizedException = "Access denied";
  static const notFoundException =
      "The requested information could not be found";
  static const unexpectedException = "Unexpected error occurred.";
  static const noInternetConnectionException =
      "No internet connection detected, please try again.";
  static const deadlineExceededException =
      "The connection has timed out, please try again.";
}

Response<dynamic> mapResponseData({
  Response<dynamic>? response,
  required RequestOptions requestOptions,
  String customMessage = "",
  bool isErrorResponse = false,
}) {
  final bool hasResponseData = response?.data != null;

  Map<String, dynamic>? responseData = response?.data;

  if (hasResponseData) {
    responseData!.addAll({
      "statusCode": response?.statusCode,
      "statusMessage": response?.statusMessage
    });
  }

  return Response(
    requestOptions: requestOptions,
    data: hasResponseData
        ? responseData
        : AppResponse(
            message: customMessage,
            success: isErrorResponse ? false : true,
            statusCode: response?.statusCode,
            statusMessage: response?.statusMessage,
          ).toJson(
            (value) => null,
          ),
  );
}
