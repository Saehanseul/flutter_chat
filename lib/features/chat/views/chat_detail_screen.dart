import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/view_models/chat_channel_view_model.dart';
import 'package:flutter_chat/features/chat/view_models/chat_message_view_model.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String channelId;
  final String otherUserName;
  final String sendUserId;
  final String receiveUserId;
  bool isBlocked;

  ChatDetailScreen({
    super.key,
    required this.channelId,
    required this.otherUserName,
    required this.sendUserId,
    required this.receiveUserId,
    required this.isBlocked,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  ChatMessageViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      _viewModel = Provider.of<ChatMessageViewModel>(context, listen: false);
      Future.microtask(() {
        _viewModel!.subscribeToMessages(widget.channelId);
        _viewModel!.updateReadStatus(
            channelId: widget.channelId, userId: widget.sendUserId);
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.unsubscribeFromMessages();
    _messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.otherUserName}님과 채팅'),
        actions: [
          TextButton(
            child: Text(widget.isBlocked ? '차단 해제' : '차단'),
            onPressed: () {
              ChatChannelViewModel? channelViewModel =
                  Provider.of<ChatChannelViewModel>(context, listen: false);

              channelViewModel.blockChannel(
                channelId: widget.channelId,
                userId: widget.sendUserId,
                block: !widget.isBlocked,
              );
              if (channelViewModel.errorMessage.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isBlocked ? '사용자가 차단 해제되었습니다.' : '사용자가 차단되었습니다.',
                    ),
                  ),
                );
                setState(() {
                  widget.isBlocked = !widget.isBlocked;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('실패: ${channelViewModel.errorMessage}')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록은 여기에서 구현할 수 있습니다.
          Expanded(
            child: Consumer<ChatMessageViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.errorMessage.isNotEmpty) {
                  return Center(child: Text(viewModel.errorMessage));
                }

                if (viewModel.messages.isEmpty) {
                  return const Center(child: Text('첫 대화를 시작해보세요'));
                }

                return ListView.builder(
                  itemCount: viewModel.messages.length,
                  itemBuilder: (context, index) {
                    final message = viewModel.messages[index];
                    return ListTile(
                      title: Text(message['message'] ?? ''),
                      subtitle: Text(message['userId'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Enter message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (_messageController.text.isNotEmpty) {
                        final viewModel = Provider.of<ChatMessageViewModel>(
                            context,
                            listen: false);
                        await viewModel.sendMessage(
                          channelId: widget.channelId,
                          sendUserId: widget.sendUserId,
                          receiveUserId: widget.receiveUserId,
                          message: _messageController.text,
                        );
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (context.watch<ChatMessageViewModel>().isLoading)
            const LinearProgressIndicator(),
          if (context.watch<ChatMessageViewModel>().errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.watch<ChatMessageViewModel>().errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
