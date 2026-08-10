import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'podcast_topics_state.dart';

class PodcastTopicsCubit extends Cubit<PodcastTopicsState> {
  final PodcastRepository repository;

  PodcastTopicsCubit(this.repository) : super(PodcastTopicsInitial());

  Future<void> fetchTopics() async {
    emit(PodcastTopicsLoading());
    print(" [PodcastTopicsCubit] Fetching topics...");

    final result = await repository.getTopics();

    if (result['success'] == true) {
      print(" [PodcastTopicsCubit] Topics loaded");
      emit(PodcastTopicsSuccess(result['data']));
    } else {
      print(" [PodcastTopicsCubit] Failed: ${result['message']}");
      emit(PodcastTopicsFailure(result['message'] ?? 'Failed to load topics'));
    }
  }
}