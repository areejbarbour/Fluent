import 'package:dio/dio.dart';
import 'package:fluent/data/models/podcast_model.dart';
import 'package:fluent/data/services/podcast_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class PodcastRepository {
  final PodcastService service;
  PodcastRepository(this.service);

  static const _keys = ['message', 'error', 'data'];

  Future<Map<String, dynamic>> getTopics() async {
    try {
      final response = await service.getTopics();
      print("✅ GetPodcastTopics Status: ${response.statusCode}");
      print("✅ GetPodcastTopics Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<PodcastTopicModel> list = [];

        if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .whereType<Map>()
              .map((e) =>
                  PodcastTopicModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map((e) =>
                  PodcastTopicModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        return {'success': true, 'data': list};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to load topics',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetPodcastTopics DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load topics',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetPodcastTopics Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getTopicPodcasts(int topicId) async {
    try {
      final response = await service.getTopicPodcasts(topicId);
      print("✅ GetTopicPodcasts Status: ${response.statusCode}");
      print("✅ GetTopicPodcasts Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          return {
            'success': true,
            'data': TopicPodcastsModel.fromJson(
              Map<String, dynamic>.from(data),
            ),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to load podcasts',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetTopicPodcasts DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load podcasts',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetTopicPodcasts Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> openPodcast(int podcastId) async {
  try {
    final response = await service.openPodcast(podcastId);
    print("✅ OpenPodcast Status: ${response.statusCode}");
    print("✅ OpenPodcast Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map) {
        return {
          'success': true,
          'data': OpenPodcastResult.fromJson(
            Map<String, dynamic>.from(data),
          ),
        };
      }
      return {
        'success': true,
        'data': OpenPodcastResult(
          message: 'Podcast opened successfully',
          remainingPoints: 0,
        ),
      };
    }

    return ApiErrorHelper.failure(
      response.data,
      'Failed to open podcast',
      preferredKeys: _keys,
    );
  } on DioException catch (e) {
    print("❌ OpenPodcast DioException: ${e.response?.data}");
    return ApiErrorHelper.fromDio(
      e,
      'Failed to open podcast',
      preferredKeys: _keys,
    );
  } catch (e) {
    print("❌ OpenPodcast Unexpected: $e");
    return {'success': false, 'message': 'An unexpected error occurred'};
  }
}

Future<Map<String, dynamic>> getPodcastDetails(int podcastId) async {
  try {
    final response = await service.getPodcastDetails(podcastId);
    print("✅ GetPodcastDetails Status: ${response.statusCode}");
    print("✅ GetPodcastDetails Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      Map<String, dynamic>? payload;

      if (data is Map && data['data'] is Map) {
        payload = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data is Map) {
        payload = Map<String, dynamic>.from(data);
      }

      if (payload != null) {
        return {
          'success': true,
          'data': PodcastDetailModel.fromJson(payload),
        };
      }
      return {'success': false, 'message': 'Unexpected response format'};
    }

    return ApiErrorHelper.failure(
      response.data,
      'Failed to load podcast details',
      preferredKeys: _keys,
    );
  } on DioException catch (e) {
    print("❌ GetPodcastDetails DioException: ${e.response?.data}");
    return ApiErrorHelper.fromDio(
      e,
      'Failed to load podcast details',
      preferredKeys: _keys,
    );
  } catch (e) {
    print("❌ GetPodcastDetails Unexpected: $e");
    return {'success': false, 'message': 'An unexpected error occurred'};
  }
}
}