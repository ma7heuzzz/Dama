class UserModel {
  final String nickname;
  
  UserModel({required this.nickname});
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
    };
  }
  
  // Método para criar a partir de JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nickname: json['nickname'] as String,
    );
  }
}
