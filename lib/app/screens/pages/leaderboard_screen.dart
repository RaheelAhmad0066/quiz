import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_sized_box.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/leaderboard_controller.dart';
import 'package:afn_test/app/models/leaderboard_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
    
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final leaderboard = controller.currentLeaderboard;
        final topThree = controller.topThree;
        final others = leaderboard.length > 3 ? leaderboard.sublist(3) : <LeaderboardModel>[];

        return SingleChildScrollView(
          child: Column(
            children: [
             
              AppSizedBoxes.largeSizedBox,
              AppSizedBoxes.largeSizedBox,
              topThree.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No rankings yet'),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 2nd Place
                          if (topThree.length >= 2)
                            Expanded(
                              child: _buildTopThreeCard(
                                player: topThree[0],
                                rank: 2,
                                isSecond: true,
                              ),
                            ),
                          if (topThree.length >= 2) const SizedBox(width: 12),
                          // 1st Place
                          if (topThree.isNotEmpty)
                            Expanded(
                              child: _buildTopThreeCard(
                                player: topThree.length >= 2 ? topThree[1] : topThree[0],
                                rank: 1,
                                isFirst: true,
                              ),
                            ),
                          if (topThree.length >= 3) const SizedBox(width: 12),
                          // 3rd Place
                          if (topThree.length >= 3)
                            Expanded(
                              child: _buildTopThreeCard(
                                player: topThree[2],
                                rank: 3,
                                isThird: true,
                              ),
                            ),
                        ],
                      ),
                    ),
              // Leaderboard Content (Inside Container)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: others.asMap().entries.map((entry) {
                            final index = entry.key;
                            final player = entry.value;
                            final rank = index + 4;
                            return _buildLeaderboardItem(player, rank);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTopThreeCard({
    required LeaderboardModel player,
    required int rank,
    bool isFirst = false,
    bool isSecond = false,
    bool isThird = false,
  }) {
    Color badgeColor = isFirst
        ? AppColors.primaryTeal
        : AppColors.primaryTeal.withOpacity(0.2);
    
    // Get emoji based on name (same logic as before - no URL images)
    final name = player.userName.toLowerCase();
    String emoji = '👤'; // default
    if (name.contains('bryan') || name.contains('alex') || name.contains('ricardo') || 
        name.contains('gary') || name.contains('turner') || name.contains('wolf')) {
      emoji = '👨';
    } else if (name.contains('meghan') || name.contains('marsha') || name.contains('juanita') ||
               name.contains('tamara') || name.contains('becky') || name.contains('fisher') ||
               name.contains('cormier') || name.contains('schmidt') || name.contains('bartell')) {
      emoji = '👩';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 90,
              height: isFirst ? 130 : 100,
              decoration: BoxDecoration(
                border: Border.all(color: badgeColor, width: 4),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            if (isFirst)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.accentYellowGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👑',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            if (isSecond || isThird)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: AppTextStyles.label14.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          player.isCurrentUser ? 'You' : player.userName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${player.totalPoints} pts',
          style: AppTextStyles.label14.copyWith(
            color: AppColors.primaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardModel player, int rank) {
    bool isUser = player.isCurrentUser;
    
    // Get emoji based on name (same logic as before - no URL images)
    final name = player.userName.toLowerCase();
    String emoji = '👤'; // default
    if (name.contains('bryan') || name.contains('alex') || name.contains('ricardo') || 
        name.contains('gary') || name.contains('turner') || name.contains('wolf') ||
        name.contains('veum') || name.contains('sanford')) {
      emoji = '👨';
    } else if (name.contains('meghan') || name.contains('marsha') || name.contains('juanita') ||
               name.contains('tamara') || name.contains('becky') || name.contains('fisher') ||
               name.contains('cormier') || name.contains('schmidt') || name.contains('bartell') ||
               name.contains('jessica') || name.contains('jes')) {
      emoji = '👩';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primaryTeal : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isUser ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.isCurrentUser ? 'You' : player.userName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            '${player.totalPoints} pts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isUser ? Colors.white : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}