import 'package:fluent/data/models/podcast_model.dart';

abstract class OpenPodcastState {}

class OpenPodcastInitial extends OpenPodcastState {}

class OpenPodcastLoading extends OpenPodcastState {
  final int podcastId;
  OpenPodcastLoading(this.podcastId);
}

class OpenPodcastSuccess extends OpenPodcastState {
  final OpenPodcastResult result;
  final int podcastId;
  OpenPodcastSuccess({required this.result, required this.podcastId});
}

class OpenPodcastFailure extends OpenPodcastState {
  final String message;
  OpenPodcastFailure(this.message);
}