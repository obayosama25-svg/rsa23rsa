import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../models/beneficiary.dart';
import '../services/transaction_service.dart';
import 'transfer_screen.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  List<Beneficiary> _allBeneficiaries = [];
  List<Beneficiary> _filteredBeneficiaries = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
    _searchController.addListener(_filterBeneficiaries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('beneficiaries_json');
    if (jsonList != null) {
      setState(() {
        _allBeneficiaries = jsonList.map((str) => Beneficiary.fromJson(str)).toList();
        _filteredBeneficiaries = List.from(_allBeneficiaries);
      });
    }
    setState(() => _isLoading = false);
  }

  void _filterBeneficiaries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBeneficiaries = _allBeneficiaries.where((b) {
        return b.name.toLowerCase().contains(query) ||
               b.accountNumber.toLowerCase().contains(query) ||
               b.id.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _deleteBeneficiary(Beneficiary b) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allBeneficiaries.remove(b);
      _filteredBeneficiaries.remove(b);
    });
    await prefs.setStringList('beneficiaries_json', _allBeneficiaries.map((b) => b.toJson()).toList());
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'المستفيدين الموثوقين',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FadeInDown(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم، الحساب، أو رقم الهوية...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filteredBeneficiaries.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredBeneficiaries.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final b = _filteredBeneficiaries[index];
                              return FadeInUp(
                                delay: Duration(milliseconds: 100 * index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isDark ? AppColors.primaryGreen.withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.1),
                                      child: Text(
                                        b.name.isNotEmpty ? b.name.substring(0, 1) : '?',
                                        style: TextStyle(
                                          color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      b.name,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'رقم الحساب: ${b.accountNumber}',
                                          style: TextStyle(
                                            color: isDark ? Colors.white54 : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (b.id.isNotEmpty && b.id != 'Migrated')
                                          Text(
                                            'الهوية: ${b.id}',
                                            style: TextStyle(
                                              color: isDark ? Colors.white38 : Colors.black38,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.send_rounded, color: AppColors.primaryGreen),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TransferScreen(initialAccountNumber: b.accountNumber),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _deleteBeneficiary(b),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddBeneficiaryDialog,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('إضافة مستفيد', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showAddBeneficiaryDialog() {
    final TextEditingController accController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    bool isSearching = false;
    String? foundId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'إضافة مستفيد جديد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: accController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'رقم الحساب',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      hintText: '12345678',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                      suffixIcon: IconButton(
                        icon: isSearching 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search, color: AppColors.primaryGreen),
                        onPressed: () async {
                          if (accController.text.length < 8) return;
                          setDialogState(() => isSearching = true);
                          final userMap = await TransactionService.searchAccount(accController.text);
                          setDialogState(() {
                            isSearching = false;
                            if (userMap != null) {
                              final fName = "${userMap['firstName'] ?? ''} ${userMap['lastName'] ?? ''}".trim();
                              foundId = userMap['_id'];
                              nameController.text = fName;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'اسم المستفيد',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final acc = accController.text.trim();
                  final name = nameController.text.trim();
                  if (acc.isNotEmpty && name.isNotEmpty) {
                    final newBeneficiary = Beneficiary(
                      id: foundId ?? 'Manual',
                      name: name,
                      accountNumber: acc,
                    );
                    final prefs = await SharedPreferences.getInstance();
                    if (!_allBeneficiaries.any((b) => b.accountNumber == acc)) {
                      setState(() {
                        _allBeneficiaries.add(newBeneficiary);
                        _filteredBeneficiaries.add(newBeneficiary);
                      });
                      await prefs.setStringList(
                        'beneficiaries_json',
                        _allBeneficiaries.map((b) => b.toJson()).toList(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }
}
