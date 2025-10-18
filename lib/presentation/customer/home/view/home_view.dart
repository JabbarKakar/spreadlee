import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/presentation/bloc/customer/home_customer_bloc/home_customer_cubit.dart';
import 'package:spreadlee/presentation/customer/home/widget/client_request.dart';
import 'package:spreadlee/presentation/customer/home/widget/drawer.dart';
import 'package:spreadlee/presentation/customer/home/widget/price_tag.dart';
import 'package:spreadlee/presentation/customer/home/widget/search.dart';
import 'package:spreadlee/presentation/resources/assets_manager.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/localStoreList.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import '../../../../domain/customer_home_model.dart';
import '../../../bloc/customer/home_customer_bloc/home_customer_states.dart';
import '../../../resources/routes_manager.dart';
import 'package:spreadlee/presentation/customer/home/widget/reviews_dialog.dart';
import 'package:spreadlee/core/utils/file_downloader.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  int _selectedCategoryIndex = -1;
  String? _selectedServiceName;
  String searchQuery = "";
  List<String> searchOnTheList = [];

  @override
  void initState() {
    context.read<HomeCubit>().getCustomerHomeData();
    context.read<HomeCubit>().fToast.init(context);
    super.initState();
  }

  Widget _buildLocationTag(String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorManager.customYellowF1D261,
          width: 1.0,
        ),
      ),
      child: Text(
        city,
        style: const TextStyle(
            color: ColorManager.customYellowF1D261,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    var cubit = HomeCubit.get(context);
    return Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: ColorManager.white,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                ImageManager.drawerIcon,
                width: 30,
                height: 30,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Opens the drawer manually
              },
            ),
          ),
          title: SearchTextField(
            onSearchChanged: (query) {
              setState(() {
                searchQuery = query; // Update search query in HomeView
              });
            },
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.filter_alt,
                      color: Colors.grey,
                      size: 25.0,
                    ),
                    iconSize: 40.0,
                    splashRadius: 20.0,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, Routes.customerFilterRoute);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: BlocConsumer<HomeCubit, HomeStates>(
          listener: (context, state) {},
          builder: (context, state) {
            // Get filtered list if data exists
            List<CustomerData> filteredList = [];
            if (state is HomeSuccessState) {
              filteredList = state.customerHomeModel.data
                      ?.where((customer) =>
                          (_selectedCategoryIndex == -1 ||
                              (customer.marketing_fields != null &&
                                  customer.marketing_fields!
                                      .contains(_selectedServiceName))) &&
                          (searchQuery.isEmpty ||
                              (customer.publicName != null &&
                                  customer.publicName!
                                      .toLowerCase()
                                      .contains(searchQuery.toLowerCase())) ||
                              (customer.commercialName != null &&
                                  customer.commercialName!
                                      .toLowerCase()
                                      .contains(searchQuery.toLowerCase()))))
                      .toList() ??
                  [];
            }

            return SafeArea(
              child: Column(
                children: [
                  // Services List
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 14.0),
                    child: SizedBox(
                      height: 65,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: servicesList.length,
                        itemBuilder: (context, index) {
                          final service = servicesList[index];
                          bool isSelected = index == _selectedCategoryIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                                _selectedServiceName = service.name;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      service.imagePath,
                                      width: 60,
                                      height: 65,
                                      fit: BoxFit.cover,
                                    ),
                                    if (isSelected)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        if (kDebugMode) {
                          print('Pull to refresh triggered');
                        }
                        context.read<HomeCubit>().getCustomerHomeData();
                      },
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 7.0, 0.0, 24.0),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  AppStrings.listOfInfluencersMarketingCompanies
                                      .tr(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0, bottom: 16.0),
                                    child: Text(
                                      '${AppStrings.total_results.tr()}: ${state is HomeSuccessState ? state.customerHomeModel.total : 0}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.grey,
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_selectedCategoryIndex != -1)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 16.0, 16.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryIndex = -1;
                                          _selectedServiceName = '';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 6.0),
                                        child: Text(
                                          'Clear Filter',
                                          style: TextStyle(
                                            color: ColorManager.blueLight800,
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (state is HomeLoadingState)
                              const Center(child: CircularProgressIndicator())
                            else if (state is HomeRefreshingState)
                              const Center(child: CircularProgressIndicator())
                            else if (state is HomeErrorState)
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      "No Connection With The Server",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (state is HomeSuccessState &&
                                filteredList.isEmpty)
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      "No Results Found",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final customer = filteredList[index];

                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 0.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: customer.price_tag ==
                                                    'Moderate Price'
                                                ? ColorManager.customBlue677BA9
                                                : customer.price_tag ==
                                                        'Low Price'
                                                    ? ColorManager
                                                        .customGreen759787
                                                    : ColorManager
                                                        .customYellowF1D261,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 44.0,
                                                    height: 44.0,
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22.0),
                                                      child: customer.photoUrl !=
                                                                  null &&
                                                              customer.photoUrl!
                                                                  .isNotEmpty
                                                          ? Image.network(
                                                              customer
                                                                  .photoUrl!,
                                                              width: 56.0,
                                                              height: 56.0,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Container(
                                                                  width: 56.0,
                                                                  height: 56.0,
                                                                  color: ColorManager
                                                                      .gray200,
                                                                  child: Icon(
                                                                    Icons
                                                                        .person,
                                                                    color: ColorManager
                                                                        .gray400,
                                                                    size: 28,
                                                                  ),
                                                                );
                                                              },
                                                              loadingBuilder:
                                                                  (context,
                                                                      child,
                                                                      loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null) {
                                                                  return child;
                                                                }
                                                                return Container(
                                                                  width: 56.0,
                                                                  height: 56.0,
                                                                  color: ColorManager
                                                                      .gray200,
                                                                  child: Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      value: loadingProgress.expectedTotalBytes !=
                                                                              null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            )
                                                          : Container(
                                                              width: 56.0,
                                                              height: 56.0,
                                                              color:
                                                                  ColorManager
                                                                      .gray200,
                                                              child: Icon(
                                                                Icons.person,
                                                                color:
                                                                    ColorManager
                                                                        .gray400,
                                                                size: 28,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        customer.role ==
                                                                'influencer'
                                                            ? customer
                                                                    .publicName ??
                                                                '-'
                                                            : customer
                                                                    .commercialName ??
                                                                '-',
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        customer.role ==
                                                                'influencer'
                                                            ? 'Influencer'
                                                            : 'Marketing Company',
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  PriceTagWidget(
                                                      priceTag:
                                                          customer.price_tag),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              if (customer.role !=
                                                      'influencer' &&
                                                  customer.marketing_fields !=
                                                      null &&
                                                  customer.marketing_fields!
                                                      .isNotEmpty)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      AppStrings.sow.tr(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 10,
                                                          fontFamily:
                                                              'Poppins'),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Wrap(
                                                      spacing: 6.0,
                                                      runSpacing: 6.0,
                                                      children: [
                                                        ...customer
                                                            .marketing_fields!
                                                            .take(11)
                                                            .map(
                                                          (field) {
                                                            if (serviceIcons
                                                                .containsKey(
                                                                    field)) {
                                                              return Image
                                                                  .asset(
                                                                serviceIcons[
                                                                    field]!,
                                                                width: 35,
                                                                height: 35,
                                                              );
                                                            } else {
                                                              return const SizedBox();
                                                            }
                                                          },
                                                        ),
                                                        if (customer.marketing_fields!
                                                                    .length >
                                                                11 &&
                                                            serviceIcons
                                                                .containsKey(
                                                                    customer.marketing_fields![
                                                                        11]))
                                                          Image.asset(
                                                            serviceIcons[customer
                                                                    .marketing_fields![
                                                                11]]!,
                                                            width: 38,
                                                            height: 38,
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 20),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    AppStrings.available_in
                                                        .tr(),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10,
                                                        fontFamily: 'Poppins'),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Wrap(
                                                    spacing: 6.0,
                                                    runSpacing: 6.0,
                                                    children: [
                                                      ...customer.cityNames!
                                                          .take(4)
                                                          .map((city) =>
                                                              _buildLocationTag(
                                                                  city)),
                                                      if (customer.cityNames!
                                                              .length >
                                                          4)
                                                        _buildLocationTag(
                                                            "..."),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 4,
                                                                horizontal: 8),
                                                        minimumSize:
                                                            const Size(0, 32),
                                                        side: BorderSide(
                                                            color: ColorManager
                                                                .blueLight800,
                                                            width: 1.0),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            Dialog(
                                                          backgroundColor:
                                                              Colors.white,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.85,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        24,
                                                                    vertical:
                                                                        8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    const Text(
                                                                      'Details',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight: FontWeight
                                                                              .w500,
                                                                          fontFamily:
                                                                              'Poppins'),
                                                                    ),
                                                                    const SizedBox(
                                                                      width:
                                                                          100,
                                                                    ),
                                                                    GestureDetector(
                                                                      onTap: () =>
                                                                          Navigator.pop(
                                                                              context),
                                                                      child:
                                                                          const Icon(
                                                                        Icons
                                                                            .close,
                                                                        size:
                                                                            24,
                                                                        color: Colors
                                                                            .black54,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 24),
                                                                Row(
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: ColorManager
                                                                            .white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .description,
                                                                        color: ColorManager
                                                                            .blueLight800,
                                                                        size:
                                                                            24,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    const Flexible(
                                                                      child:
                                                                          Text(
                                                                        'Service & Description.pdf',
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color: Colors.black87,
                                                                            fontFamily: 'Poppins'),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 24),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          SizedBox(
                                                                        height:
                                                                            35,
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () async {
                                                                            final result =
                                                                                await FileDownloader.downloadFile(
                                                                              customer.pricingDetails ?? '',
                                                                              'Service & Description',
                                                                            );
                                                                            Navigator.pop(context);
                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              SnackBar(
                                                                                content: Text(
                                                                                  result,
                                                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins'),
                                                                                ),
                                                                                duration: const Duration(milliseconds: 4000),
                                                                                backgroundColor: result == 'Error downloading file' ? Colors.red : Colors.green,
                                                                              ),
                                                                            );
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                ColorManager.blueLight800,
                                                                            foregroundColor:
                                                                                Colors.white,
                                                                            elevation:
                                                                                0,
                                                                            padding:
                                                                                EdgeInsets.zero,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              const Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                'Download',
                                                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                                                                              ),
                                                                              SizedBox(width: 5),
                                                                              Icon(
                                                                                Icons.download,
                                                                                size: 14,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            6),
                                                                    Expanded(
                                                                      child:
                                                                          SizedBox(
                                                                        height:
                                                                            35,
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.pushNamed(
                                                                              context,
                                                                              Routes.pdfViewRoute,
                                                                              arguments: {
                                                                                'pdfUrl': customer.pricingDetails ?? '', // Replace with your actual PDF URL
                                                                              },
                                                                            );
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                ColorManager.blueLight800,
                                                                            foregroundColor:
                                                                                Colors.white,
                                                                            elevation:
                                                                                0,
                                                                            padding:
                                                                                EdgeInsets.zero,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              const Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                'View File',
                                                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                                                                              ),
                                                                              SizedBox(width: 5),
                                                                              Icon(
                                                                                Icons.visibility,
                                                                                size: 14,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 20,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        AppStrings.details.tr(),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: ColorManager
                                                                .blueLight800,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 4,
                                                                horizontal: 8),
                                                        minimumSize:
                                                            const Size(0, 32),
                                                        side: BorderSide(
                                                            color: ColorManager
                                                                .blueLight800,
                                                            width: 1.0),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        ReviewsDialog.show(
                                                          context,
                                                          customer.sId ?? '',
                                                        );
                                                      },
                                                      child: Text(
                                                        AppStrings.reviews.tr(),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: ColorManager
                                                                .blueLight800,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 4,
                                                                horizontal: 8),
                                                        minimumSize:
                                                            const Size(0, 32),
                                                        side: BorderSide(
                                                            color: ColorManager
                                                                .blueLight800,
                                                            width: 1.0),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Future.delayed(
                                                            const Duration(
                                                                milliseconds:
                                                                    500),
                                                            () async {
                                                          ClientRequestDialog
                                                              .show(
                                                            context,
                                                            (selectedCountry) async {
                                                              // You can use customer.id here
                                                              print(
                                                                  "Customer ID: ${customer.sId}");
                                                              // Call your API or handle the logic
                                                            },
                                                            customerId: customer
                                                                .sId, // pass ID directly to the dialog if needed
                                                          );
                                                        });
                                                      },
                                                      child: Text(
                                                        AppStrings.chat.tr(),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: ColorManager
                                                                .blueLight800,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ));
  }
}
