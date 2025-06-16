import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

Future<bool> signUp(String serverAddress, String username, String password) async
{
  final uri = Uri.parse('$serverAddress/auth/signup');
  final response = await http.post(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    debugPrint('⚠️ Sign up failed: ${jsonDecode(response.body)['detail']}');
    return false;
  }
}

Future<bool> signIn(String serverAddress, String username, String password) async {
  final uri = Uri.parse('$serverAddress/auth/login');
  final response = await http.post(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    print('Login failed: ${jsonDecode(response.body)['detail']}');
    return false;
  }
}

Future<bool> recordSession({
  required String serverAddress,
  required String username,
  required String sessionType,
  required DateTime startTime,
  required DateTime endTime,
}) async {
  final uri = Uri.parse('$serverAddress/session/record');

  final response = await http.post(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username,
      'session_type': sessionType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    }),
  );

  if (response.statusCode == 200) {
    debugPrint('\n세션 기록 전송 완료');
    return true;
  } else {
    debugPrint('\n세션 기록 실패: ${response.statusCode}');
    return false;
  }
}

Future<List<Map<String, dynamic>>> fetchSessionHistory(String serverAddress, String username) async {
  final uri = Uri.parse('$serverAddress/session/history/$username');

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)); // date, total_minutes
  } else {
    print('세션 통계를 가져오지 못했습니다. (${response.statusCode})');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchUserTaskLists(String server, String user) async {
  final uri = Uri.parse('$server/task/lists/$user');
  final response = await http.get(uri);
  if (response.statusCode == 200)
  {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
  return [];
}

Future<List<Map<String, dynamic>>> fetchTasksInList(String server, int listId) async {
  final uri = Uri.parse('$server/task/list/$listId/tasks');
  final response = await http.get(uri);
  if (response.statusCode == 200)
  {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
  return [];
}

Future<bool> createTaskList({
  required String server,
  required String username,
  required String title,
}) async
{
  final uri = Uri.parse('$server/task/list');
  final response = await http.post(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(
    {
      'owner_id': username,
      'name': title,
    }),
  );
  return response.statusCode == 200;
}

Future<bool> addTaskToList({
  required String server,
  required int listId,
  required String title,
  required String description,
  required int order,
}) async {
  final uri = Uri.parse('$server/task/list/$listId/task');
  final response = await http.post(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'description': description,
      'order': order,
    }),
  );
  return response.statusCode == 200;
}

Future<bool> deleteTask(String server, int taskId) async {
  final uri = Uri.parse('$server/task/task/$taskId');
  final response = await http.delete(uri);
  return response.statusCode == 200;
}

Future<bool> updateTaskTitle(String server, int taskId, String newTitle) async {
  final uri = Uri.parse('\$server/task/task/$taskId');
  final response = await http.put(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'title': newTitle}),
  );
  return response.statusCode == 200;
}

Future<bool> updateTask(String server, int taskId, String newTitle, String newDescription) async {
  final uri = Uri.parse('$server/task/task/$taskId');
  final response = await http.put(uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': newTitle,
      'description': newDescription,
    }),
  );
  return response.statusCode == 200;
}

Future<bool> deleteTaskList(String server, int listId) async {
  final uri = Uri.parse('$server/task/list/$listId');
  final response = await http.delete(uri);
  return response.statusCode == 200;
}