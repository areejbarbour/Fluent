import 'package:fluent/data/models/podcast_model.dart';

abstract class PodcastDetailState {}

class PodcastDetailInitial extends PodcastDetailState {}

class PodcastDetailLoading extends PodcastDetailState {}

class PodcastDetailSuccess extends PodcastDetailState {
  final PodcastDetailModel data;
  PodcastDetailSuccess(this.data);
}

class PodcastDetailFailure extends PodcastDetailState {
  final String message;
  PodcastDetailFailure(this.message);
}