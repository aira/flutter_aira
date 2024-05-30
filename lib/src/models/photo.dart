/// A shared photo.
class Photo {
  Photo({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    required this.thumbnailUrl,
    required this.createdDate,
  });

  /// Creates a [Photo] from a JSON object.
  Photo.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          title: json['title'] ?? '',
          description: json['description'],
          url: json['url'],
          thumbnailUrl: json['thumbnailUrl'],
          createdDate: DateTime.fromMillisecondsSinceEpoch(json['createdDate']),
        );

  /// Unique Id of the Photo.
  final int id;

  /// Title attributed by the agent taking the picture.
  final String title;

  /// Description attributed by the agent taking the picture.
  final String? description;

  /// URL where to access to the photo.
  final String url;

  /// URL where to access the thumbnail of the photo.
  final String thumbnailUrl;

  /// Creation Date.
  final DateTime createdDate;
}
