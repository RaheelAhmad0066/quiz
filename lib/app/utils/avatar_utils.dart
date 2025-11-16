import 'dart:math';
import 'package:flutter/material.dart';

/// Utility class for generating random avatar URLs based on name
class AvatarUtils {
  static final Random _random = Random();

  /// Generate avatar URL based on name
  /// If name contains "girl" or female indicators -> girl avatar
  /// If name contains "men" or male indicators -> boy avatar
  /// Otherwise random
  static String getAvatarUrl(String name) {
    final nameLower = name.toLowerCase();
    
    // Common female names/indicators
    final femaleIndicators = [
      'girl', 'woman', 'female', 'leslie', 'kristin', 'darlene', 
      'savannah', 'jenny', 'dianne', 'meghan', 'marsha', 'juanita',
      'tamara', 'becky', 'sarah', 'emily', 'jessica', 'amanda',
      'lisa', 'jennifer', 'michelle', 'patricia', 'linda', 'elizabeth',
      'barbara', 'susan', 'karen', 'nancy', 'betty', 'helen',
      'sandra', 'donna', 'carol', 'ruth', 'sharon', 'michelle',
      'laura', 'kimberly', 'deborah', 'amy', 'angela', 'ashley',
      'brenda', 'emma', 'olivia', 'sophia', 'isabella', 'mia',
      'charlotte', 'amelia', 'harper', 'evelyn', 'abigail', 'emily',
    ];
    
    // Common male names/indicators
    final maleIndicators = [
      'men', 'man', 'male', 'boy', 'bryan', 'alex', 'ricardo',
      'gary', 'john', 'michael', 'david', 'james', 'robert',
      'william', 'richard', 'joseph', 'thomas', 'charles', 'christopher',
      'daniel', 'matthew', 'anthony', 'mark', 'donald', 'steven',
      'paul', 'andrew', 'joshua', 'kenneth', 'kevin', 'brian',
      'george', 'timothy', 'ronald', 'jason', 'edward', 'jeffrey',
      'ryan', 'jacob', 'gary', 'nicholas', 'eric', 'jonathan',
      'stephen', 'larry', 'justin', 'scott', 'brandon', 'benjamin',
      'samuel', 'frank', 'gregory', 'raymond', 'alexander', 'patrick',
      'jack', 'dennis', 'jerry', 'tyler', 'aaron', 'jose',
    ];
    
    // Check for female indicators
    for (final indicator in femaleIndicators) {
      if (nameLower.contains(indicator)) {
        return _getGirlAvatar();
      }
    }
    
    // Check for male indicators
    for (final indicator in maleIndicators) {
      if (nameLower.contains(indicator)) {
        return _getBoyAvatar();
      }
    }
    
    // Default: random based on name hash for consistency
    final nameHash = name.hashCode;
    return nameHash.isEven ? _getGirlAvatar() : _getBoyAvatar();
  }

  /// Get random girl avatar URL
  static String _getGirlAvatar() {
    final girlAvatars = [
      'https://i.pravatar.cc/150?img=47', // Leslie
      'https://i.pravatar.cc/150?img=20', // Alex
      'https://i.pravatar.cc/150?img=27', // Kristin
      'https://i.pravatar.cc/150?img=33', // Darlene
      'https://i.pravatar.cc/150?img=45', // Savannah
      'https://i.pravatar.cc/150?img=32', // Jenny
      'https://i.pravatar.cc/150?img=31', // Dianne
      'https://i.pravatar.cc/150?img=25',
      'https://i.pravatar.cc/150?img=29',
      'https://i.pravatar.cc/150?img=35',
    ];
    return girlAvatars[_random.nextInt(girlAvatars.length)];
  }

  /// Get random boy avatar URL
  static String _getBoyAvatar() {
    final boyAvatars = [
      'https://i.pravatar.cc/150?img=12', // You (male with beard)
      'https://i.pravatar.cc/150?img=13',
      'https://i.pravatar.cc/150?img=15',
      'https://i.pravatar.cc/150?img=16',
      'https://i.pravatar.cc/150?img=18',
      'https://i.pravatar.cc/150?img=19',
      'https://i.pravatar.cc/150?img=21',
      'https://i.pravatar.cc/150?img=23',
      'https://i.pravatar.cc/150?img=24',
      'https://i.pravatar.cc/150?img=26',
    ];
    return boyAvatars[_random.nextInt(boyAvatars.length)];
  }

  /// Get avatar color based on rank
  static Color getAvatarColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFE1BEE7); // Light purple
      case 2:
        return const Color(0xFFD7CCC8); // Light brown
      case 3:
        return const Color(0xFFBBDEFB); // Light blue
      default:
        return const Color(0xFFE0E0E0); // Light gray
    }
  }
}

