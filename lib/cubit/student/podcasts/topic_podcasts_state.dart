import 'package:fluent/data/models/podcast_model.dart';

abstract class TopicPodcastsState {}

class TopicPodcastsInitial extends TopicPodcastsState {}

class TopicPodcastsLoading extends TopicPodcastsState {}

class TopicPodcastsSuccess extends TopicPodcastsState {
  final TopicPodcastsModel data;
  TopicPodcastsSuccess(this.data);
}

class TopicPodcastsFailure extends TopicPodcastsState {
  final String message;
  TopicPodcastsFailure(this.message);
}