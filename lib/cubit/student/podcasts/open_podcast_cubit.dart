import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'open_podcast_state.dart';

class OpenPodcastCubit extends Cubit<OpenPodcastState> {
  final PodcastRepository repository;

  OpenPodcastCubit(this.repository) : super(OpenPodcastInitial());

  Future<void> openPodcast(int podcastId) async {
    emit(OpenPodcastLoading(podcastId));
    print(" [OpenPodcastCubit] Opening podcast #$podcastId...");

    final result = await repository.openPodcast(podcastId);

    if (result['success'] == true) {
      print(" [OpenPodcastCubit] Podcast opened");
      emit(OpenPodcastSuccess(
        result: result['data'],
        podcastId: podcastId,
      ));
    } else {
      print(" [OpenPodcastCubit] Failed: ${result['message']}");
      emit(OpenPodcastFailure(
        result['message'] ?? 'Failed to open podcast',
      ));
    }
  }

  void reset() => emit(OpenPodcastInitial());
}