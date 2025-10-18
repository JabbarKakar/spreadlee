import 'package:equatable/equatable.dart';

abstract class TicketsEvent extends Equatable {
  const TicketsEvent();

  @override
  List<Object?> get props => [];
}

class GetTicketsEvent extends TicketsEvent {}

class CreateTicketEvent extends TicketsEvent {
  final String title;
  final String description;

  const CreateTicketEvent({
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [title, description];
}
