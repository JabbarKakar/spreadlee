import 'package:equatable/equatable.dart';
import 'package:spreadlee/domain/tickets_model.dart';

abstract class TicketsBusinessState extends Equatable {
  const TicketsBusinessState();

  @override
  List<Object?> get props => [];
}

class TicketsBusinessInitialState extends TicketsBusinessState {}

class TicketsBusinessLoadingState extends TicketsBusinessState {}

class TicketsBusinessSuccessState extends TicketsBusinessState {
  final List<TicketData> tickets;

  const TicketsBusinessSuccessState(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

class TicketsBusinessEmptyState extends TicketsBusinessState {}

class TicketsBusinessErrorState extends TicketsBusinessState {
  final String error;

  const TicketsBusinessErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

// Create Ticket States
class CreateTicketBusinessLoadingState extends TicketsBusinessState {}

class CreateTicketBusinessSuccessState extends TicketsBusinessState {
  final TicketData ticket;

  const CreateTicketBusinessSuccessState(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class CreateTicketBusinessErrorState extends TicketsBusinessState {
  final String error;

  const CreateTicketBusinessErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
