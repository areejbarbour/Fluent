import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluent/data/models/word_model.dart';
import 'package:fluent/data/services/word_service.dart';

class WordRepository {
  final WordService wordService;
  WordRepository(this.wordService);

  /// Backend StoreWordRequest: audio max 5120 KB = 5 MB
  static const int maxAudioBytes = 5 * 1024 * 1024;

  Map<String, dynamic> _unwrapResource(Map<String, dynamic> raw) {
    final inner = raw['data'];
    if (inner is Map<String, dynamic> && inner['id'] != null) {
      return inner;
    }
    if (raw['id'] != null &&
        (raw['word_en'] != null || raw['word_ar'] != null)) {
      return raw;
    }
    return raw;
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is! Map) return fallback;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      if (firstValue is String) return firstValue;
    }
    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (data['error'] is String && (data['error'] as String).isNotEmpty) {
      return data['error'] as String;
    }
    return fallback;
  }

  Map<String, dynamic> _errorPayload(DioException e) {
    final data = e.response?.data;
    return {
      'success': false,
      'message': _extractMessage(data, e.message ?? 'Request failed'),
      'errors': data is Map ? data['errors'] : null,
    };
  }

  Future<MultipartFile> _toMultipart(File file, String filename) async {
    return MultipartFile.fromFile(file.path, filename: filename);
  }

  /// POST /api/words/{lesson}/create
  /// Backend: word_en, word_ar, audio (required file, max 5MB)
  Future<Map<String, dynamic>> createWord(
    int lessonId, {
    required String wordEn,
    required String wordAr,
    required File audioFile,
    String? audioFileName,
  }) async {
    try {
      final length = await audioFile.length();
      if (length > maxAudioBytes) {
        return {
          'success': false,
          'message': 'Audio must be 5MB or smaller.',
          'errors': {
            'audio': ['Audio must be 5MB or smaller.'],
          },
        };
      }

      final name = audioFileName ?? audioFile.path.split(RegExp(r'[/\\]')).last;
      final form = FormData.fromMap({
        'word_en': wordEn,
        'word_ar': wordAr,
        'audio': await _toMultipart(audioFile, name),
      });

      final response = await wordService.createWord(lessonId, form);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': WordModel.fromJson(_unwrapResource(data)),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to create word'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /api/words/{word}/update
  /// Backend: word_en/word_ar sometimes; audio optional.
  /// Service always updates word_en + word_ar — always send both.
  Future<Map<String, dynamic>> updateWord(
    int wordId, {
    required String wordEn,
    required String wordAr,
    File? audioFile,
    String? audioFileName,
  }) async {
    try {
      final map = <String, dynamic>{'word_en': wordEn, 'word_ar': wordAr};

      if (audioFile != null) {
        final length = await audioFile.length();
        if (length > maxAudioBytes) {
          return {
            'success': false,
            'message': 'Audio must be 5MB or smaller.',
            'errors': {
              'audio': ['Audio must be 5MB or smaller.'],
            },
          };
        }
        final name =
            audioFileName ?? audioFile.path.split(RegExp(r'[/\\]')).last;
        map['audio'] = await _toMultipart(audioFile, name);
      }

      final form = FormData.fromMap(map);
      final response = await wordService.updateWord(wordId, form);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': WordModel.fromJson(_unwrapResource(data)),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to update word'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// DELETE /api/words/{word}/delete
  Future<Map<String, dynamic>> deleteWord(int wordId) async {
    try {
      final response = await wordService.deleteWord(wordId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String message = 'Word deleted successfully';
        if (data is Map) {
          if (data['message'] is String) {
            message = data['message'] as String;
          } else if (data['word'] is String) {
            message = data['word'] as String;
          }
        } else if (data is List && data.isNotEmpty) {
          message = data.first.toString();
        }
        return {'success': true, 'message': message};
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to delete word'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }
}
