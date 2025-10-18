class SocialMediaModel {
  final String name;
  final String img;
  final String accountName;

  const SocialMediaModel({
    required this.name,
    required this.img,
    required this.accountName,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'img': img,
      'accountName': accountName,
    };
  }

  factory SocialMediaModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaModel(
      name: json['name'],
      img: json['img'],
      accountName: json['accountName'],
    );
  }
}

// List of available social media platforms
final List<SocialMediaModel> availableSocialMedia = [
  const SocialMediaModel(
    name: 'YouTube',
    img:
        'https://firebasestorage.googleapis.com/v0/b/spread-lee-xf1i5z.appspot.com/o/youtube.png?alt=media&token=e9d622d8-27a8-4b2c-adf4-8c05f88d1a8f',
    accountName: '',
  ),
  const SocialMediaModel(
    name: 'Facebook',
    img:
        'https://firebasestorage.googleapis.com/v0/b/spread-lee-xf1i5z.appspot.com/o/Facebook.png?alt=media&token=1c63244b-1efd-4cb3-a477-b98560eb9fa9',
    accountName: '',
  ),
  const SocialMediaModel(
    name: 'Twitter',
    img:
        'https://firebasestorage.googleapis.com/v0/b/spread-lee-xf1i5z.appspot.com/o/twitter.png?alt=media&token=58b573c7-10c5-4c6d-a8f2-b5b6da0a5392',
    accountName: '',
  ),
  const SocialMediaModel(
    name: 'Snapchat',
    img:
        'https://firebasestorage.googleapis.com/v0/b/spread-lee-xf1i5z.appspot.com/o/snapchat.png?alt=media&token=b962500a-d263-467d-ad9e-8558439cd587',
    accountName: '',
  ),
  const SocialMediaModel(
    name: 'TikTok',
    img:
        'https://firebasestorage.googleapis.com/v0/b/spread-lee-xf1i5z.appspot.com/o/tiktok.png?alt=media&token=0a274341-d524-4396-b8d7-ebbd0c984927',
    accountName: '',
  ),
  const SocialMediaModel(
    name: 'Other',
    img:
        'https://firebasestorage.googleapis.com/v0/b/spread-lee-xf1i5z.appspot.com/o/Avatar.png?alt=media&token=6f77407d-eebd-4d73-9697-2ce3c5499a23',
    accountName: '',
  ),
];
