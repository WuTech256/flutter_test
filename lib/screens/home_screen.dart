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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.onPrimaryContainer, size: 42),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
        title: const Text('Trang chủ'),
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
              fontSize: 20,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed: () => NotificationService.showInstantNotification(
                title: 'Test',
                body: 'Thông báo thử',
                id: 1234,
              ),
              child: const Text('Test notify'),
            ),
          ),
        ],
      ),
    );
  }
}
