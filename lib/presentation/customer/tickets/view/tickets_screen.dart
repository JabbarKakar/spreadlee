import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/business/chat/view/chat_screen.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/domain/tickets_model.dart';
import 'package:spreadlee/domain/chat_model.dart' as chat_model;
import 'package:spreadlee/presentation/bloc/customer/tickets_bloc/tickets_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/tickets_bloc/tickets_states.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Helper method to convert ChatData to Chats object
  chat_model.Chats? _convertChatDataToChats(ChatData? chatData) {
    if (chatData == null) return null;

    return chat_model.Chats(
      sId: chatData.sId,
      chatLastMessage: chatData.chatLastMessage != null
          ? chat_model.ChatLastMessage(
              sId: chatData.chatLastMessage,
              messageText: chatData.chatLastMessage,
              messageDate: DateTime.now().toIso8601String(),
              messageCreator: null,
            )
          : null,
      chatCompanyName: chatData.chatCompanyName,
      chatCustomerCompanyName: chatData.chatCustomerCompanyName,
      chatCustomerCommercialName: chatData.chatCustomerCommercialName,
      chatUsers: chatData.chatUsers != null
          ? chat_model.ChatUsers(
              customerId: chatData.chatUsers!.customerId,
              companyId: chatData.chatUsers!.companyId != null
                  ? chat_model.CompanyId(
                      sId: chatData.chatUsers!.customerId,
                      companyName: chatData.chatCompanyName,
                      commercialName: chatData.chatCustomerCommercialName,
                    )
                  : null,
            )
          : null,
      isDeleted: chatData.isDeleted,
      isClosed: chatData.isClosed,
      isTicketChat: chatData.isTicketChat,
      isActive: chatData.isActive,
      isAdminJoined: chatData.isAdminJoined,
      participants: chatData.participants
          ?.map((p) => p.userId ?? '')
          .where((id) => id.isNotEmpty)
          .toList(),
      createdAt: chatData.createdAt,
      updatedAt: chatData.updatedAt,
      chatNotSeenMessages: chatData.chatNotSeenMessages,
    );
  }

  Widget _buildTicketItem(TicketData ticket) {
    final DateTime createdDate = DateTime.parse(ticket.createdAt ?? '');
    final String formattedDate =
        DateFormat('EEEE, MMM d, y, HH:mm').format(createdDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${ticket.ticketNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            if (ticket.status == 'follow_up' &&
                ticket.chatId?.isActive == true) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    minimumSize: const Size(0, 32),
                    side: BorderSide(
                        color: ColorManager.blueLight800, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: ticket.chatId?.sId ?? '',
                          userId: ticket.chatId?.chatUsers?.customerId ?? '',
                          userRole: 'customer',
                          companyName:
                              ticket.chatId?.chatCustomerCompanyName ?? '',
                          isOnline: ticket.chatId?.isActive ?? false,
                          chat: _convertChatDataToChats(ticket.chatId),
                          isTicketChat: true,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 10,
                      color: ColorManager.blueLight800,
                    ),
                  ),
                ),
              ),
            ] else if (ticket.status == 'closed' &&
                ticket.chatId?.isClosed == true) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    minimumSize: const Size(0, 32),
                    side: BorderSide(color: Colors.grey[600]!, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: ticket.chatId?.sId ?? '',
                          userId: ticket.chatId?.chatUsers?.customerId ?? '',
                          userRole: 'customer',
                          companyName:
                              ticket.chatId?.chatCustomerCompanyName ?? '',
                          isOnline: ticket.chatId?.isActive ?? false,
                          chat: _convertChatDataToChats(ticket.chatId),
                          isTicketChat: true,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TicketData> _getTicketsByStatus(
      List<TicketData> tickets, String status) {
    return tickets.where((ticket) => ticket.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = TicketsCubit();
        cubit.initFToast(context);
        cubit.getTickets();
        return cubit;
      },
      child: BlocBuilder<TicketsCubit, TicketsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: ColorManager.gray50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pushReplacementNamed(
                    context, Routes.contactUsRoute),
              ),
              title: Text(
                AppStrings.allTickets.tr(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: ColorManager.blueLight800,
                unselectedLabelColor: Colors.black,
                indicatorColor: ColorManager.blueLight800,
                labelStyle: const TextStyle(fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.only(bottom: 8),
                tabs: const [
                  Tab(
                    text: 'Pending tickets',
                    height: 40,
                  ),
                  Tab(
                    text: 'Follow up Tickets',
                    height: 40,
                  ),
                  Tab(
                    text: 'Solved tickets',
                    height: 40,
                  ),
                ],
              ),
            ),
            body: state is TicketsLoadingState
                ? const Center(child: CircularProgressIndicator())
                : state is TicketsSuccessState
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          // Pending Tickets Tab
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount:
                                _getTicketsByStatus(state.tickets, 'pending')
                                    .length,
                            itemBuilder: (context, index) => _buildTicketItem(
                                _getTicketsByStatus(
                                    state.tickets, 'pending')[index]),
                          ),
                          // Follow up Tickets Tab
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount:
                                _getTicketsByStatus(state.tickets, 'follow_up')
                                    .length,
                            itemBuilder: (context, index) => _buildTicketItem(
                                _getTicketsByStatus(
                                    state.tickets, 'follow_up')[index]),
                          ),
                          // Solved Tickets Tab
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount:
                                _getTicketsByStatus(state.tickets, 'closed')
                                    .length,
                            itemBuilder: (context, index) => _buildTicketItem(
                                _getTicketsByStatus(
                                    state.tickets, 'closed')[index]),
                          ),
                        ],
                      )
                    : state is TicketsEmptyState
                        ? Center(
                            child: Text(
                              'No tickets found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : state is TicketsErrorState
                            ? Center(
                                child: Text(
                                  state.error,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            : const SizedBox(),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(30),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                      context, Routes.createTicketRoute);
                  if (result == true) {
                    if (mounted) {
                      context.read<TicketsCubit>().getTickets();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.blueLight800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Create New Ticket',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
