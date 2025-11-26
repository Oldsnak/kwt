import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/core/models/product_model.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';

class RemoveItemsPage extends StatefulWidget {
  const RemoveItemsPage({super.key});

  @override
  State<RemoveItemsPage> createState() => _RemoveItemsPageState();
}

class _RemoveItemsPageState extends State<RemoveItemsPage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _deleting = false;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  final Set<String> _selectedIds = {};

  List<Product> _lastDeleted = [];

  static const String _adminPin = "1234";

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD ONLY ACTIVE PRODUCTS
  // ---------------------------------------------------------------------------
  Future<void> _loadProducts() async {
    try {
      setState(() => _loading = true);

      final response = await _client
          .from('products')
          .select('''
            id, name, purchase_rate, selling_rate, stock_quantity, is_active, barcode, created_at,
            categories(name)
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map<Product>((row) {
        return Product.fromMap({
          ...row,
          'category_name': row['categories']?['name'],
        });
      }).toList();

      setState(() {
        _allProducts = list;
        _filteredProducts = List<Product>.from(list);
        _selectedIds.clear();
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to load products: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH FILTER
  // ---------------------------------------------------------------------------
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredProducts = List<Product>.from(_allProducts));
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final name = p.name.toLowerCase();
        final barcode = p.barcode.toLowerCase();
        final category = (p.categoryName ?? '').toLowerCase();
        return name.contains(q) ||
            barcode.contains(q) ||
            category.contains(q);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // SELECT / UNSELECT
  // ---------------------------------------------------------------------------
  void _toggleSelection(String? id) {
    if (id == null) return;
    setState(() {
      _selectedIds.contains(id)
          ? _selectedIds.remove(id)
          : _selectedIds.add(id);
    });
  }

  bool get _allVisibleSelected =>
      _filteredProducts.isNotEmpty &&
          _filteredProducts
              .where((p) => p.id != null)
              .every((p) => _selectedIds.contains(p.id));

  void _toggleSelectAllVisible() {
    setState(() {
      if (_allVisibleSelected) {
        for (final p in _filteredProducts) {
          if (p.id != null) _selectedIds.remove(p.id);
        }
      } else {
        for (final p in _filteredProducts) {
          if (p.id != null) _selectedIds.add(p.id!);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // ADMIN PIN DIALOG
  // ---------------------------------------------------------------------------
  Future<bool> _askAdminPin() async {
    final pinCtrl = TextEditingController();
    bool approved = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dark = SHelperFunctions.isDarkMode(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: dark ? const Color(0xFF2A2A2A) : Colors.white,
          title: Row(
            children: const [
              Icon(Icons.lock, color: SColors.primary),
              SizedBox(width: 8),
              Text("Admin Confirmation"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter 4-digit admin PIN to delete selected items."),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: "Admin PIN",
                  prefixIcon: Icon(Icons.password),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (pinCtrl.text == _adminPin) {
                  approved = true;
                  Navigator.of(ctx).pop();
                } else {
                  Get.snackbar("Invalid PIN", "Admin PIN is incorrect.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SColors.primary,
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    return approved;
  }

  // ---------------------------------------------------------------------------
  // CONFIRM DIALOG
  // ---------------------------------------------------------------------------
  Future<bool> _confirmDeleteDialog(int count) async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final dark = SHelperFunctions.isDarkMode(ctx);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)]
                    : [Colors.white, Colors.grey.shade100],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(
                  "Delete $count item(s)?",
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "These products will be marked as inactive.\nYou can UNDO this action.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        confirm = true;
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirm;
  }

  // ---------------------------------------------------------------------------
  // DELETE USING SOFT DELETE (is_active = false)
  // ---------------------------------------------------------------------------
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      Get.snackbar("No Selection", "Select at least one item to delete.");
      return;
    }

    final pinOk = await _askAdminPin();
    if (!pinOk) return;

    final confirm = await _confirmDeleteDialog(_selectedIds.length);
    if (!confirm) return;

    try {
      setState(() => _deleting = true);

      _lastDeleted = _allProducts
          .where((p) => p.id != null && _selectedIds.contains(p.id))
          .toList();

      await _client
          .from('products')
          .update({'is_active': false})
          .filter('id', 'in', _selectedIds.toList());

      setState(() {
        _allProducts.removeWhere((p) => _selectedIds.contains(p.id));
        _filteredProducts.removeWhere((p) => _selectedIds.contains(p.id));
        _selectedIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted ${_lastDeleted.length} item(s)"),
          action: SnackBarAction(label: "UNDO", onPressed: _undoDelete),
        ),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to delete items: $e");
    } finally {
      setState(() => _deleting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UNDO SOFT DELETE
  // ---------------------------------------------------------------------------
  Future<void> _undoDelete() async {
    if (_lastDeleted.isEmpty) return;

    final ids = _lastDeleted.map((p) => p.id!).toList();

    try {
      await _client
          .from('products')
          .update({'is_active': true})
          .filter('id', 'in', ids);

      setState(() {
        _allProducts.insertAll(0, _lastDeleted);
        _applySearch();
      });

      _lastDeleted = [];
    } catch (e) {
      Get.snackbar("Error", "Failed to undo delete: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // UI (UNCHANGED)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Remove Items"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(SSizes.sm),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by name / barcode / category",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: dark ? Colors.black26 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SSizes.sm),
            child: Row(
              children: [
                Checkbox(
                  value: _allVisibleSelected,
                  onChanged: (val) => _toggleSelectAllVisible(),
                ),
                const Text("Select All", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _deleting || _selectedIds.isEmpty ? null : _deleteSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: SSizes.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: _deleting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.delete),
                  label: Text(
                    _deleting ? "Deleting..." : "Delete (${_selectedIds.length})",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: SSizes.xs),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? const Center(child: Text("No active products found."))
                : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final p = _filteredProducts[index];
                final id = p.id;
                final selected = id != null && _selectedIds.contains(id);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SSizes.sm,
                    vertical: SSizes.xs,
                  ),
                  child: GlossyContainer(
                    child: ListTile(
                      onTap: id == null ? null : () => _toggleSelection(id),
                      leading: Checkbox(
                        value: selected,
                        onChanged: (val) => id != null ? _toggleSelection(id) : null,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Stock: ${p.stockQuantity} • Price: ${p.sellingRate} • "
                            "Category: ${p.categoryName ?? '--'}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: id == null
                            ? null
                            : () {
                          _selectedIds
                            ..clear()
                            ..add(id);
                          _deleteSelected();
                        },
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
}
