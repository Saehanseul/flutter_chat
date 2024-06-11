import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/view_models/chat_channel_view_model.dart';
import 'package:flutter_chat/features/chat/views/chat_detail_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class ChatChannelListScreen extends StatefulWidget {
  final String userId;

  const ChatChannelListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ChatChannelListScreen> createState() => _ChatChannelListScreenState();
}

class _ChatChannelListScreenState extends State<ChatChannelListScreen> {
  ChatChannelViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      _viewModel = Provider.of<ChatChannelViewModel>(context, listen: false);
      Future.microtask(
          () => _viewModel!.subscribeToChatChannels(widget.userId));
    }
  }

  @override
  void dispose() {
    _viewModel?.unsubscribeFromChatChannels();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatChannelViewModel = Provider.of<ChatChannelViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Channels'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              if (chatChannelViewModel.isLoading)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: chatChannelViewModel.chatChannels.length,
                    itemBuilder: (context, index) {
                      final channel = chatChannelViewModel.chatChannels[index];
                      List<String> participants =
                          List<String>.from(channel['participantsIds']);
                      String otherUserId =
                          participants.firstWhere((id) => id != widget.userId);
                      String otherUserName = otherUserId; // 필요 시 이름 맵핑 로직 추가

                      return Slidable(
                        key: Key(channel['channelId']),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                // 핀 고정 로직을 여기에 추가하세요
                              },
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.push_pin,
                              label: '핀고정',
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                setState(() {
                                  chatChannelViewModel
                                      .deleteChannel(channel['channelId']);
                                  chatChannelViewModel.chatChannels
                                      .removeAt(index);
                                });
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: '삭제',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(otherUserName),
                          subtitle: Text('${channel['lastMessage'] ?? ''}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  channelId: channel['channelId'],
                                  otherUserName: otherUserName,
                                  sendUserId: widget.userId,
                                  receiveUserId: otherUserId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (chatChannelViewModel.errorMessage.isNotEmpty)
                Text(
                  chatChannelViewModel.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}