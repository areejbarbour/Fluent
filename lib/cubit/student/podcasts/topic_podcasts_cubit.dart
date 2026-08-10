import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'topic_podcasts_state.dart';

class TopicPodcastsCubit extends Cubit<TopicPodcastsState> {
  final PodcastRepository repository;

  TopicPodcastsCubit(this.repository) : super(TopicPodcastsInitial());

  Future<void> fetchTopicPodcasts(int topicId) async {
    emit(TopicPodcastsLoading());
    print(" [TopicPodcastsCubit] Fetching podcasts for topic #$topicId...");

    final result = await repository.getTopicPodcasts(topicId);

    if (result['success'] == true) {
      print(" [TopicPodcastsCubit] Podcasts loaded");
      emit(TopicPodcastsSuccess(result['data']));
    } else {
      print(" [TopicPodcastsCubit] Failed: ${result['message']}");
      emit(TopicPodcastsFailure(
        result['message'] ?? 'Failed to load podcasts',
      ));
    }
  }
}