import 'package:equatable/equatable.dart';

abstract class TicketsBusinessEvent extends Equatable {
  const TicketsBusinessEvent();

  @override
  List<Object?> get props => [];
}

class GetTicketsBusinessEvent extends TicketsBusinessEvent {}

class CreateTicketBusinessEvent extends TicketsBusinessEvent {
  final String title;
  final String description;

  const CreateTicketBusinessEvent({
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [title, description];
}
