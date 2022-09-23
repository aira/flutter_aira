
/// Model containing all the information about a Gallery Photo.
class GalleryPhoto {
  GalleryPhoto({
    required this.id,
    required this.title,
    this.description,
    List<String>? categories,
    required this.url,
    required this.thumbnailUrl,
    this.createdDate,
    required this.modifiedDate,
  }): categories = categories ?? [];

  /// Unique Id of the Photo.
  final int id;

  /// Title attributed by the agent taking the picture.
  final String title;

  /// Description attributed by the agent taking the picture.
  final String? description;

  /// Type of Photo (SNAPSHOT, PROFILE PICTURE, etc.)
  final List<String> categories;

  /// URL where to access to the photo.
  final String url;

  /// URL where to access the thumbnail of the photo.
  final String thumbnailUrl;

  /// Creation Date.
  final DateTime? createdDate;

  /// modified Date.
  final DateTime modifiedDate;

  /// Creates a GalleryPhoto from a JSON object
  static GalleryPhoto fromJSON(Map<String, dynamic> json) {
    return GalleryPhoto(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      categories: json['categories'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
      createdDate: DateTime.fromMillisecondsSinceEpoch(json['createdDate']),
      modifiedDate: DateTime.fromMillisecondsSinceEpoch(json['modifiedDate']),
    );
  }
}