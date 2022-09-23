
import 'package:flutter_aira/src/models/gallery_photo.dart';

class GalleryPhotoAggregator {
  GalleryPhotoAggregator() : nextPage = 0, _hasMore = true, photos = [];

  int nextPage;
  bool _hasMore;
  final List<GalleryPhoto> photos;

  bool get hasMore => _hasMore;
  // List<GalleryPhoto> get photos => _photos.values.expand((list) => list).toList(growable: false);

  void addPage(bool hasMore, List<GalleryPhoto> lastPage) {
    print('<<<<<<<<<< adding a page in GalleryPhotoAggregator');
    photos.addAll(lastPage);
    nextPage ++;
    _hasMore = hasMore;
  }
}