import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/controller/book_your_service_controller.dart';
import 'package:plotrol/controller/create_account_controller.dart';
import 'package:plotrol/controller/home_screen_controller.dart';
import 'package:plotrol/globalWidgets/text_widget.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/view/ongoing_task.dart';
import 'package:plotrol/view/order_details.dart';
import 'package:plotrol/view/profile.dart';
import 'package:plotrol/view/properties_details.dart';
import 'package:plotrol/view/singup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../globalWidgets/flutter_toast.dart';
import '../helper/const_assets_const.dart';
import '../model/response/autentication_response/autentication_response.dart';
import '../model/response/book_service/pgr_create_response.dart';
import '../widgets/thumbnail_collage.dart';
import 'all_properties_dart.dart';
import 'book_your_service.dart';
import 'view_all_orders_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeScreenController controller = Get.put(HomeScreenController());

  final AuthenticationController authController =
      Get.put(AuthenticationController());

  final CreateAccountController createAccountController =
      Get.put(CreateAccountController());

  final BookYourServiceController bookYourServiceController =
      Get.put(BookYourServiceController());

  DateTime? currentBackPressTime;

  Future<bool> _willPopCallback() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 1)) {
      currentBackPressTime = now;
      Toast.showToast("Press one more time to exit");
      return Future.value(false);
    } else {
      Get.back();
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetBuilder<HomeScreenController>(initState: (_) async {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final prefs = await SharedPreferences.getInstance();

            if (prefs.getString('access_token') == null) {
              Get.offAll(() => LoginScreen());
              return;
            }

            final userInfoString = prefs.getString('userInfo');
            final userRequest =
                UserRequest.fromJson(jsonDecode(userInfoString!));

            controller.getDetails();
            controller.isPropertyLoading.value =
                AppUtils().checkIsHousehold(userRequest.roles ?? []) &&
                    !AppUtils().checkIsPGRAdmin(userRequest.roles ?? []);

            bookYourServiceController.isCategoryLoading.value =
                AppUtils().checkIsHousehold(userRequest.roles ?? []) &&
                    !AppUtils().checkIsPGRAdmin(userRequest.roles ?? []);

            controller.getTenantApiFunction();
            controller.getOrdersApiFunction();

            if (AppUtils().checkIsHousehold(userRequest.roles ?? []) &&
                !AppUtils().checkIsPGRAdmin(userRequest.roles ?? [])) {
              controller.getPropertiesApiFunction();
              bookYourServiceController.getCategories();
            }
          });
        }, builder: (controller) {
          return WillPopScope(
            onWillPop: () => _willPopCallback(),
            child: SafeArea(
              child: Scaffold(
                backgroundColor: const Color(0xFFF8F9FA),
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      title: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              minRadius: 28,
                              maxRadius: 28,
                              backgroundColor: Colors.transparent,
                              child: (controller.profileImage.value.isNotEmpty)
                                  ? ClipOval(
                                      child: !controller.isTenantDetailLoading.value
                                          ? Image.network(
                                              fit: BoxFit.cover,
                                              width: 56,
                                              height: 56,
                                              controller.tenantProfileImage.value,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.network(
                                                  ImageAssetsConst.sampleRoomPage,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;

                                                final total = loadingProgress
                                                    .expectedTotalBytes;
                                                final loaded = loadingProgress
                                                    .cumulativeBytesLoaded;
                                                final progress = total != null
                                                    ? loaded / total
                                                    : null;

                                                return SizedBox(
                                                  height: 56,
                                                  width: 56,
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        CircularProgressIndicator(
                                                            value: progress),
                                                        const SizedBox(height: 4),
                                                        if (progress != null)
                                                          Text(
                                                              '${(progress * 100).toStringAsFixed(0)}%',
                                                              style: const TextStyle(fontSize: 10)),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.white,
                                              ),
                                            ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: ReusableTextWidget(
                                          text: authController.getInitials(
                                                  controller.name.value ?? '',
                                                  controller.lastName.value) ??
                                              '',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: 3.h,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReusableTextWidget(
                                  text:
                                      'Hi ${controller.tenantFirstName.toUpperCase()}',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  maxLines: 1,
                                ),
                                SizedBox(
                                  height: 0.5.h,
                                ),
                                const ReusableTextWidget(
                                  text: 'Ready to book a service?',
                                  fontSize: 13,
                                  color: Colors.grey,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.black87,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ReusableTextWidget(
                          text: 'Book Your Services',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                        SizedBox(
                          height: 1.5.h,
                        ),
                        SizedBox(height: 130, child: CategoriesTypeWidget()),
                        SizedBox(
                          height: 2.h,
                        ),
                        Row(
                          children: [
                            const ReusableTextWidget(
                              text: 'Ongoing Tasks',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Get.to(() => ViewAllOrdersScreen());
                              },
                              child: (controller.createdOrders.isNotEmpty)
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const ReusableTextWidget(
                                        text: 'View All',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 1.5.h,
                        ),
                        OnGoingTask(
                          status: 'created',
                          maxItems: 5,
                        ),
                        SizedBox(
                          height: 3.h,
                        ),
                        Row(
                          children: [
                            const ReusableTextWidget(
                              text: 'Your Properties',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Get.to(() => AllProperties());
                              },
                              child:
                                  (controller.getPropertiesDetails.isNotEmpty)
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const ReusableTextWidget(
                                            text: 'See All',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        )
                                      : const SizedBox(),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 1.5.h,
                        ),
                        PropertyWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

/// Property widget
class PropertyWidget extends StatelessWidget {
  PropertyWidget({
    super.key,
  });

  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenController>(builder: (controller) {
      return (controller.getPropertiesDetails.isEmpty &&
              !controller.isPropertyLoading.value)
          ? Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    ReusableTextWidget(
                      text: 'No properties found',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    ReusableTextWidget(
                      text: 'Add your properties to get started',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.getPropertiesDetails.length,
                itemBuilder: (context, index) {
                  return controller.isPropertyLoading.value
                      ? _buildShimmerCard()
                      : Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => PropertiesDetailsScreen(
                                    propertyImage: controller
                                        .getPropertiesDetails[index]
                                        .imageUrls,
                                    address: AppUtils().formatAddress(
                                        controller
                                            .getPropertiesDetails[index]
                                            .address),
                                    contactNumber: controller
                                            .getPropertiesDetails[index]
                                            .additionalFields
                                            ?.fields
                                            ?.where((a) =>
                                                a.key == 'contactNo')
                                            .first
                                            .value ??
                                        '',
                                  ));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    child: ThumbCollage(
                                      urls: controller
                                              .getPropertiesDetails[index]
                                              .imageUrls ??
                                          [],
                                      height: 120,
                                      width: double.infinity,
                                      borderRadius: 20,
                                      spacing: 2,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ReusableTextWidget(
                                            text:
                                                '${controller.getPropertiesDetails[index].additionalFields?.fields?.where((a) => a.key == 'notes').first.value}',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          ReusableTextWidget(
                                            maxLines: 2,
                                            text: AppUtils().formatAddress(controller
                                                .getPropertiesDetails[index].address),
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 32,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                              ),
                                              onPressed: () {
                                                Get.to(() => BookYourService(
                                                      householdModel: controller
                                                              .getPropertiesDetails[
                                                          index],
                                                      tenantImage: controller
                                                          .getPropertiesDetails[
                                                              index]
                                                          .imageUrls,
                                                      address: AppUtils()
                                                          .formatAddress(controller
                                                              .getPropertiesDetails[
                                                                  index]
                                                              .address),
                                                      contactNumber: controller
                                                              .getPropertiesDetails[
                                                                  index]
                                                              .additionalFields
                                                              ?.fields
                                                              ?.where((a) =>
                                                                  a.key ==
                                                                  'contactNo')
                                                              .firstOrNull
                                                              ?.value ??
                                                          '',
                                                    ));
                                              },
                                              child: const ReusableTextWidget(
                                                text: 'BOOK SERVICE',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
    });
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[300]!,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 32,
                        width: double.infinity,
                        color: Colors.grey[300]!,
                      ),
                      const Spacer(),
                      Container(
                        height: 32,
                        width: double.infinity,
                        color: Colors.grey[300]!,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category Widget
class CategoriesTypeWidget extends StatelessWidget {
  CategoriesTypeWidget({super.key});

  final BookYourServiceController controller =
      Get.put(BookYourServiceController());

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (BuildContext context, Orientation orientation, screenType) {
        return GetBuilder<BookYourServiceController>(builder: (controller) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.listOfCategories.length,
            itemBuilder: (context, index) {
              return controller.isCategoryLoading.value
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        margin: const EdgeInsets.only(right: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 60,
                              height: 12,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        Get.to(() => AllProperties(
                              selectedCategory: controller
                                      .listOfCategories[index].categoryname ??
                                  '',
                              isFromCategory: true,
                            ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade100,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  controller.listOfCategories[index].serviceimage ??
                                      '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ReusableTextWidget(
                              text: controller
                                      .listOfCategories[index].categoryname ??
                                  '',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ],
                        ),
                      ),
                    );
            },
          );
        });
      },
    );
  }
}

/// OnGoing Task widget
class OnGoingTask extends StatelessWidget {
  final bool isVerticalScrollable;
  final bool isForStatusScreen;
  final String status;
  final int? maxItems;

  const OnGoingTask({
    super.key,
    this.isVerticalScrollable = false,
    this.isForStatusScreen = false,
    this.status = '',
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final HomeScreenController homeScreenController =
        Get.put(HomeScreenController());
    return GetBuilder<HomeScreenController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeScreenController.updateLoadingState();
          homeScreenController.getOrdersApiFunction();
        });
      },
      builder: (controller) {
        if (homeScreenController.isOrderLoading.value) {
          return SizedBox(
            height: MediaQuery.of(context).size.height / 3,
            child: buildShimmerLoader(),
          );
        }

        if (homeScreenController.getOrderDetails.isEmpty) {
          return Container(
            height: MediaQuery.of(context).size.height / 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  ReusableTextWidget(
                    text: 'No Ongoing Tasks',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  ReusableTextWidget(
                    text: 'Book a service to get started',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }

        if (isVerticalScrollable) {
          if (status == 'created') {
            final orders = isForStatusScreen
                ? controller.todayCreatedOrders
                : controller.createdOrders;
            if (orders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      ReusableTextWidget(
                        text: 'No Created Orders Found',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? null
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: maxItems != null
                  ? (orders.length > maxItems! ? maxItems! : orders.length)
                  : orders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(orders[index]);
              },
            );
          }
          if (status == 'pending') {
            if (controller.pendingOrders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_actions_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      ReusableTextWidget(
                        text: 'No Pending Orders Found',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? null
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.pendingOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.pendingOrders[index]);
              },
            );
          }
          if (status == 'accepted') {
            if (controller.acceptedOrders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      ReusableTextWidget(
                        text: 'No Accepted Orders Found',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? null
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.acceptedOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.acceptedOrders[index]);
              },
            );
          } else if (status == 'completed') {
            final completedList = controller.completedOrders;
            if (completedList.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.done_all_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      ReusableTextWidget(
                        text: 'No Completed Tasks Found',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? null
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: completedList.length,
              itemBuilder: (context, index) {
                return buildOrderItem(completedList[index]);
              },
            );
          } else if (status == 'active') {
            if (controller.activeOrders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      ReusableTextWidget(
                        text: 'No Active Orders Found',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? null
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.activeOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.activeOrders[index]);
              },
            );
          } else {
            if (controller.todayOrders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      const ReusableTextWidget(
                        text: 'No Orders Found for Today',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          Get.to(() => ViewAllOrdersScreen());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const ReusableTextWidget(
                            text: 'Go to Inbox',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: controller.todayOrders.length,
                itemBuilder: (context, index) {
                  return buildOrderItem(controller.todayOrders[index]);
                },
              ),
            );
          }
        } else {
          if (controller.createdOrders.isEmpty) {
            return Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    ReusableTextWidget(
                      text: 'No Active Orders Found',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          }
          return SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: maxItems != null
                  ? (controller.createdOrders.length > maxItems!
                      ? maxItems!
                      : controller.createdOrders.length)
                  : controller.createdOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.createdOrders[index]);
              },
            ),
          );
        }
      },
    );
  }

  Widget buildOrderItem(ServiceWrapper order) {
    return GestureDetector(
      onTap: () {
        try {
          Get.to(() => OrderDetailScreen(
                tasks: (order.service?.description ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty
                    ? [order.service?.description ?? '']
                    : [],
                suburb: order.service?.tenantId ?? '',
                address: AppUtils().formatAddress(order.service?.address),
                tenantName: order.service?.user?.name ?? '',
                propertyImage: (order.imageUrls ?? []).isNotEmpty
                    ? order.imageUrls
                    : [ImageAssetsConst.sampleRoomPage],
                date: AppUtils.timeStampToDate(
                    order.service?.auditDetails?.createdTime),
                tenantContactName: order.service?.additionalDetail?['household']?['contactNo']?.toString() ?? '',
                type: AppUtils().getOrderStatus(order),
                orderID: order.service?.serviceRequestId ?? '',
                tenantLatitude:
                    (order.service?.address?.latitude ?? 'N/A').toString(),
                tenantLongitude:
                    (order.service?.address?.longitude ?? 'N/A').toString(),
                orderImages: [ImageAssetsConst.plotRolLogo],
                staffMobileNumber: '<Staff Contact No>',
                staffLocation: '<Staff Address>',
                staffName: '<Staff Name>',
                order: order,
                startDate: AppUtils().getOrderStatus(order) == "created"
                    ? AppUtils.timeStampToDate(
                        order.service?.auditDetails?.createdTime)
                    : '',
                acceptedDate: AppUtils().getOrderStatus(order) == "accepted"
                    ? AppUtils.timeStampToDate(
                        order.service?.auditDetails?.lastModifiedTime)
                    : '',
                completedDate: AppUtils().getOrderStatus(order) == "completed"
                    ? AppUtils.timeStampToDate(
                        order.service?.auditDetails?.lastModifiedTime)
                    : '',
              ));
        } on Exception catch (e, s) {
          print(s);
        }
      },
      child: Container(
        width: 320,
        margin: isVerticalScrollable
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                height: 140,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: (order.imageUrls != null && order.imageUrls!.isNotEmpty)
                    ? ThumbCollage(
                        urls: order.imageUrls ?? [],
                        height: 140,
                        width: double.infinity,
                        borderRadius: 20,
                        spacing: 2,
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ReusableTextWidget(
                          text: order.service?.address?.city ?? 'Service Location',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: _getDecorationBasedOnStatus(
                          AppUtils().getOrderStatus(order),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReusableTextWidget(
                              text: AppUtils().getOrderStatus(order),
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            if (AppUtils().getOrderStatus(order) == 'completed')
                              const SizedBox(width: 4),
                            if (AppUtils().getOrderStatus(order) == 'completed')
                              const Icon(
                                size: 12,
                                Icons.check_circle,
                                color: Colors.white,
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        size: 14,
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ReusableTextWidget(
                          text: AppUtils().formatAddress(order.service?.address),
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ReusableTextWidget(
                      text: order.service?.description ?? 'No description',
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ReusableTextWidget(
                          text:
                              'Order Date: ${AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime)}',
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 320,
            margin: isVerticalScrollable
                ? const EdgeInsets.symmetric(vertical: 8)
                : const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey[300]!,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 16,
                        width: 150,
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 200,
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 32,
                        width: double.infinity,
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.grey[300]!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return '';
    }
  }
}

BoxDecoration _getDecorationBasedOnStatus(String? status) {
  switch (status) {
    case 'created':
      return BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      );
    case 'pending':
      return BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      );
    case 'accepted':
      return BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(12),
      );
    case 'active':
      return BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      );
    case 'completed':
      return BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      );
    default:
      return BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(12),
      );
  }
}

List<Widget> _widgetOptionsNearle() => <Widget>[
      HomeScreen(),
      ViewAllOrdersScreen(isFromNavigation: true),
      const OngoingTaskScreen(),
      Profile(),
    ];