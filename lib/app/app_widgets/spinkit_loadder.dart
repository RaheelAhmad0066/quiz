import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SpinkitLoader extends StatelessWidget {
  final Color color;
  const SpinkitLoader({super.key, this.color = AppColors.primaryTeal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(child: SpinKitFadingCircle(color: color, size: 40.0)),
    );
  }
}
