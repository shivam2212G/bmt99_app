class FeatureBrandModel {
  final int featureBrandId;
  final String featureBrandName;
  final String featureBrandImage;
  final bool isActive;

  FeatureBrandModel({
    required this.featureBrandId,
    required this.featureBrandName,
    required this.featureBrandImage,
    required this.isActive,
  });

  factory FeatureBrandModel.fromJson(Map<String, dynamic> json) {
    return FeatureBrandModel(
      featureBrandId: json['feature_brand_id'] ?? 0,
      featureBrandName: json['feature_brand_name'] ?? "",
      featureBrandImage: json['feature_brand_image'] ?? "",
      isActive: json['is_active'] == 1,
    );
  }
}


