class Review {
  final String id;
  final String userName;
  final String userAvatar;
  final String bookId;
  final double rating;
  final String review;
  final String createdAt;
  final String updatedAt;

  Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.bookId,
    required this.rating,
    required this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'],
      userName: json['user']['fullName'],
      userAvatar: json['user']['profilePicture'],
      bookId: json['book'],
      rating: json['rating'].toDouble(),
      review: json['review'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}
