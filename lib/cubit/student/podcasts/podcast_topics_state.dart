import 'package:fluent/data/models/podcast_model.dart';

abstract class PodcastTopicsState {}

class PodcastTopicsInitial extends PodcastTopicsState {}

class PodcastTopicsLoading extends PodcastTopicsState {}

class PodcastTopicsSuccess extends PodcastTopicsState {
  final List<PodcastTopicModel> topics;
  PodcastTopicsSuccess(this.topics);
}

class PodcastTopicsFailure extends PodcastTopicsState {
  final String message;
  PodcastTopicsFailure(this.message);
}