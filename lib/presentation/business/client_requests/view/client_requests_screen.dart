import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_cubit.dart';
import 'package:spreadlee/presentation/business/client_requests/widget/client_requests_page.dart';

class ClientRequestsScreen extends StatelessWidget {
  const ClientRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientRequestsCubit(),
      child: const ClientRequestsPage(),
    );
  }
}
