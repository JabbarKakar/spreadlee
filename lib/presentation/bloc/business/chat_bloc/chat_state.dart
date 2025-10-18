import 'package:equatable/equatable.dart';
import '../../../../domain/chat_model.dart';

abstract class ChatBusinessState extends Equatable {
  const ChatBusinessState();

  @override
  List<Object> get props => [];
}

class ChatBusinessInitialState extends ChatBusinessState {
  const ChatBusinessInitialState();
}

class ChatBusinessLoadingState extends ChatBusinessState {
  const ChatBusinessLoadingState();
}

class ChatBusinessSuccessState extends ChatBusinessState {
  final List<Chats> chats;

  const ChatBusinessSuccessState(this.chats);

  @override
  List<Object> get props => [chats];
}

class ChatBusinessErrorState extends ChatBusinessState {
  final String error;

  const ChatBusinessErrorState(this.error);

  @override
  List<Object> get props => [error];
}

class ChatMessagesLoadingState extends ChatBusinessState {
  final String chatId;

  const ChatMessagesLoadingState({
    required this.chatId,
  });

  @override
  List<Object> get props => [chatId];
}

class ChatMessagesSuccessState extends ChatBusinessState {
  final List<ChatMessage> messages;
  final String chatId;
  final bool hasMore;
  final double? uploadProgress;

  const ChatMessagesSuccessState({
    required this.messages,
    required this.chatId,
    this.hasMore = true,
    this.uploadProgress,
  });

  @override
  List<Object> get props => [messages, chatId, hasMore, uploadProgress ?? 0.0];
}

class ChatMessagesErrorState extends ChatBusinessState {
  final String error;
  final String chatId;

  const ChatMessagesErrorState({
    required this.error,
    required this.chatId,
  });

  @override
  List<Object> get props => [error, chatId];
}
