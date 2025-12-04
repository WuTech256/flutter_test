import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toanvuthinh/screens/change_password_screen.dart';
import 'package:toanvuthinh/screens/location_screen.dart';
import 'package:toanvuthinh/screens/fall_status_screen.dart';
import 'package:toanvuthinh/screens/medication_list_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout() => FirebaseAuth.instance.signOut();

  Widget _feature({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required BuildContext context,
}) {
  final cs = Theme.of(context).colorScheme;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.primaryContainer,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),

          // 🔧 Phần text này là phần mình sửa
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,   // giảm kích thước chữ
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email?.split('@').first ?? 'unknown_user';
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      appBar: AppBar(
        title: const Text('Trang chủ', style: const TextStyle(
              fontSize: 20,   // giảm kích thước chữ
              fontWeight: FontWeight.w600,
            ),),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Xin chào, $username 👋',
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _feature(
                    icon: Icons.health_and_safety,
                    label: 'Theo dõi ngã',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => FallStatusScreen(username: username),
                      ),
                    ),
                    context: context,
                  ),
                  _feature(
                    icon: Icons.location_on,
                    label: 'Xem vị trí',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => LocationScreen(username: username),
                      ),
                    ),
                    context: context,
                  ),
                  _feature(
                    icon: Icons.medication,
                    label: 'Thuốc',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const MedicationListScreen(),
                      ),
                    ),
                    context: context,
                  ),
                  _feature(
                    icon: Icons.password,
                    label: 'Đổi mật khẩu',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const ChangePasswordScreen(),
                      ),
                    ),
                    context: context,
                  ),
                  _feature(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    onTap: _logout,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 20),
          //   child: ElevatedButton(
          //     onPressed: () => NotificationService.showInstantNotification(
          //       title: 'Test',
          //       body: 'Thông báo thử',
          //       id: 1234,
          //     ),
          //     child: const Text('Test notify'),
          //   ),
          // ),
        ],
      ),
    );
  }
}
