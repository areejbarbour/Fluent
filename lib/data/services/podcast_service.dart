import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class PodcastService {
  final Dio dio;
  PodcastService(this.dio);

  Future<Response> getTopics() async {
    return await dio.get(
      apiPodcastTopics,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getTopicPodcasts(int topicId) async {
    return await dio.get(
      apiTopicPodcasts(topicId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> openPodcast(int podcastId) async {
  return await dio.post(
    apiOpenPodcast(podcastId),
    options: Options(
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );
}

Future<Response> getPodcastDetails(int podcastId) async {
  return await dio.get(
    apiPodcastDetails(podcastId),
    options: Options(
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );
}
}