
import 'package:flutter_aira/src/models/gallery_photo.dart';

class GalleryPhotoAggregator {
  GalleryPhotoAggregator() : nextPage = 0, _hasMore = true, photos = [];

  int nextPage;
  bool _hasMore;
  final List<GalleryPhoto> photos;

  bool get hasMore => _hasMore;

  void addPage(bool hasMore, List<GalleryPhoto> lastPage) {
    photos.addAll(lastPage);
    nextPage ++;
    _hasMore = hasMore;
  }
}