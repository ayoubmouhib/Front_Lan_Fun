import 'package:get/get.dart';

import '../controllers/conversation_controller.dart';
import '../controllers/conversation_detail_controller.dart';

class ConversationBinding extends Bindings {
  @override
  void dependencies() {
    // ConversationController may already be registered by HomeBinding when
    // the user arrives from home; lazyPut(fenix: true) is a no-op if it is.
    Get.lazyPut<ConversationController>(
      () => ConversationController(),
      fenix: true,
    );
    Get.lazyPut<ConversationDetailController>(
      () => ConversationDetailController(),
      fenix: true,
    );
  }
}
