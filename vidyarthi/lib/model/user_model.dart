class UserModel {
  String? uid;
  String? email;
  String? Name;
  String? phoneNumber;
  String? idNumber;

  UserModel({this.uid, this.email, this.Name, this.phoneNumber, this.idNumber});

  // Receiving data from server
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      Name: map['name'],
      phoneNumber: map['phoneNumber'],
      idNumber: map['idNumber'],
    );
  }


  // Sending data to our server
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': Name,
      'phoneNumber': phoneNumber,
      'idNumber': idNumber,
    };
  }
}
