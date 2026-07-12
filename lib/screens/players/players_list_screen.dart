import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/player_provider.dart';
import '../../widgets/player_card.dart';
import 'add_edit_player_screen.dart';
import 'player_details_screen.dart';

/// صفحة "اللاعبون" — قاعدة بيانات اللاعبين الخاصة بالمستخدم (الفصل 2.2)
class PlayersListScreen extends StatefulWidget {
  const PlayersListScreen({super.key});

  @override
  State<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends State<PlayersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👥 اللاعبون')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن لاعب...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PlayerProvider>().search('');
                        },
                      ),
              ),
              onChanged: (value) => context.read<PlayerProvider>().search(value),
            ),
          ),
          Expanded(
            child: Consumer<PlayerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.players.isEmpty) {
                  return const _EmptyPlayersState();
                }
                return RefreshIndicator(
                  onRefresh: provider.loadPlayers,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 4),
                    itemCount: provider.players.length,
                    itemBuilder: (context, index) {
                      final player = provider.players[index];
                      return PlayerCard(
                        player: player,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerDetailsScreen(playerId: player.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditPlayerScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyPlayersState extends StatelessWidget {
  const _EmptyPlayersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'لا يوجد لاعبون بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط على زر (+) لإضافة أول لاعب قبل إنشاء أي بطولة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
