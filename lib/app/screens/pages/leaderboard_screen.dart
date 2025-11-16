import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_sized_box.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/app_icons.dart';
import 'package:afn_test/app/app_widgets/spinkit_loadder.dart';
import 'package:afn_test/app/controllers/leaderboard_controller.dart';
import 'package:afn_test/app/models/leaderboard_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  /// Get asset image path based on name
  String _getProfileAssetImage(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('bryan') || lowerName.contains('alex') || lowerName.contains('ricardo') || 
        lowerName.contains('gary') || lowerName.contains('turner') || lowerName.contains('wolf') ||
        lowerName.contains('veum') || lowerName.contains('sanford')) {
      return AppIcons.man;
    } else if (lowerName.contains('meghan') || lowerName.contains('marsha') || lowerName.contains('juanita') ||
               lowerName.contains('tamara') || lowerName.contains('becky') || lowerName.contains('fisher') ||
               lowerName.contains('cormier') || lowerName.contains('schmidt') || lowerName.contains('bartell') ||
               lowerName.contains('jessica') || lowerName.contains('jes')) {
      return AppIcons.girl;
    } else {
      return AppIcons.businessman; // default
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
    
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: SpinkitLoader(),
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
    
    // Get asset image based on name
    final profileImage = _getProfileAssetImage(player.userName);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
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
                  child: Image.asset(
                    profileImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (isFirst)
              Positioned(
                top: -8,
                child: Container(
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
              ),
            if (isSecond)
              Positioned(
                top: -8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      AppIcons.medal2,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (isThird)
              Positioned(
                top: -8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      AppIcons.medal3,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
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
    
    // Get asset image based on name
    final profileImage = _getProfileAssetImage(player.userName);

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
            child: Image.asset(
              profileImage,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.totalPoints} pts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isUser ? Colors.white : Colors.black54,
                ),
              ),
              if (player.matchesWon > 0)
                Text(
                  '${player.matchesWon} wins',
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? Colors.white70 : Colors.black38,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}