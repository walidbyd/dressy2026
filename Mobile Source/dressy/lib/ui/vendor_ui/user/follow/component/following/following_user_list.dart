import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/user/user_list_provider.dart';
import '../../../../../../core/vendor/utils/ps_animation.dart';
import '../../../../../../core/vendor/viewobject/user.dart';
import '../../../../../custom_ui/user/follow/component/user_vertical_list_item.dart';

class FollowingUserList extends StatefulWidget {
  const FollowingUserList({required this.animationController});
  final AnimationController animationController;

  @override
  State<FollowingUserList> createState() => _FollowingUserListState();
}

class _FollowingUserListState extends State<FollowingUserList>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late UserListProvider provider;
  @override
  void initState() {
    _scrollController.addListener(() {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !provider.isLoading &&
          !provider.isReachMaxData) {
        provider.loadNextDataList();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserListProvider provider = Provider.of<UserListProvider>(context);
    final int count = provider.dataLength;
    final bool isLoading = provider.currentStatus == PsStatus.BLOCK_LOADING;

    return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: PsDimens.space8),
        shrinkWrap: false,
        itemCount: count,
        itemBuilder: (BuildContext context, int index) {
          final User userItem = (provider.userList.data != null &&
                  index < provider.userList.data!.length)
              ? provider.userList.data![index]
              : User();
          return CustomUserVerticalListItem(
              isLoading: isLoading,
              animationController: widget.animationController,
              animation: curveAnimation(widget.animationController,
                  count: count, index: index),
              user: userItem,);
        });
  }
}
