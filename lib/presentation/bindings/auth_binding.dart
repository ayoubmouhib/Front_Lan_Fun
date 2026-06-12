import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppController(), permanent: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
