class Paged<T> {
  Paged({
    required this.items,
    required this.hasMore,
    required this.page,
  });

  List<T> items;
  bool hasMore;
  int page;
}
