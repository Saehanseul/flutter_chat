import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/repos/chat_channel_repo.dart';
import 'package:flutter_chat/features/chat/repos/chat_message_repo.dart';

class ChatMessageViewModel extends ChangeNotifier {
  final ChatMessageRepo _chatMessageRepo = ChatMessageRepo();
  final ChatChannelRepo _chatChannelRepo = ChatChannelRepo();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setMessages(List<Map<String, dynamic>> messages) {
    _messages = messages;
    notifyListeners();
  }

  /// 메시지 전송
  /// 현재는 text message만 고려
  /// 추후 비즈니스 로직에 따라 messageType 으로 image, file 등 추가 가능
  /// metaPathList: 이미지, 파일 전송시 사용
  Future<void> sendMessage({
    required String channelId,
    required String sendUserId,
    required String receiveUserId,
    required String message,
    String messageType = 'text',
    List<String>? metaPathList,
  }) async {
    _setLoading(true);

    // 채널 차단 여부 확인
    bool? isBlocked = await _chatChannelRepo.isChannelBlocked(channelId);
    if (isBlocked != false) {
      _setLoading(false);
      return;
    }

    bool isSuccess = await _chatMessageRepo.sendMessage(
      channelId: channelId,
      sendUserId: sendUserId,
      receiveUserId: receiveUserId,
      message: message,
      messageType: messageType,
      metaPathList: metaPathList,
    );
    if (isSuccess) {
      _setErrorMessage('');
      await _chatChannelRepo.updateChannelWithLastMessage(
        channelId: channelId,
        lastMessage: message,
        lastMessageSenderId: sendUserId,
      );
    } else {
      _setErrorMessage('메시지 전송 실패');
    }
    _setLoading(false);
  }

  /// 현재 참여한 채널의 메시지 구독
  void subscribeToMessages(String channelId) {
    _setLoading(true);

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatMessageRepo.subscribeToMessages(
      channelId: channelId,
      onData: (messages) {
        _setMessages(messages);
        _setLoading(false);
      },
      onError: (error) {
        _setErrorMessage(error);
        _setLoading(false);
      },
    );
  }

  /// 메시지 구독 취소
  void unsubscribeFromMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }

  // 현재는 구독 방식으로 바꿔서 사용x 추후 로직 변경시 재사용 가능
  // Future<void> fetchMessages(String channelId) async {
  //   _setLoading(true);
  //
  //   try {
  //     List<Map<String, dynamic>> messages =
  //         await _chatMessageRepo.getMessages(channelId);
  //     _setMessages(messages);
  //     _setErrorMessage('');
  //   } catch (e) {
  //     _setErrorMessage('메시지 로드 실패');
  //   }
  //
  //   _setLoading(false);
  // }

  /// 메시지 읽음 처리
  /// 해당 채널의 모든 메시지 읽음 처리 (해당 channel의 messages의 해당 유저의 모든 readStatus 업데이트)
  /// channel의 해당 유저 안읽은 메시지 카운트 0으로 업데이트
  Future<void> updateReadStatus({
    required String channelId,
    required String userId,
  }) async {
    _setLoading(true);

    // 해당 채널의 모든 메시지 읽음 처리
    bool isSuccess = await _chatMessageRepo.updateReadStatus(
      channelId: channelId,
      userId: userId,
    );
    if (isSuccess) {
      _setErrorMessage('');
      // channel의 해당 유저 안읽은 메시지 카운트 0으로 업데이트
      await _chatChannelRepo.updateUserUnreadCount(
          channelId: channelId, userId: userId, count: 0);
    } else {
      _setErrorMessage('읽음 상태 업데이트 실패');
    }
    _setLoading(false);
  }

  @override
  void dispose() {
    unsubscribeFromMessages();
    super.dispose();
  }
}
