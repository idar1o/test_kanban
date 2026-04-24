import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/board_source.dart';
import '../domain/kanban_task.dart';

class BoardHttpSource implements BoardSource {
  BoardHttpSource({
    required ApiClient apiClient,
    this.periodStart = '2026-04-01',
    this.periodEnd = '2026-04-30',
    this.periodKey = 'month',
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final String periodStart;
  final String periodEnd;
  final String periodKey;

  @override
  Future<List<KanbanTask>> loadTasks() async {
    final form = FormData.fromMap({
      'period_start': periodStart,
      'period_end': periodEnd,
      'period_key': periodKey,
      'requested_mo_id': KpiDriveApiConfig.requestedMoId,
      'behaviour_key': 'task,kpi_task',
      'with_result': 'false',
      'response_fields': 'name,indicator_to_mo_id,parent_id,order',
      'auth_user_id': KpiDriveApiConfig.authUserId,
    });

    final resp = await _apiClient.dio.post(
      '/_api/indicators/get_mo_indicators',
      data: form,
    );

    final rows = _extractRows(resp.data);
    return rows.map(_parseTask).toList();
  }

  @override
  Future<void> saveTaskPosition({
    required int indicatorToMoId,
    required int parentId,
    required int order,
  }) async {
    final form = FormData.fromMap({
      'period_start': periodStart,
      'period_end': periodEnd,
      'period_key': periodKey,
      'indicator_to_mo_id': indicatorToMoId,
      'auth_user_id': KpiDriveApiConfig.authUserId,
    });
    form.fields.addAll([
      const MapEntry('field_name', 'parent_id'),
      MapEntry('field_value', '$parentId'),
      const MapEntry('field_name', 'order'),
      MapEntry('field_value', '$order'),
    ]);

    final resp = await _apiClient.dio.post(
      '/_api/indicators/save_indicator_instance_field',
      data: form,
    );

    final data = resp.data;
    if (data is Map && data['STATUS'] != null && data['STATUS'] != 'OK' && data['status'] != 'ok') {
      throw Exception('Сервер отклонил сохранение: ${data['MESSAGE'] ?? data}');
    }
  }

  List<Map<String, dynamic>> _extractRows(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map) {
      for (final key in ['DATA', 'data']) {
        final inner = data[key];
        if (inner is List) return inner.cast<Map<String, dynamic>>();
        if (inner is Map) {
          for (final rowsKey in ['rows', 'ROWS', 'indicators', 'items']) {
            final rows = inner[rowsKey];
            if (rows is List) return rows.cast<Map<String, dynamic>>();
          }
        }
      }
      for (final rowsKey in ['rows', 'ROWS', 'indicators', 'items']) {
        final rows = data[rowsKey];
        if (rows is List) return rows.cast<Map<String, dynamic>>();
      }
    }
    return const [];
  }

  KanbanTask _parseTask(Map<String, dynamic> row) {
    return KanbanTask(
      indicatorToMoId: _asInt(row['indicator_to_mo_id']),
      parentId: _asInt(row['parent_id']),
      name: (row['name'] ?? '').toString(),
      order: _asInt(row['order']),
    );
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
