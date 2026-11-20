import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/route/route_paths.dart';
import '../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../core/vendor/db/common/ps_data_source_manager.dart';
import '../../../../../core/vendor/provider/chat/buyer_chat_history_list_provider.dart';
import '../../../../../core/vendor/provider/chat/seller_chat_history_list_provider.dart';
import '../../../../../core/vendor/provider/chat/user_unread_message_provider.dart';
import '../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/chat_history.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../core/vendor/viewobject/holder/chat_history_parameter_holder.dart';
import '../../../../../core/vendor/viewobject/holder/intent_holder/chat_history_intent_holder.dart';
import '../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../core/vendor/viewobject/holder/user_unread_message_parameter_holder.dart';
import '../../../../../core/vendor/viewobject/user.dart';
import '../../../common/ps_ui_widget.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({
    Key? key,
    required this.buyerListProvider,
    required this.sellerListProvider,
    required this.scaffoldKey,
  }) : super(key: key);

  final BuyerChatHistoryListProvider? buyerListProvider;
  final SellerChatHistoryListProvider? sellerListProvider;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  _ChatListViewState createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final ScrollController _scrollController = ScrollController();
  ChatHistoryParameterHolder? _unifiedHolder;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.buyerListProvider != null &&
          widget.buyerListProvider!.hasData &&
          !widget.buyerListProvider!.isLoading) {
        widget.buyerListProvider!.loadNextDataList(
          dataConfig:
              DataConfiguration(dataSourceType: DataSourceType.SERVER_DIRECT),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    if (_isRefreshing) {
      return;
    }

    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);
    final UserUnreadMessageProvider unreadMessageProvider =
        Provider.of<UserUnreadMessageProvider>(context, listen: false);

    if (widget.buyerListProvider != null &&
        !Utils.isLoginUserEmpty(psValueHolder)) {
      if (widget.buyerListProvider!.isLoading) {
        return;
      }
      _isRefreshing = true;
      try {
        final String currentUserId = Utils.checkUserLoginId(psValueHolder);
        _unifiedHolder = ChatHistoryParameterHolder().getUnifiedHistoryList();
        _unifiedHolder!.userId = currentUserId;

        widget.buyerListProvider!.resetShowProgress();
        await widget.buyerListProvider!.loadDataList(
          reset: true,
          requestBodyHolder: _unifiedHolder!,
          requestPathHolder: RequestPathHolder(
            loginUserId: currentUserId,
            headerToken: psValueHolder.headerToken,
            languageCode: langProvider.currentLocale.languageCode,
          ),
          dataConfig:
              DataConfiguration(dataSourceType: DataSourceType.SERVER_DIRECT),
        );

        // Also refresh unread counts
        if (!Utils.isLoginUserEmpty(psValueHolder)) {
          await unreadMessageProvider.loadData(
            requestBodyHolder: UserUnreadMessageParameterHolder(
              userId: currentUserId,
              deviceToken: psValueHolder.deviceToken,
            ),
            requestPathHolder: RequestPathHolder(
              loginUserId: currentUserId,
              headerToken: psValueHolder.headerToken,
              languageCode: langProvider.currentLocale.languageCode,
            ),
          );
        }
      } catch (e) {
        // Safe catch for network glitches
      } finally {
        _isRefreshing = false;
      }
    }
  }

  Future<void> _navigateToChat(
      BuildContext context, ChatHistory chatHistory, String currentUserId) async {
    final bool isBuyer = (currentUserId == chatHistory.buyerUserId);
    final User? otherUser =
        chatHistory.user ?? (isBuyer ? chatHistory.seller : chatHistory.buyer);

    // Optimistically clear unread count locally immediately
    setState(() {
      chatHistory.buyerUnreadCount = '0';
      chatHistory.sellerUnreadCount = '0';
    });

    await Navigator.pushNamed(
      context,
      RoutePaths.chatView,
      arguments: ChatHistoryIntentHolder(
        chatFlag: isBuyer ? PsConst.CHAT_FROM_BUYER : PsConst.CHAT_FROM_SELLER,
        itemId: chatHistory.item?.id ?? chatHistory.itemId,
        buyerUserId: chatHistory.buyerUserId,
        sellerUserId: chatHistory.sellerUserId,
        userCoverPhoto: otherUser?.userCoverPhoto,
        userName: otherUser?.name ?? '',
        itemDetail: chatHistory.item,
        orderId: chatHistory.orderId,
        orderCode: chatHistory.orderCode,
      ),
    );

    if (mounted) {
      _refreshMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PsValueHolder psValueHolder = Provider.of<PsValueHolder>(context);
    final String currentUserId = Utils.checkUserLoginId(psValueHolder);

    if (widget.buyerListProvider == null) {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider<BuyerChatHistoryListProvider>.value(
      value: widget.buyerListProvider!,
      child: Consumer<BuyerChatHistoryListProvider>(
        builder: (BuildContext context, BuyerChatHistoryListProvider provider,
            Widget? child) {
          // Single unified messages list
          final List<ChatHistory> messageList =
              provider.chatHistoryList.data ?? <ChatHistory>[];

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? dynamic) async {
              if (didPop) {
                return;
              }
              return Future<void>.value(false);
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFFAF7F2),
              appBar: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF2D2424)),
                  onPressed: () {
                    widget.scaffoldKey.currentState?.openDrawer();
                  },
                ),
                title: Row(
                  children: <Widget>[
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Color(0xFF2D2424),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (messageList.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C1A2B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${messageList.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5C1A2B),
                          ),
                        ),
                      ),
                  ],
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEAE2D8),
                  ),
                ),
              ),
              body: Utils.isLoginUserEmpty(psValueHolder)
                  ? _buildNotLoggedInView(context)
                  : Stack(
                      children: <Widget>[
                        RefreshIndicator(
                          color: const Color(0xFF5C1A2B),
                          onRefresh: _refreshMessages,
                          child: messageList.isNotEmpty
                              ? ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: PsDimens.space8),
                                  itemCount: messageList.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final ChatHistory chatHistory =
                                        messageList[index];
                                    return _buildUnifiedChatCard(
                                      context,
                                      chatHistory,
                                      currentUserId,
                                    );
                                  },
                                )
                              : (provider.currentStatus == PsStatus.NOACTION ||
                                      !provider.isLoading)
                                  ? _buildEmptyView(context)
                                  : const SizedBox.shrink(),
                        ),
                        if (provider.isLoading && !provider.hasData)
                          const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF5C1A2B),
                            ),
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedChatCard(
      BuildContext context, ChatHistory chatHistory, String currentUserId) {
    final bool isBuyer = (currentUserId == chatHistory.buyerUserId);
    final User? otherUser =
        chatHistory.user ?? (isBuyer ? chatHistory.seller : chatHistory.buyer);

    // Dynamic unread state
    final bool hasUnread = chatHistory.hasUnreadCount ||
        (isBuyer
            ? chatHistory.hasBuyerUnreadCount
            : chatHistory.hasSellerUnreadCount);

    final String unreadCountStr = chatHistory.unreadCount?.isNotEmpty == true
        ? chatHistory.unreadCount!
        : (isBuyer
            ? (chatHistory.buyerUnreadCount ?? '0')
            : (chatHistory.sellerUnreadCount ?? '0'));

    final String otherUserName = otherUser?.name?.trim().isNotEmpty == true
        ? otherUser!.name!
        : 'Utilisateur Dressy';

    final String itemTitle = chatHistory.item?.title ?? 'Article';
    final String orderCode = chatHistory.orderCode ?? '';

    // Human-readable order status label & styling
    final String statusLabel = _resolveStatusLabel(chatHistory);

    final String previewMessage = (isBuyer &&
            chatHistory.actionStatus == 'pending')
        ? 'En attente de confirmation du vendeur...'
        : (chatHistory.lastMessage?.trim().isNotEmpty == true
            ? chatHistory.lastMessage!
            : (chatHistory.latestChatMessage ?? ''));

    final String timeStr = chatHistory.lastMessageTime?.isNotEmpty == true
        ? chatHistory.lastMessageTime!
        : (chatHistory.addedDateStr ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space6,
      ),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFFFFFDF9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? const Color(0xFF5C1A2B).withValues(alpha: 0.28)
              : const Color(0xFFEFE8E0),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToChat(context, chatHistory, currentUserId),
          child: Padding(
            padding: const EdgeInsets.all(PsDimens.space12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Product Thumbnail & Avatar Stack
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFFAF7F2),
                        child: chatHistory.item?.defaultPhoto != null
                            ? PsNetworkImage(
                                photoKey: '',
                                defaultPhoto: chatHistory.item?.defaultPhoto,
                                imageAspectRation: PsConst.Aspect_Ratio_1x,
                                boxfit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.checkroom_rounded,
                                size: 28,
                                color: Color(0xFFD6CBC1),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -4,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: PsNetworkCircleImageForUser(
                            photoKey: '',
                            imagePath: otherUser?.userCoverPhoto,
                            boxfit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Center Information Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Username & Role/Order Badges Row
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              otherUserName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF2D2424),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Role & Order Badge: "Vente • #123" or "Achat • #123"
                          _buildRoleOrderBadge(
                            isBuyer: isBuyer,
                            orderCode: orderCode,
                          ),

                          // Order Status Pill (e.g. En attente, Acceptée, Expédiée...)
                          if (statusLabel.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 4),
                            _buildStatusPill(statusLabel),
                          ],
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Item Title
                      Text(
                        itemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7A736E),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Latest Message Snippet
                      Text(
                        previewMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                          fontStyle: (isBuyer &&
                                  chatHistory.actionStatus == 'pending')
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: hasUnread
                              ? const Color(0xFF2D2424)
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right Meta (Timestamp & Unread Count)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread
                            ? const Color(0xFF5C1A2B)
                            : const Color(0xFFB0A8A0),
                        fontWeight:
                            hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C1A2B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCountStr,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.done_all_rounded,
                        size: 16,
                        color: Color(0xFFB0A8A0),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOrderBadge({
    required bool isBuyer,
    required String orderCode,
  }) {
    final bool isSelling = !isBuyer;
    final String label = orderCode.isNotEmpty
        ? (isSelling ? 'Vente • #$orderCode' : 'Achat • #$orderCode')
        : (isSelling ? 'Vente' : 'Achat');

    final Color bgColor = isSelling
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFE3F2FD);
    final Color textColor = isSelling
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1565C0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String statusLabel) {
    Color bg = const Color(0xFFF5F5F5);
    Color fg = const Color(0xFF616161);

    final String lower = statusLabel.toLowerCase();
    if (lower.contains('attente') || lower.contains('pending')) {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
    } else if (lower.contains('accept') ||
        lower.contains('confirm') ||
        lower.contains('livr')) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (lower.contains('expéd') || lower.contains('dispatch')) {
      bg = const Color(0xFFEDE7F6);
      fg = const Color(0xFF512DA8);
    } else if (lower.contains('annul') || lower.contains('cancel')) {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  String _resolveStatusLabel(ChatHistory chatHistory) {
    if (chatHistory.orderStatusLabel?.isNotEmpty == true) {
      return chatHistory.orderStatusLabel!;
    }
    final String action = chatHistory.actionStatus ?? '';
    switch (action.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
      case 'accepted':
        return 'Acceptée';
      case 'dispatched':
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return '';
    }
  }

  Widget _buildEmptyView(BuildContext context) {
    const String emptyTitle = 'Aucun message pour le moment';
    const String emptySubtitle =
        'Vos commandes et vos conversations avec les acheteurs et vendeurs apparaîtront ici.';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.symmetric(horizontal: PsDimens.space32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C1A2B).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: Color(0xFF5C1A2B),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2424),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF8A827B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PsDimens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF5C1A2B).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 38,
                color: Color(0xFF5C1A2B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connectez-vous pour voir vos messages',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2424),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C1A2B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, RoutePaths.login_container);
              },
              child: const Text(
                'Se connecter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
