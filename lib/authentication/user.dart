import "package:cloud_firestore/cloud_firestore.dart";

class AppUser {
  String? name;
  String? uid;
  String? image;
  String? email;
  String? youtube;
  String? facebook;
  String? x;
  String? instagram;
  final int followers;
  final int following;
  String? bio;

  AppUser({
    this.name,
    this.uid,
    this.image,
    this.youtube,
    this.facebook,
    this.email,
    this.x,
    this.instagram,
    this.followers = 0,
    this.following = 0,
    this.bio,
  });
  Map<String, dynamic> toJson() => {
    "name": name,
    "uid": uid,
    "image": image,
    "youtube": youtube,
    "facebook": facebook,
    "email": email,
    "x": x,
    "instagram": instagram,
    'followers': followers,
    'following': following,
    'bio': bio,
  };

  static AppUser fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    int parseCount(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is List) {
        return value.length;
      } else {
        return 0;
      }
    }

    // String parseString(String field, [String defaultValue = '']) {
    //   return snapshot[field]?.toString() ?? defaultValue;
    // }

    // int parseInt(String field, [int defaultValue = 0]) {
    //   final value = snapshot[field];
    //   if (value is int) return value;
    //   if (value is String) return int.tryParse(value) ?? defaultValue;
    //   return defaultValue;
    // }

    return AppUser(
      name: dataSnapshot["name"],
      uid: dataSnapshot["uid"],
      image: dataSnapshot["image"],
      facebook: dataSnapshot["facebook"],
      email: dataSnapshot["email"],
      x: dataSnapshot["x"],
      youtube: dataSnapshot["youtube"],
      instagram: dataSnapshot["instagram"],
      followers: parseCount(dataSnapshot['followers']),
      following: parseCount(dataSnapshot['following']),
      //followers: dataSnapshot["followers"] ?? 0,
      //following: dataSnapshot["following"] ?? 0,
      // followers: (dataSnapshot['followers'] as List<dynamic>?)?.length ?? 0,
      // following: (dataSnapshot['following'] as List<dynamic>?)?.length ?? 0,
      bio: dataSnapshot["bio"] ?? "",
    );
  }
}
