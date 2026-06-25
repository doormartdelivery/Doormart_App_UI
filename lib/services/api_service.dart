import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<dynamic> get(String path, {String? token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
          )
          .timeout(_requestTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check the backend URL.', 408);
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check the backend URL.', 408);
    }
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check the backend URL.', 408);
    }
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check the backend URL.', 408);
    }
  }

  Future<dynamic> delete(String path, {String? token}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
          )
          .timeout(_requestTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check the backend URL.', 408);
    }
  }

  Future<dynamic> uploadImage(
    String path, {
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    required String fieldName,
    String? token,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (kIsWeb) {
      if (bytes == null) {
        throw StateError('Image bytes are required on web');
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName ?? 'upload.jpg',
        ),
      );
    } else {
      if (filePath == null || filePath.isEmpty) {
        throw StateError('File path is required');
      }
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, filePath),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = body is Map<String, dynamic>
          ? body['message'] as String? ?? 'Request failed'
          : 'Request failed';
      throw ApiException(message, response.statusCode);
    }
    return body;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
