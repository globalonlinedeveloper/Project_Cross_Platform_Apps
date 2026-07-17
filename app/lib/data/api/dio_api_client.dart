import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../auth/auth_repository.dart';
import '../models/budget_info.dart';
import '../models/entitlement.dart';
import '../models/payment_record.dart';
import '../models/subscription.dart';
import 'api_client.dart';

/// Live client against the app's Cloudflare Worker. Every request carries the
/// Supabase JWT as a bearer token; the Worker verifies it and scopes to the user.
class DioApiClient implements ApiClient {
  DioApiClient(this._auth)
      : _dio = Dio(BaseOptions(
          baseUrl: '${AppConfig.apiBaseUrl}/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: <String, String>{'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        final String? token = await _auth.currentAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final AuthRepository _auth;
  final Dio _dio;

  Never _fail(Object e) {
    if (e is DioException) {
      final int code = e.response?.statusCode ?? 0;
      final dynamic data = e.response?.data;
      final String msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : e.message ?? 'Network error';
      throw ApiException(code, msg);
    }
    throw ApiException(0, e.toString());
  }

  @override
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/subscriptions');
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Subscription> createSubscription(Subscription draft) async {
    try {
      final Response<dynamic> res =
          await _dio.post<dynamic>('/subscriptions', data: draft.toJson());
      return Subscription.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Subscription> getSubscription(String id) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/subscriptions/$id');
      final Map<String, dynamic> data = res.data as Map<String, dynamic>;
      final Map<String, dynamic> sub = data.containsKey('subscription')
          ? data['subscription'] as Map<String, dynamic>
          : data;
      return Subscription.fromJson(sub);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Subscription> updateSubscription(
      String id, Map<String, dynamic> changes) async {
    try {
      final Response<dynamic> res =
          await _dio.patch<dynamic>('/subscriptions/$id', data: changes);
      return Subscription.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    try {
      await _dio.delete<dynamic>('/subscriptions/$id');
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<PaymentRecord>> getPaymentHistory(String id) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/subscriptions/$id');
      final Map<String, dynamic> data = res.data as Map<String, dynamic>;
      final List<dynamic> hist =
          (data['payment_history'] as List<dynamic>?) ?? <dynamic>[];
      return hist
          .map((dynamic e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<BudgetInfo> getBudget() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/budget');
      return BudgetInfo.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<BudgetInfo> updateBudget(BudgetInfo budget) async {
    try {
      final Response<dynamic> res =
          await _dio.put<dynamic>('/budget', data: budget.toJson());
      return BudgetInfo.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Entitlements> getEntitlements() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/entitlements');
      return Entitlements.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      _fail(e);
    }
  }
}
