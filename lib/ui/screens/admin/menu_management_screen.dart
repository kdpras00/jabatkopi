import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/menu_model.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_logout_button.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<MenuModel> _menus = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchMenus());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenus() async {
    if (_menus.isEmpty) setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('/menus');
      final List<dynamic> data = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _menus = data.map((json) => MenuModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MenuModel> get _filteredMenus {
    if (_searchQuery.isEmpty) return _menus;
    return _menus.where((menu) => 
      menu.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      menu.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showAddEditBottomSheet([MenuModel? menu]) {
    final nameController = TextEditingController(text: menu?.name);
    final priceController = TextEditingController(text: menu?.price.toString());
    final stockController = TextEditingController(text: menu?.stock.toString() ?? '50');
    String selectedCategory = menu?.category ?? 'Coffee'; 
    
    XFile? pickedImage;
    Uint8List? previewBytes;
    bool isUploading = false;

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
                  menu == null ? 'ADD NEW MENU' : 'EDIT MENU ITEM',
                  style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                
                // IMAGE PREVIEW & PICKER
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setModalState(() {
                          pickedImage = image;
                          previewBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.caramelGold.withValues(alpha: 0.3)),
                        image: previewBytes != null 
                          ? DecorationImage(image: MemoryImage(previewBytes!), fit: BoxFit.cover)
                          : (menu != null && menu.imageUrl.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(menu.imageUrl), fit: BoxFit.cover)
                              : null,
                      ),
                      child: (previewBytes == null && (menu == null || menu.imageUrl.isEmpty))
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: AppColors.caramelGold),
                                SizedBox(height: 8),
                                Text('Upload Image', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildTextField('Menu Name', nameController, Icons.coffee),
                const SizedBox(height: 16),
                
                // DROPDOWN KATEGORI
                const Text('Category', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppColors.darkGrey,
                      style: const TextStyle(color: Colors.white),
                      items: [
                        'Coffee', 
                        'Non Coffee', 
                        'Tea', 
                        'Manual Brew', 
                        'Food & Snack',
                        if (!['Coffee', 'Non Coffee', 'Tea', 'Manual Brew', 'Food & Snack'].contains(selectedCategory)) selectedCategory
                      ].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedCategory = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField('Price (IDR)', priceController, Icons.payments, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField('Stock (Qty)', stockController, Icons.inventory, isNumber: true),
                const SizedBox(height: 32),
                
                JkPrimaryButton(
                  label: menu == null ? 'CREATE MENU' : 'UPDATE MENU',
                  isLoading: isUploading,
                  onPressed: () async {
                    setModalState(() => isUploading = true);
                    try {
                      String? base64Image;
                      if (pickedImage != null) {
                        final bytes = await pickedImage!.readAsBytes();
                        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      }

                      final data = {
                        'name': nameController.text,
                        'category': selectedCategory,
                        'price': double.tryParse(priceController.text) ?? 0,
                        'stock': int.tryParse(stockController.text) ?? 0,
                        'description': '-',
                      };
                      
                      if (base64Image != null) {
                        data['image_base64'] = base64Image;
                      } else if (menu != null) {
                        data['image_url'] = menu.imageUrl;
                      }

                      if (menu == null) {
                        await ApiClient().post('/admin/menus', data);
                      } else {
                        await ApiClient().put('/admin/menus/${menu.id}', data);
                      }
                      
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _fetchMenus();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      setModalState(() => isUploading = false);
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
        title: const Text('MENU MANAGEMENT'),
        actions: const [
          JkLogoutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: AppColors.caramelGold,
        child: const Icon(Icons.add, color: AppColors.charcoal),
      ),
      body: _isLoading && _menus.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : Column(
              children: [
                if (_menus.isNotEmpty) _buildStockSummary(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: JkGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari menu atau kategori...',
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
                  child: _filteredMenus.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredMenus.length,
                            itemBuilder: (context, index) {
                              final menu = _filteredMenus[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: JkGlassCard(
                                  padding: const EdgeInsets.all(8),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(menu.imageUrl.isNotEmpty ? menu.imageUrl : 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=100'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        if (menu.stock < 10)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: menu.stock == 0 ? Colors.red.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: menu.stock == 0 ? Colors.red : Colors.orange, width: 0.5),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  menu.stock == 0 ? Icons.error_outline : Icons.warning_amber_rounded,
                                                  size: 12,
                                                  color: menu.stock == 0 ? Colors.red : Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  menu.stock == 0 ? 'HABIS' : 'STOK RENDAH',
                                                  style: TextStyle(
                                                    color: menu.stock == 0 ? Colors.red : Colors.orange,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${menu.category} • Stok: ${menu.stock}', 
                                      style: TextStyle(
                                        color: menu.stock < 10 ? (menu.stock == 0 ? Colors.redAccent : Colors.orangeAccent) : Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: AppColors.caramelGold),
                                          onPressed: () => _showAddEditBottomSheet(menu),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _showDeleteConfirm(menu),
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

  Widget _buildStockSummary() {
    final outOfStockCount = _menus.where((m) => m.stock == 0).length;
    final lowStockCount = _menus.where((m) => m.stock > 0 && m.stock < 10).length;

    if (outOfStockCount == 0 && lowStockCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: JkGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.caramelGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Stok', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (outOfStockCount > 0) ...[
                        Text('$outOfStockCount Habis', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        const SizedBox(width: 12),
                      ],
                      if (lowStockCount > 0)
                        Text('$lowStockCount Stok Rendah', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            child: Icon(Icons.restaurant_menu, size: 80, color: AppColors.caramelGold.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text('No Menu Items Yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Start adding your premium coffee collection.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDeleteConfirm(MenuModel menu) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete ${menu.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ApiClient().delete('/admin/menus/${menu.id}');
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) _fetchMenus();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
