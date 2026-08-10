class PodcastTopicModel {
  final int id;
  final String name;
  final String? imageUrl;

  PodcastTopicModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory PodcastTopicModel.fromJson(Map<String, dynamic> json) {
    return PodcastTopicModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}

class PodcastItemModel {
  final int id;
  final String name;
  final int pointRequired;

  PodcastItemModel({
    required this.id,
    required this.name,
    required this.pointRequired,
  });

  factory PodcastItemModel.fromJson(Map<String, dynamic> json) {
    return PodcastItemModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      pointRequired: json['point_required'] ?? 0,
    );
  }
}

class TopicPodcastsModel {
  final int totalPodcasts;
  final int openedCount;
  final List<PodcastItemModel> openedPodcasts;
  final List<PodcastItemModel> lockedPodcasts;

  TopicPodcastsModel({
    required this.totalPodcasts,
    required this.openedCount,
    required this.openedPodcasts,
    required this.lockedPodcasts,
  });

  factory TopicPodcastsModel.fromJson(Map<String, dynamic> json) {
    List<PodcastItemModel> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => PodcastItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return TopicPodcastsModel(
      totalPodcasts: json['total_podcasts'] ?? 0,
      openedCount: json['opened_count'] ?? 0,
      openedPodcasts: parseList(json['opened_podcasts']),
      lockedPodcasts: parseList(json['locked_podcasts']),
    );
  }
}

class OpenPodcastResult {
  final String message;
  final int remainingPoints;

  OpenPodcastResult({
    required this.message,
    required this.remainingPoints,
  });

  factory OpenPodcastResult.fromJson(Map<String, dynamic> json) {
    return OpenPodcastResult(
      message: json['message']?.toString() ?? 'Podcast opened successfully',
      remainingPoints: json['remaining_points'] is int
          ? json['remaining_points'] as int
          : int.tryParse('${json['remaining_points']}') ?? 0,
    );
  }
}

class PodcastDetailModel {
  final int id;
  final int topicId;
  final String name;
  final int pointRequired;
  final String? videoUrl;

  PodcastDetailModel({
    required this.id,
    required this.topicId,
    required this.name,
    required this.pointRequired,
    this.videoUrl,
  });

  factory PodcastDetailModel.fromJson(Map<String, dynamic> json) {
    return PodcastDetailModel(
      id: json['id'] ?? 0,
      topicId: json['topic_id'] ?? 0,
      name: json['name']?.toString() ?? '',
      pointRequired: json['point_required'] ?? 0,
      videoUrl: json['video_url']?.toString(),
    );
  }

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;
}