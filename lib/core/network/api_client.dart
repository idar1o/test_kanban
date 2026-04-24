import 'package:dio/dio.dart';

class KpiDriveApiConfig {
  static const String baseUrl = 'https://api.dev.kpi-drive.ru';
  static const String bearerToken = '5c3964b8e3ee4755f2cc0febb851e2f8';
  static const int authUserId = 40;
  static const int requestedMoId = 42;
}

class ApiClient {
  ApiClient._(this._dio);

  factory ApiClient.create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: KpiDriveApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Authorization': 'Bearer ${KpiDriveApiConfig.bearerToken}',
        },
      ),
    );
    return ApiClient._(dio);
  }

  final Dio _dio;

  Dio get dio => _dio;
}
