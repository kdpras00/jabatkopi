import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';

import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _imageUrl;
  XFile? _pickedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient().get('/profile');
      final data = res['data'];
      setState(() {
        _nameController.text = data['name'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _emailController.text = data['email'] ?? '';
        _imageUrl = data['image_url'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Kecilkan quality untuk base64
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String base64Image = _imageUrl ?? '';
      
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64.encode(bytes)}';
      }

      await ApiClient().put('/profile', {
        'name': _nameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'image_url': base64Image,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Balikkan true untuk refresh
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.darkGrey,
                          backgroundImage: _pickedImage != null 
                            ? (kIsWeb ? NetworkImage(_pickedImage!.path) : FileImage(File(_pickedImage!.path)) as ImageProvider)
                            : _getSafeImageProvider(_imageUrl),
                          child: (_pickedImage == null && (_imageUrl == null || _imageUrl!.isEmpty || _getSafeImageProvider(_imageUrl) == null))
                            ? const Icon(Icons.person, size: 50, color: AppColors.caramelGold)
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppColors.caramelGold, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 18, color: AppColors.charcoal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  JkGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField('Full Name', _nameController),
                        const SizedBox(height: 16),
                        _buildTextField('Username', _usernameController),
                        const SizedBox(height: 16),
                        _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  JkPrimaryButton(
                    label: 'SAVE CHANGES',
                    onPressed: _updateProfile,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.caramelGold, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}

ImageProvider? _getSafeImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:image')) {
    try {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      return null;
    }
  }
  return NetworkImage(url);
}
