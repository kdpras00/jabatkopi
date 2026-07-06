import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_logout_button.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  List<dynamic> _users = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchUsers());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (_users.isEmpty) setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('/admin/users');
      if (mounted) {
        setState(() {
          _users = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final username = (user['username'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || username.contains(query) || role.contains(query);
    }).toList();
  }

  void _showAddEditUserBottomSheet([dynamic user]) {
    final nameController = TextEditingController(text: user?['name']);
    final usernameController = TextEditingController(text: user?['username']);
    final emailController = TextEditingController(text: user?['email']);
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'pegawai';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user == null ? 'CREATE NEW ACCOUNT' : 'EDIT ACCOUNT',
                  style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                _buildTextField('Full Name', nameController, Icons.badge),
                const SizedBox(height: 16),
                _buildTextField('Username', usernameController, Icons.person),
                const SizedBox(height: 16),
                _buildTextField('Email Address', emailController, Icons.email),
                if (user == null) ...[
                  const SizedBox(height: 16),
                  _buildTextField('Password', passwordController, Icons.lock, isPassword: true),
                ],
                const SizedBox(height: 16),
                const Text('User Role', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      dropdownColor: AppColors.darkGrey,
                      style: const TextStyle(color: Colors.white),
                      items: ['admin', 'pegawai', 'customer'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedRole = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                JkPrimaryButton(
                  label: user == null ? 'CREATE ACCOUNT' : 'UPDATE ACCOUNT',
                  onPressed: () async {
                    try {
                      final data = {
                        'name': nameController.text,
                        'username': usernameController.text,
                        'email': emailController.text,
                        'role': selectedRole,
                      };
                      if (user == null) {
                        data['password'] = passwordController.text;
                        await ApiClient().post('/admin/users', data);
                      } else {
                        await ApiClient().put('/admin/users/${user['id']}', data);
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _fetchUsers();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.caramelGold, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACCOUNT MANAGEMENT'),
        actions: const [
          JkLogoutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserBottomSheet(),
        backgroundColor: AppColors.caramelGold,
        child: const Icon(Icons.person_add, color: AppColors.charcoal),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: JkGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, username, atau role...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: AppColors.caramelGold),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: JkGlassCard(
                                padding: const EdgeInsets.all(12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user['role'] == 'admin' ? Colors.red : AppColors.caramelGold,
                                    child: const Icon(Icons.person, color: AppColors.charcoal),
                                  ),
                                  title: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${user['username']} - ${user['role'].toString().toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () => _showAddEditUserBottomSheet(user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _showDeleteConfirm(user),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.people_outline, size: 80, color: AppColors.caramelGold.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text('No Accounts Found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add staff or admin accounts to manage the system.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDeleteConfirm(dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to delete ${user['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ApiClient().delete('/admin/users/${user['id']}');
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) _fetchUsers();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
