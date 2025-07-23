import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPremium = false;
  bool _showFollowers = true;
  bool _isPrivate = false;
  bool _notificationsEnabled = true;
  File? _avatarFile;
  String? _avatarUrl;
  bool _loading = false;
  List<String> _following = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _emailController.text = user.email ?? '';
          _isPremium = data['is_premium'] ?? false;
          _showFollowers = data['showFollowers'] ?? true;
          _isPrivate = data['is_private'] ?? false;
          _notificationsEnabled = data['notifications_enabled'] ?? true;
          _avatarUrl = data['avatar'] ?? '';
          _following = List<String>.from(data['following'] ?? []);
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
      // Upload avatar to Azure Blob Storage and get URL
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Use the provided SAS URL for the container
        final String containerSasUrl =
            'https://streamyzstorage.blob.core.windows.net/avatars?sp=racwdl&st=2025-07-23T18:57:22Z&se=2025-08-31T03:12:22Z&sv=2024-11-04&sr=c&sig=nAg9CyVBDE%2FHdASserKMhdO2g%2B9iPeAPuGv%2BSphyfss%3D';
        final String blobUrl = containerSasUrl.replaceFirst(
          '?sp=',
          '/$fileName?sp=',
        );
        try {
          final bytes = await _avatarFile!.readAsBytes();
          final request = await HttpClient().putUrl(Uri.parse(blobUrl));
          request.headers.set('x-ms-blob-type', 'BlockBlob');
          request.headers.set('Content-Type', 'image/jpeg');
          request.add(bytes);
          final httpResponse = await request.close();
          if (httpResponse.statusCode == 201) {
            setState(() {
              _avatarUrl =
                  'https://streamyzstorage.blob.core.windows.net/avatars/$fileName';
            });
          } else {
            debugPrint('Erreur upload Azure: ${httpResponse.statusCode}');
          }
        } catch (e) {
          debugPrint('Erreur upload Azure: $e');
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    String avatarUrl = _avatarUrl ?? '';
    if (user != null) {
      // Update email
      if (_emailController.text.trim() != user.email) {
        await user.updateEmail(_emailController.text.trim());
      }
      // Update password
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }
      // Upload avatar if changed
      if (_avatarFile != null) {
        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String blobUrl =
            'https://streamyzstorage.blob.core.windows.net/avatars/$fileName?sp=racwdl&st=2025-07-23T18:57:22Z&se=2025-08-31T03:12:22Z&sv=2024-11-04&sr=c&sig=nAg9CyVBDE%2FHdASserKMhdO2g%2B9iPeAPuGv%2BSphyfss%3D';
        try {
          final bytes = await _avatarFile!.readAsBytes();
          final request = await HttpClient().putUrl(Uri.parse(blobUrl));
          request.headers.set('x-ms-blob-type', 'BlockBlob');
          request.headers.set('Content-Type', 'image/jpeg');
          request.add(bytes);
          final httpResponse = await request.close();
          if (httpResponse.statusCode == 201) {
            avatarUrl =
                'https://streamyzstorage.blob.core.windows.net/avatars/$fileName';
          } else {
            debugPrint('Erreur upload Azure: ${httpResponse.statusCode}');
          }
        } catch (e) {
          debugPrint('Erreur upload Azure: $e');
        }
      }
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': _usernameController.text.trim(),
            'bio': _bioController.text.trim(),
            'avatar': avatarUrl,
            'is_premium': _isPremium,
            'showFollowers': _showFollowers,
            'is_private': _isPrivate,
            'notifications_enabled': _notificationsEnabled,
            'following': _following,
          });
      if (mounted) Navigator.pop(context);
    }
    setState(() => _loading = false);
  }

  void _addFollowing(String uid) {
    setState(() {
      if (!_following.contains(uid)) _following.add(uid);
    });
  }

  void _removeFollowing(String uid) {
    setState(() {
      _following.remove(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? NetworkImage(_avatarUrl!) as ImageProvider
                            : null,
                        child:
                            _avatarFile == null &&
                                (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Mode premium'),
                      value: _isPremium,
                      onChanged: (val) => setState(() => _isPremium = val),
                    ),
                    SwitchListTile(
                      title: const Text('Afficher mes followers'),
                      value: _showFollowers,
                      onChanged: (val) => setState(() => _showFollowers = val),
                    ),
                    SwitchListTile(
                      title: const Text('Profil privé'),
                      value: _isPrivate,
                      onChanged: (val) => setState(() => _isPrivate = val),
                    ),
                    SwitchListTile(
                      title: const Text('Notifications activées'),
                      value: _notificationsEnabled,
                      onChanged: (val) =>
                          setState(() => _notificationsEnabled = val),
                    ),
                    const SizedBox(height: 16),
                    const Text('Abonnements (UIDs):'),
                    Wrap(
                      spacing: 8,
                      children: _following
                          .map(
                            (uid) => Chip(
                              label: Text(uid),
                              onDeleted: () => _removeFollowing(uid),
                            ),
                          )
                          .toList(),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Ajouter un abonnement (UID)',
                      ),
                      onFieldSubmitted: (uid) => _addFollowing(uid.trim()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _updateProfile,
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
