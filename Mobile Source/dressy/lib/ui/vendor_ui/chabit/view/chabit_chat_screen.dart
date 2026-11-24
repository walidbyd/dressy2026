import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../../config/ps_colors.dart';
import '../../../../../config/ps_config.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';

class ChabitChatScreen extends StatefulWidget {
  const ChabitChatScreen({Key? key, this.threadId}) : super(key: key);

  final int? threadId;

  @override
  State<ChabitChatScreen> createState() => _ChabitChatScreenState();
}

class _ChabitChatScreenState extends State<ChabitChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;

  int? _activeThreadId;
  String _language = 'fr';
  bool _aiPaused = false;
  String _threadType = 'assistant';
  String? _orderCode;

  List<Map<String, dynamic>> _threads = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  Timer? _pollTimer;

  late PsValueHolder _valueHolder;

  @override
  void initState() {
    super.initState();
    _activeThreadId = widget.threadId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _activeThreadId != null && !_sending) {
        _loadMessages(_activeThreadId!, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, String> _headers() {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': PsConfig.ps_bearer_token,
    };
    if (_valueHolder.headerToken != null &&
        _valueHolder.headerToken!.isNotEmpty) {
      headers['Ps-Token'] = _valueHolder.headerToken!;
    }
    return headers;
  }

  String _userIdParam() {
    return _valueHolder.loginUserId ?? '';
  }

  Future<void> _initializeChat() async {
    _valueHolder = Provider.of<PsValueHolder>(context, listen: false);
    if (Utils.isLoginUserEmpty(_valueHolder)) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    await _loadThreads();
    if (_activeThreadId != null) {
      await _loadMessages(_activeThreadId!);
    }
  }

  Future<void> _loadThreads() async {
    try {
      final Uri uri = Uri.parse(
          '${PsConfig.ps_app_url}chabit/threads?login_user_id=${_userIdParam()}');
      final http.Response res =
          await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15));

      if (res.statusCode == 401) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Veuillez vous connecter pour utiliser Chabit AI.';
          });
        }
        return;
      }

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        final List<dynamic> rawThreads =
            (data['threads'] as List<dynamic>?) ?? <dynamic>[];
        final List<Map<String, dynamic>> parsed = rawThreads
            .whereType<Map<String, dynamic>>()
            .toList();

        if (mounted) {
          setState(() {
            _threads = parsed;
            _activeThreadId ??= data['default_thread_id'] as int? ??
                (parsed.isNotEmpty ? parsed.first['id'] as int? : null);
          });
        }
      } else if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur serveur (${res.statusCode})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossible de joindre Chabit AI.';
        });
      }
    }
  }

  Future<void> _loadMessages(int threadId, {bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final Uri uri = Uri.parse(
          '${PsConfig.ps_app_url}chabit/threads/$threadId/messages?login_user_id=${_userIdParam()}');
      final http.Response res =
          await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic>? thread =
            data['thread'] as Map<String, dynamic>?;
        final List<dynamic> rawMsgs =
            (data['messages'] as List<dynamic>?) ?? <dynamic>[];
        final List<Map<String, dynamic>> parsedMsgs = rawMsgs
            .whereType<Map<String, dynamic>>()
            .toList();

        final bool hasNew = parsedMsgs.length != _messages.length;

        if (mounted) {
          setState(() {
            _loading = false;
            _activeThreadId = threadId;
            _messages = parsedMsgs;
            if (thread != null) {
              _language = (thread['language'] as String?) ?? _language;
              _aiPaused = thread['ai_paused'] == true || thread['ai_paused'] == 1;
              _threadType = (thread['thread_type'] as String?) ?? 'assistant';
              final Map<String, dynamic>? orderObj =
                  thread['order'] as Map<String, dynamic>?;
              _orderCode = orderObj?['order_code']?.toString();
            }
          });
          if (!silent || hasNew) {
            _scrollToBottom();
          }
        }
      } else if (!silent && mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossible de charger les messages (${res.statusCode}).';
        });
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() {
          _loading = false;
          _error = 'Connexion interrompue.';
        });
      }
    }
  }

  Future<void> _sendMessage({String? customBody, String? action}) async {
    final String body = (customBody ?? _inputController.text).trim();
    if ((body.isEmpty && (action == null || action.isEmpty)) ||
        _activeThreadId == null ||
        _sending) {
      return;
    }

    if (customBody == null) {
      _inputController.clear();
    }

    final Map<String, dynamic> optimistic = <String, dynamic>{
      'id': -DateTime.now().millisecondsSinceEpoch,
      'sender_type': 'user',
      'body': body.isNotEmpty ? body : (action ?? ''),
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _sending = true;
      _messages.add(optimistic);
    });
    _scrollToBottom();

    try {
      final Uri uri = Uri.parse(
          '${PsConfig.ps_app_url}chabit/threads/$_activeThreadId/messages?login_user_id=${_userIdParam()}');
      final http.Response res = await http
          .post(
            uri,
            headers: _headers(),
            body: json.encode(<String, dynamic>{
              'login_user_id': _userIdParam(),
              'body': body,
              if (action != null) 'action': action,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic>? thread =
            data['thread'] as Map<String, dynamic>?;
        final Map<String, dynamic>? userMsg =
            data['user_message'] as Map<String, dynamic>?;
        final Map<String, dynamic>? replyMsg =
            data['reply_message'] as Map<String, dynamic>?;

        if (mounted) {
          setState(() {
            _messages.removeWhere(
                (Map<String, dynamic> m) => m['id'] == optimistic['id']);
            if (userMsg != null) {
              _messages.add(userMsg);
            }
            if (replyMsg != null) {
              _messages.add(replyMsg);
            }
            if (thread != null && thread['language'] != null) {
              _language = thread['language'].toString();
            }
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi du message.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _switchLanguage(String lang) async {
    if (_activeThreadId == null || _sending) {
      return;
    }
    setState(() {
      _language = lang;
      _sending = true;
    });
    try {
      final Uri uri = Uri.parse(
          '${PsConfig.ps_app_url}chabit/threads/$_activeThreadId/language?login_user_id=${_userIdParam()}');
      final http.Response res = await http
          .post(
            uri,
            headers: _headers(),
            body: json.encode(<String, dynamic>{
              'login_user_id': _userIdParam(),
              'language': lang,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic>? reply =
            data['reply_message'] as Map<String, dynamic>?;
        if (mounted && reply != null) {
          setState(() {
            _messages.add(reply);
          });
          _scrollToBottom();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showThreadsBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Conversations Chabit AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _threads.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Map<String, dynamic> t = _threads[i];
                    final String type = (t['thread_type'] as String?) ?? 'assistant';
                    final Map<String, dynamic>? order =
                        t['order'] as Map<String, dynamic>?;
                    final String title = type == 'assistant'
                        ? '✨ Assistant Dressy (Chabit)'
                        : (type == 'order_buyer'
                            ? '🛍️ Commande ${order?['order_code'] ?? '#${t['order_id']}'}'
                            : '📦 Vente ${order?['order_code'] ?? '#${t['order_id']}'}');
                    final Map<String, dynamic>? latest =
                        t['latest_message'] as Map<String, dynamic>?;
                    final bool selected = t['id'] == _activeThreadId;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: PsColors.burgundy.withValues(alpha: 0.08),
                      title: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        (latest?['body'] as String?) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (t['id'] is int) {
                          _loadMessages(t['id'] as int);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRtl = _language == 'ar';
    final bool isLight = Utils.isLightMode(context);

    final String hintText = _language == 'ar'
        ? 'اكتب رسالتك لشابيت...'
        : (_language == 'en'
            ? 'Ask Chabit anything about Dressy...'
            : 'Posez votre question à Chabit...');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isLight ? const Color(0xFFFAF7F2) : PsColors.achromatic900,
        appBar: AppBar(
          backgroundColor: isLight ? Colors.white : PsColors.achromatic800,
          elevation: 0.5,
          iconTheme: IconThemeData(
              color: isLight ? PsColors.burgundy : PsColors.achromatic50),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.auto_awesome,
                      size: 18, color: PsColors.burgundy),
                  const SizedBox(width: 6),
                  Text(
                    _threadType == 'assistant'
                        ? 'Chabit AI'
                        : (_orderCode != null
                            ? 'Commande $_orderCode'
                            : 'Suivi Commande'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLight ? PsColors.burgundy : Colors.white,
                    ),
                  ),
                ],
              ),
              if (_aiPaused)
                const Text(
                  'Support Humain Dressy',
                  style: TextStyle(fontSize: 11, color: Colors.teal),
                ),
            ],
          ),
          actions: <Widget>[
            // Top-bar Language Switcher (AR / FR / EN)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFF3ECE4)
                      : PsColors.achromatic700,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <String>['ar', 'fr', 'en'].map((String code) {
                    final bool active = _language == code;
                    return GestureDetector(
                      onTap: () => _switchLanguage(code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? PsColors.burgundy : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: active
                                ? Colors.white
                                : (isLight ? PsColors.text700 : Colors.white70),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_threads.length > 1)
              IconButton(
                icon: const Icon(Icons.forum_outlined, size: 22),
                tooltip: 'Conversations',
                onPressed: _showThreadsBottomSheet,
              ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: PsColors.burgundy))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: PsColors.burgundy),
                                  onPressed: _initializeChat,
                                  child: const Text('Réessayer',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (BuildContext context, int index) {
                            if (_sending && index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessageBubble(
                                _messages[index], isLight);
                          },
                        ),
            ),
            // Input Bar
            SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : PsColors.achromatic800,
                  border: Border(
                    top: BorderSide(
                      color: isLight
                          ? const Color(0xFFEAE2D8)
                          : PsColors.achromatic700,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: const TextStyle(fontSize: 13.5),
                          filled: true,
                          fillColor: isLight
                              ? const Color(0xFFFAF7F2)
                              : PsColors.achromatic900,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: PsColors.burgundy,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                        onPressed: _sending ? null : () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isLight) {
    final String sender = (msg['sender_type'] as String?) ?? 'ai';
    final bool isUser = sender == 'user';
    final String body = (msg['body'] as String?) ?? '';
    final List<dynamic> quickReplies =
        (msg['quick_replies'] as List<dynamic>?) ?? <dynamic>[];

    String badgeText = 'Chabit AI';
    Color badgeColor = PsColors.burgundy;
    if (sender == 'admin') {
      badgeText = 'Admin Dressy';
      badgeColor = const Color(0xFF059669);
    } else if (sender == 'system') {
      badgeText = 'Dressy';
      badgeColor = const Color(0xFF475569);
    }

    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? PsColors.burgundy
                    : (isLight ? Colors.white : PsColors.achromatic800),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isLight
                            ? const Color(0xFFEAE2D8)
                            : PsColors.achromatic700,
                      ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isUser
                      ? Colors.white
                      : (isLight ? const Color(0xFF1F2937) : Colors.white),
                ),
              ),
            ),
            if (quickReplies.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickReplies
                    .whereType<Map<String, dynamic>>()
                    .map((Map<String, dynamic> qr) {
                  final String label = (qr['label'] as String?) ?? '';
                  final String action = (qr['action'] as String?) ?? '';
                  return ActionChip(
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: PsColors.burgundy,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: PsColors.burgundy, width: 1.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: _sending
                        ? null
                        : () => _sendMessage(customBody: label, action: action),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE2D8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PsColors.burgundy,
              ),
            ),
            SizedBox(width: 8),
            Text('Chabit...', style: TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
