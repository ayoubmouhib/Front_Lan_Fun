import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/blocked_users_api.dart';
import '../../data/models/blocked_user_model.dart';

class BlockedUsersController extends GetxController {
  static BlockedUsersController get to => Get.find();

  final blockedUsers = <BlockedUserModel>[].obs;
  final isLoading    = true.obs;
  final errorMessage = Rx<String?>(null);

  /// Tracks block IDs currently being unblocked, so their tile can show a spinner.
  final unblockingIds = <int>{}.obs;

  late final BlockedUsersApi _api;

  @override
  void onInit() {
    super.onInit();
    _api = BlockedUsersApi(ApiClient.instance);
    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final list = await _api.getBlockedUsers();
      blockedUsers.assignAll(
        list.map((j) => BlockedUserModel.fromJson(j)).toList(),
      );
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unblock(BlockedUserModel user) async {
    unblockingIds.add(user.blockId);
    try {
      await _api.deleteBlock(user.userId);
      blockedUsers.removeWhere((u) => u.blockId == user.blockId);
      Get.snackbar(
        'Unblocked',
        '${user.name} can now contact you again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Action Failed',
        ApiClient.parseError(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      unblockingIds.remove(user.blockId);
    }
  }
}
