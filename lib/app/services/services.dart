import 'package:afn_test/app/services/fcm_token_service.dart';
import 'package:afn_test/app/services/prefferences.dart';
import 'package:get/get.dart';


class Services {
  static final Services _instance = Services._();

  Services._();

  factory Services() => _instance;
  Future<void> initServices() async {
    await Get.putAsync<Preferences>(() => Preferences().initial());
    // Initialize FCM Token Service
    Get.put(FcmTokenService(), permanent: true);
    await Get.find<FcmTokenService>().initialize();
  }
}
