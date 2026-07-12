import 'package:flutter/material.dart';
import '../../data/official_tournament_data.dart';
import '../../widgets/team_badge.dart';

/// نتيجة اختيار شعار: الاسم (يُستخدم لتوليد الشعار المرئي) واللون المميز
class SelectedLogo {
  final String name;
  final String colorHex;
  SelectedLogo(this.name, this.colorHex);
}

/// نافذة اختيار شعار من مكتبة التطبيق — تبويبات حسب الفئة + بحث (الفصل 2.5)
class LogoPickerScreen extends StatefulWidget {
  const LogoPickerScreen({super.key});

  @override
  State<LogoPickerScreen> createState() => _LogoPickerScreenState();
}

class _LogoPickerScreenState extends State<LogoPickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final Map<String, List<OfficialTeamData>> _categories =
      OfficialTournamentData.allByCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار شعار'),
        bottom: _searchQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.keys.map((c) => Tab(text: c)).toList(),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث باسم الفريق أو المنتخب...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: _categories.values
                        .map((teams) => _buildGrid(teams))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final allTeams = _categories.values.expand((e) => e).toList();
    final results = allTeams
        .where((t) => t.name.contains(_searchQuery))
        .toSet() // إزالة التكرار (بعض الأندية تظهر في أكثر من فئة كدوري الأبطال)
        .toList();
    if (results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج'));
    }
    return _buildGrid(results);
  }

  Widget _buildGrid(List<OfficialTeamData> teams) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context)
              .pop(SelectedLogo(team.name, team.colorHex)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TeamBadge(name: team.name, colorHex: team.colorHex, size: 56),
              const SizedBox(height: 6),
              Text(
                team.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
