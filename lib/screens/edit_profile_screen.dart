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

  File? _avatarFile;
  String? _avatarUrl;
  bool _isPremium = false;
  bool _showFollowers = true;
  bool _loading = false;
  bool _savingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          setState(() {
            _usernameController.text = data['username'] ?? '';
            _avatarUrl = data['avatar'] ?? '';
            _isPremium = data['is_premium'] ?? false;
            _showFollowers = data['showFollowers'] ?? true;
          });
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors du chargement des données');
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (picked != null) {
        final pickedFile = await picker.pickImage(
          source: picked,
          maxWidth: 500,
          maxHeight: 500,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _avatarFile = File(pickedFile.path);
            _savingImage = true;
          });
          await _uploadAvatar();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Nouveau SAS/URL Azure fourni pour l'avatar
        final String blobUrl =
            'https://streamyzstorage.blob.core.windows.net/avatars/$fileName?sp=racwdl&st=2025-08-08T16:26:26Z&se=2025-08-31T00:41:26Z&sv=2024-11-04&sr=c&sig=5G8sR91Zgoj5nS12zmnL573iBCyu2udQmuhlc6c4hyE%3D';

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
          _showSuccessSnackBar('Photo de profil mise à jour');
        } else {
          _showErrorSnackBar('Erreur lors de l\'upload');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'upload');
      } finally {
        setState(() => _savingImage = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final username = _usernameController.text.trim();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'username': username,
              'username_lower': username.toLowerCase(),
              'avatar': _avatarUrl ?? '',
              'is_premium': _isPremium,
              'showFollowers': _showFollowers,
            });

        _showSuccessSnackBar('Profil mis à jour avec succès');
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la mise à jour');
      }
    }

    setState(() => _loading = false);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _loading ? null : _updateProfile,
            child: Text(
              'Enregistrer',
              style: TextStyle(
                color: _loading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Photo de profil
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _avatarFile != null
                                      ? FileImage(_avatarFile!)
                                      : (_avatarUrl != null &&
                                            _avatarUrl!.isNotEmpty)
                                      ? NetworkImage(_avatarUrl!)
                                            as ImageProvider
                                      : null,
                                  child:
                                      _avatarFile == null &&
                                          (_avatarUrl == null ||
                                              _avatarUrl!.isEmpty)
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[400],
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: _savingImage
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                    onPressed: _savingImage
                                        ? null
                                        : _pickAvatar,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appuyez pour changer votre photo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Section Informations personnelles
                    _buildSectionHeader(
                      'Informations personnelles',
                      Icons.person,
                    ),
                    _buildInfoCard([
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Nom d\'utilisateur',
                        hint: '@votre_pseudo',
                        icon: Icons.alternate_email,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom d\'utilisateur est requis';
                          }
                          if (value.trim().length < 3) {
                            return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
                          }
                          if (!RegExp(
                            r'^[a-zA-Z0-9_]+$',
                          ).hasMatch(value.trim())) {
                            return 'Seules les lettres, chiffres et _ sont autorisés';
                          }
                          return null;
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Section Paramètres du compte
                    _buildSectionHeader('Paramètres du compte', Icons.settings),
                    _buildInfoCard([
                      _buildSwitchTile(
                        title: 'Compte Premium',
                        subtitle:
                            'Fonctionnalités avancées et privilèges spéciaux',
                        value: _isPremium,
                        icon: Icons.star,
                        onChanged: (value) =>
                            setState(() => _isPremium = value),
                      ),
                      _buildSwitchTile(
                        title: 'Afficher mes abonnés',
                        subtitle:
                            'Les autres utilisateurs peuvent voir votre liste d\'abonnés',
                        value: _showFollowers,
                        icon: Icons.people,
                        onChanged: (value) =>
                            setState(() => _showFollowers = value),
                      ),
                    ]),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        counterText: maxLength != null ? '' : null,
      ),
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
      contentPadding: EdgeInsets.zero,
    );
  }
}
