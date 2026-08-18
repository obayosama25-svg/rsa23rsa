import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';

/// شاشة الفروع وأجهزة الصراف
class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});
  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _selectedCity = 0;

  final List<String> _cities = ['الخرطوم', 'أم درمان', 'بحري', 'بورتسودان', 'كسلا'];

  final List<_Branch> _branches = const [
    _Branch('فرع الخرطوم المركزي', 'شارع النيل، الخرطوم', '07:30 – 16:00', '249-111-000', true, 'الخرطوم'),
    _Branch('فرع الرياض', 'حي الرياض، الخرطوم', '08:00 – 15:30', '249-111-001', true, 'الخرطوم'),
    _Branch('فرع المنشية', 'شارع المنشية، أم درمان', '08:00 – 15:00', '249-111-002', false, 'أم درمان'),
    _Branch('فرع بحري', 'شارع الصناعة، بحري', '07:30 – 16:00', '249-111-003', true, 'بحري'),
    _Branch('فرع بورتسودان', 'البحر الأحمر، بورتسودان', '08:00 – 15:00', '249-111-004', true, 'بورتسودان'),
  ];

  final List<_ATM> _atms = const [
    _ATM('صراف الخرطوم 1', 'مجمع الخرطوم التجاري', true, 'الخرطوم'),
    _ATM('صراف المطار', 'مطار الخرطوم الدولي', true, 'الخرطوم'),
    _ATM('صراف أم درمان', 'السوق الكبير، أم درمان', false, 'أم درمان'),
    _ATM('صراف بحري 1', 'شارع الستين، بحري', true, 'بحري'),
    _ATM('صراف السجانة', 'حي السجانة، الخرطوم', true, 'الخرطوم'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredBranches = _branches.where((b) => b.city == _cities[_selectedCity]).toList();
    final filteredAtms     = _atms.where((a) => a.city == _cities[_selectedCity]).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F6FA),
        body: NestedScrollView(
          headerSliverBuilder: (ctx, inner) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF0D0D12) : const Color(0xFF0B2545),
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('الفروع والصراف', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              centerTitle: true,
              elevation: 0,
              bottom: TabBar(
                controller: _tab,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [Tab(text: 'الفروع'), Tab(text: 'أجهزة الصراف')],
              ),
            ),
          ],
          body: Column(
            children: [
              // فلتر المدن
              Container(
                color: isDark ? AppColors.darkSurface : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cities.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = _selectedCity == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCity = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF0052FF) : (isDark ? const Color(0xFF0D1826) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? const Color(0xFF0052FF) : Colors.transparent),
                          ),
                          child: Text(_cities[i], style: TextStyle(
                            color: selected ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                            fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          )),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // المحتوى
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // الفروع
                    filteredBranches.isEmpty
                      ? _Empty(isDark: isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBranches.length,
                          itemBuilder: (_, i) => FadeInUp(
                            delay: Duration(milliseconds: i * 60),
                            duration: const Duration(milliseconds: 300),
                            child: _BranchCard(branch: filteredBranches[i], isDark: isDark),
                          ),
                        ),
                    // الصراف
                    filteredAtms.isEmpty
                      ? _Empty(isDark: isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAtms.length,
                          itemBuilder: (_, i) => FadeInUp(
                            delay: Duration(milliseconds: i * 60),
                            duration: const Duration(milliseconds: 300),
                            child: _ATMCard(atm: filteredAtms[i], isDark: isDark),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
class _Branch {
  final String name, address, hours, phone, city; final bool isOpen;
  const _Branch(this.name, this.address, this.hours, this.phone, this.isOpen, this.city);
}

class _ATM {
  final String name, address, city; final bool isActive;
  const _ATM(this.name, this.address, this.isActive, this.city);
}

class _BranchCard extends StatelessWidget {
  final _Branch branch; final bool isDark;
  const _BranchCard({required this.branch, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1826) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF0052FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0052FF), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(branch.name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(branch.address, style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (branch.isOpen ? const Color(0xFF10B981) : const Color(0xFFDC2626)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(branch.isOpen ? 'مفتوح' : 'مغلق',
            style: TextStyle(color: branch.isOpen ? const Color(0xFF10B981) : const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(branch.hours, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(width: 16),
        const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(branch.phone, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ]),
    ]),
  );
}

class _ATMCard extends StatelessWidget {
  final _ATM atm; final bool isDark;
  const _ATMCard({required this.atm, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1826) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(
        color: (atm.isActive ? const Color(0xFF10B981) : const Color(0xFFDC2626)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.atm_rounded, color: atm.isActive ? const Color(0xFF10B981) : const Color(0xFFDC2626), size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(atm.name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(atm.address, style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 12)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(
          color: atm.isActive ? const Color(0xFF4ADE80) : const Color(0xFFDC2626),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (atm.isActive ? const Color(0xFF4ADE80) : const Color(0xFFDC2626)).withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)],
        )),
        const SizedBox(height: 4),
        Text(atm.isActive ? 'يعمل' : 'خارج الخدمة',
          style: TextStyle(color: atm.isActive ? const Color(0xFF4ADE80) : const Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );
}

class _Empty extends StatelessWidget {
  final bool isDark;
  const _Empty({required this.isDark});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.location_off_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
    const SizedBox(height: 12),
    Text('لا توجد نتائج في هذه المدينة', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
  ]));
}
