import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'podcast_detail_state.dart';

class PodcastDetailCubit extends Cubit<PodcastDetailState> {
  final PodcastRepository repository;

  PodcastDetailCubit(this.repository) : super(PodcastDetailInitial());

  Future<void> fetchDetails(int podcastId) async {
    emit(PodcastDetailLoading());
    print(" [PodcastDetailCubit] Fetching podcast #$podcastId...");

    final result = await repository.getPodcastDetails(podcastId);

    if (result['success'] == true) {
      print(" [PodcastDetailCubit] Details loaded");
      emit(PodcastDetailSuccess(result['data']));
    } else {
      print(" [PodcastDetailCubit] Failed: ${result['message']}");
      emit(PodcastDetailFailure(
        result['message'] ?? 'Failed to load podcast details',
      ));
    }
  }
}