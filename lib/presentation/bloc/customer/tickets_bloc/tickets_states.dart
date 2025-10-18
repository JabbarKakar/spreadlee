import 'package:equatable/equatable.dart';
import 'package:spreadlee/domain/tickets_model.dart';

abstract class TicketsState extends Equatable {
  const TicketsState();

  @override
  List<Object?> get props => [];
}

class TicketsInitialState extends TicketsState {}

class TicketsLoadingState extends TicketsState {}

class TicketsSuccessState extends TicketsState {
  final List<TicketData> tickets;

  const TicketsSuccessState(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

class TicketsEmptyState extends TicketsState {}

class TicketsErrorState extends TicketsState {
  final String error;

  const TicketsErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

// Create Ticket States
class CreateTicketLoadingState extends TicketsState {}

class CreateTicketSuccessState extends TicketsState {
  final TicketData ticket;

  const CreateTicketSuccessState(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class CreateTicketErrorState extends TicketsState {
  final String error;

  const CreateTicketErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
