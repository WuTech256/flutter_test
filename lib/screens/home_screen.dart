import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toanvuthinh/screens/change_password_screen.dart';
import 'package:toanvuthinh/screens/location_screen.dart';
import 'package:toanvuthinh/screens/fall_status_screen.dart';
import 'package:toanvuthinh/screens/medication_list_screen.dart';
import '../services/notification_service.dart'; // ✅ Import
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout() {
    FirebaseAuth.instance.signOut();
  }

  Widget _buildFeature({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
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
            Icon(icon, color: colorScheme.onPrimaryContainer, size: 42),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
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
    final username = user?.email?.split('@').first ?? "unknown_user";
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Xin chào, $username 👋',
            style: TextStyle(
              color: colorScheme.onPrimary,
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
                  _buildFeature(
                    icon: Icons.health_and_safety,
                    label: 'Theo dõi ngã',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => FallStatusScreen(username: username),
                        ),
                      );
                    },
                    context: context,
                  ),
                  _buildFeature(
                    icon: Icons.location_on,
                    label: 'Xem vị trí',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) =>
                              LocationScreen(username: username),
                        ),
                      );
                    },
                    context: context,
                  ),
                  _buildFeature(
                    icon: Icons.medication,
                    label: 'Thuoc',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) =>
                              MedicationListScreen(),
                        ),
                      );
                    },
                    context: context,
                  ),
                  _buildFeature(
                    icon: Icons.password,
                    label: 'Đổi mật khẩu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    context: context,
                  ),
                  _buildFeature(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    onTap: _logout,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
          onPressed: () => NotificationService.showInstantNotification(
            title: '⚠️ Cảnh báo ngã lần',
            body: 'vẫn đang trong trạng thái ngã!',
          ),
          child: const Text('Test alarm 10s'),
        )
        ],
      ),
    );
  }
}
