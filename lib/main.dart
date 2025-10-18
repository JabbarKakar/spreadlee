import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/core/app.dart';
import 'package:spreadlee/core/di.dart';
import 'package:spreadlee/core/languages_manager.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/services/media_cache_service.dart';
import 'package:spreadlee/presentation/bloc/bloc_observer.dart';
import 'package:spreadlee/presentation/bloc/business/chat_bloc/chat_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/review_bloc/review_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/tax_invoices_bloc/tax_invoices_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/chat_bloc/chat_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/client_request_bloc/client_request_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/customer_company_bloc/customer_company_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/otp_customer_bloc/otp_customer_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/tickets_bloc/tickets_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/my_wallet/wallet_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/auth_bloc/auth_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/invoices_bloc/invoices_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/subaccounts/subaccounts_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/tickets_bloc/tickets_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/home_customer_bloc/home_customer_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/invoices_bloc/invoices_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/login_customer_bloc/login_customer_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/reviews_bloc/reviews_cubit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_cubit.dart';
import 'package:spreadlee/services/force_logout_service.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/providers/user_status_provider.dart';
import 'package:spreadlee/providers/presence_provider.dart';
import 'package:spreadlee/services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize permission handler
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();

  // Initialize media cache service
  final mediaCacheService = MediaCacheService();
  await mediaCacheService.init();
  instance.registerLazySingleton<MediaCacheService>(() => mediaCacheService);

  await initAppModule(); // <-- Move this up here, before runApp!

  DioHelper.init();
  Bloc.observer = MyBlocObserver();

  // Initialize the global force logout service
  ForceLogoutService.initialize();

  runApp(MultiBlocProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) {
          final provider = UserStatusProvider();
          if (Constants.userId.isNotEmpty && Constants.token.isNotEmpty) {
            provider.connect(Constants.userId, Constants.token);
          }
          return provider;
        },
      ),
      ChangeNotifierProvider(
        create: (_) => PresenceProvider(),
      ),
      Provider<ChatService>(
        create: (_) => instance<ChatService>(),
      ),
      BlocProvider(
        create: (_) => LoginCubit(),
      ),
      BlocProvider(
        create: (_) => OtpCubit(),
      ),
      BlocProvider(
        create: (_) => HomeCubit(),
      ),
      BlocProvider(
        create: (_) => CustomerCompanyCubit(),
      ),
      BlocProvider(
        create: (_) => ClientRequestCubit(),
      ),
      BlocProvider(
        create: (_) => TicketsCubit(),
      ),
      BlocProvider(
        create: (_) => TicketsBusinessCubit(),
      ),
      BlocProvider(
        create: (_) => InvoicesBusinessCubit(),
      ),
      BlocProvider(
        create: (_) => InvoicesCubit(),
      ),
      BlocProvider(
        create: (_) => AuthCubit(),
      ),
      BlocProvider(
        create: (_) => SettingCubit(),
      ),
      BlocProvider(
        create: (_) => WalletCubit(),
      ),
      BlocProvider(
        create: (_) => SubaccountsCubit(),
      ),
      BlocProvider(
        create: (_) => ClientRequestCubit(),
      ),
      BlocProvider(
        create: (_) => PaymentCubit(),
      ),
      BlocProvider(
        create: (_) => ReviewCompanyCubit(),
      ),
      BlocProvider(
        create: (_) => TaxInvoicesCubit(),
      ),
      BlocProvider(
        create: (_) => ChatBusinessCubit(),
      ),
      BlocProvider(
        create: (_) => ChatCustomerCubit(),
      ),
      BlocProvider(
        create: (_) => ClientRequestsCubit(),
      ),
      BlocProvider(
        create: (_) => ReviewsCubit(),
      ),
    ],
    child: EasyLocalization(
        supportedLocales: const [ARABIC_LOCALE, ENGLISH_LOCALE],
        path: ASSET_PATH_LOCALE,
        child: Phoenix(child: MyApp())),
  ));
  await ScreenUtil.ensureScreenSize();
}
