import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final goalController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final user = auth.user;

    nameController.text = user?.displayName ?? '';
    goalController.text = user?.goal ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(labelText: "Learning Goal"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Gọi repository để cập nhật Firestore
                await auth.updateProfile(
                  nameController.text,
                  goalController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Profile updated successfully")));
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
