// API Response Models
class ReviewsResponse {
  final bool success;
  final double averageRating;
  final List<ReviewModel> reviews;

  ReviewsResponse({
    required this.success,
    required this.averageRating,
    required this.reviews,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ReviewsResponse(
      success: json['success'] as bool,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviews: (json['reviews'] as List)
          .map((item) => ReviewModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'averageRating': averageRating,
      'reviews': reviews.map((x) => x.toJson()).toList(),
    };
  }
}

class ReviewModel {
  final String id;
  final String description;
  final int rating;
  final String title;

  ReviewModel({
    required this.id,
    required this.description,
    required this.rating,
    required this.title,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      rating: json['rating'] ?? 0,
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'description': description,
      'rating': rating,
      'title': title,
    };
  }
}
