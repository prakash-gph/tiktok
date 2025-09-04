import "package:cloud_firestore/cloud_firestore.dart";

class User {
  String? name;
  String? uid;
  String? image;
  String? email;
  String? youtube;
  String? facebook;
  String? x;
  String? instagram;

  User({
    this.name,
    this.uid,
    this.image,
    this.youtube,
    this.facebook,
    this.email,
    this.x,
    this.instagram,
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
  };

  static User fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return User(
      name: dataSnapshot["name"],
      uid: dataSnapshot["uid"],
      image: dataSnapshot["image"],
      facebook: dataSnapshot["facebook"],
      email: dataSnapshot["email"],
      x: dataSnapshot["x"],
      youtube: dataSnapshot["youtube"],
      instagram: dataSnapshot["instagram"],
    );
  }
}
