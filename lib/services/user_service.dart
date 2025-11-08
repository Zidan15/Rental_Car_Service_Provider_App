import 'package:fleetwise/models/user.dart';

class UserService {
  static User getMockUser() {
    final now = DateTime.now();
    
    return User(
      id: '1',
      name: 'Zidan Shaikh',
      company: 'RENT.GOA Admin',
      contactNumber: '+91 1111111111',
      email: 'zs@rentgoa.com',
      createdAt: now.subtract(const Duration(days: 180)),
      updatedAt: now,
    );
  }
}
