import 'package:equatable/equatable.dart';
import '../../../../domain/chat_model.dart';

abstract class ChatCustomerState extends Equatable {
  const ChatCustomerState();

  @override
  List<Object> get props => [];
}

class ChatCustomerInitialState extends ChatCustomerState {
  const ChatCustomerInitialState();
}

class ChatCustomerLoadingState extends ChatCustomerState {
  const ChatCustomerLoadingState();
}

class ChatCustomerSuccessState extends ChatCustomerState {
  final List<Chats> chats;

  const ChatCustomerSuccessState(this.chats);

  @override
  List<Object> get props => [chats];
}

class ChatCustomerErrorState extends ChatCustomerState {
  final String error;

  const ChatCustomerErrorState(this.error);

  @override
  List<Object> get props => [error];
}

class ChatCustomerMessagesLoadingState extends ChatCustomerState {
  final String chatId;

  const ChatCustomerMessagesLoadingState({
    required this.chatId,
  });

  @override
  List<Object> get props => [chatId];
}

class ChatCustomerMessagesSuccessState extends ChatCustomerState {
  final List<ChatMessage> messages;
  final String chatId;
  final bool hasMore;
  final double? uploadProgress;

  const ChatCustomerMessagesSuccessState({
    required this.messages,
    required this.chatId,
    this.hasMore = true,
    this.uploadProgress,
  });

  @override
  List<Object> get props => [messages, chatId, hasMore, uploadProgress ?? 0.0];
}

class ChatCustomerMessagesErrorState extends ChatCustomerState {
  final String error;
  final String chatId;

  const ChatCustomerMessagesErrorState({
    required this.error,
    required this.chatId,
  });

  @override
  List<Object> get props => [error, chatId];
}
