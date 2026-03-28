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

// ── Design tokens ─────────────────────────────────────────────────────────────
const _cream       = Color(0xFFF7F3EE);
const _parchment   = Color(0xFFEFE9DF);
const _sand        = Color(0xFFE4DAC8);
const _espresso    = Color(0xFF1C1510);
const _walnut      = Color(0xFF3D2B1F);
const _sienna      = Color(0xFFB85C38);
const _siennaLight = Color(0x1AB85C38);
const _siennaFade  = Color(0x08B85C38);
const _sage        = Color(0xFF6B8C6E);
const _sageSoft    = Color(0x1A6B8C6E);
const _amber       = Color(0xFFD4830A);
const _amberSoft   = Color(0x1AD4830A);
const _steel       = Color(0xFF8C8480);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeScreenController controller = Get.put(HomeScreenController());
  final AuthenticationController authController = Get.put(AuthenticationController());
  final CreateAccountController createAccountController = Get.put(CreateAccountController());
  final BookYourServiceController bookYourServiceController = Get.put(BookYourServiceController());

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
    return Sizer(builder: (context, orientation, deviceType) {
      return GetBuilder<HomeScreenController>(initState: (_) async {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getString('access_token') == null) {
            Get.offAll(() => LoginScreen());
            return;
          }
          final userInfoString = prefs.getString('userInfo');
          final userRequest = UserRequest.fromJson(jsonDecode(userInfoString!));

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
              backgroundColor: _cream,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeHeader(controller: controller, authController: authController),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _EyebrowLabel(text: 'WHAT DO YOU NEED?'),
                        const SizedBox(height: 12),
                        SizedBox(height: 108, child: CategoriesTypeWidget()),

                        const SizedBox(height: 36),
                        _DashedRule(),
                        const SizedBox(height: 32),

                        _BlockHeader(
                          title: 'Ongoing\nTasks',
                          actionLabel: 'All tasks →',
                          onAction: () => Get.to(() => ViewAllOrdersScreen()),
                          show: controller.createdOrders.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        OnGoingTask(status: 'created', maxItems: 5),

                        const SizedBox(height: 36),
                        _DashedRule(),
                        const SizedBox(height: 32),

                        _BlockHeader(
                          title: 'Your\nProperties',
                          actionLabel: 'See all →',
                          onAction: () => Get.to(() => AllProperties()),
                          show: controller.getPropertiesDetails.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        PropertyWidget(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    });
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final HomeScreenController controller;
  final AuthenticationController authController;
  const _HomeHeader({required this.controller, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cream,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(controller: controller, authController: authController),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _parchment,
                    shape: BoxShape.circle,
                    border: Border.all(color: _dividerLine, width: 1.5),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: _walnut),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hello,',
            style: const TextStyle(
              fontSize: 15,
              color: _steel,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            controller.tenantFirstName.value,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: _espresso,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _sienna,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Ready to book a service?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: _dividerLine),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final HomeScreenController controller;
  final AuthenticationController authController;
  const _Avatar({required this.controller, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _sand,
        border: Border.all(color: _sienna, width: 2),
      ),
      child: ClipOval(
        child: controller.profileImage.value.isNotEmpty
            ? !controller.isTenantDetailLoading.value
                ? Image.network(
                    controller.tenantProfileImage.value,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _initials(controller, authController),
                    loadingBuilder: (c, child, progress) =>
                        progress == null ? child : _shimmerCircle(52),
                  )
                : _shimmerCircle(52)
            : _initials(controller, authController),
      ),
    );
  }
}

Widget _initials(HomeScreenController c, AuthenticationController a) => Center(
      child: Text(
        a.getInitials(c.name.value ?? '', c.lastName.value) ?? '',
        style: const TextStyle(color: _sienna, fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );

Widget _shimmerCircle(double size) => Shimmer.fromColors(
      baseColor: _sand,
      highlightColor: _cream,
      child: Container(width: size, height: size, color: _sand),
    );

// ── Typography helpers ────────────────────────────────────────────────────────
class _EyebrowLabel extends StatelessWidget {
  final String text;
  const _EyebrowLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _sienna,
          letterSpacing: 2.5,
        ),
      );
}

class _BlockHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final bool show;
  const _BlockHeader({required this.title, required this.actionLabel, required this.onAction, required this.show});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: _espresso,
                letterSpacing: -1,
                height: 1.05,
              ),
            ),
          ),
          if (show)
            GestureDetector(
              onTap: onAction,
              child: const Text(
                'View all →',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _sienna),
              ),
            ),
        ],
      );
}

class _DashedRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          40,
          (i) => Expanded(
            child: Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              color: i % 2 == 0 ? _sand : Colors.transparent,
            ),
          ),
        ),
      );
}

// ── Property Widget ───────────────────────────────────────────────────────────
class PropertyWidget extends StatelessWidget {
  PropertyWidget({super.key});
  final HomeScreenController homeScreenController = Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenController>(builder: (controller) {
      if (controller.getPropertiesDetails.isEmpty && !controller.isPropertyLoading.value) {
        return _EmptyCard(icon: Icons.home_work_outlined, label: 'No properties yet');
      }
      return SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.getPropertiesDetails.length,
          itemBuilder: (context, index) {
            if (controller.isPropertyLoading.value) return _shimmerPropertyCard();
            final prop = controller.getPropertiesDetails[index];
            final notes = prop.additionalFields?.fields?.where((a) => a.key == 'notes').firstOrNull?.value ?? '';
            final contactNo = prop.additionalFields?.fields?.where((a) => a.key == 'contactNo').firstOrNull?.value ?? '';

            return GestureDetector(
              onTap: () => Get.to(() => PropertiesDetailsScreen(
                    propertyImage: prop.imageUrls,
                    address: AppUtils().formatAddress(prop.address),
                    contactNumber: contactNo,
                  )),
              child: Container(
                width: 190,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _dividerLine),
                  boxShadow: [
                    BoxShadow(color: _espresso.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image section - Fixed to fill container without gaps
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: SizedBox(
                        height: 125,
                        width: double.infinity,
                        child: ThumbCollage(
                          urls: prop.imageUrls ?? [],
                          height: 125,
                          width: double.infinity,
                          borderRadius: 24,
                          spacing: 2,
                        ),
                      ),
                    ),
                    
                    // Content section with minimal spacing
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notes.isNotEmpty ? notes : 'My Property',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _espresso,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppUtils().formatAddress(prop.address),
                            style: const TextStyle(fontSize: 12, color: _steel, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Get.to(() => BookYourService(
                                  householdModel: prop,
                                  tenantImage: prop.imageUrls,
                                  address: AppUtils().formatAddress(prop.address),
                                  contactNumber: contactNo,
                                )),
                            child: Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _espresso,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Book Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _shimmerPropertyCard() => Shimmer.fromColors(
        baseColor: _parchment,
        highlightColor: _cream,
        child: Container(
          width: 190,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(color: _parchment, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 125,
                width: double.infinity,
                color: _sand,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 15, width: 100, color: _sand),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 140, color: _sand),
                    const SizedBox(height: 20),
                    Container(height: 36, color: _sand),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Categories Widget ─────────────────────────────────────────────────────────
class CategoriesTypeWidget extends StatelessWidget {
  CategoriesTypeWidget({super.key});
  final BookYourServiceController controller = Get.put(BookYourServiceController());

  static const _accentColors = [
    Color(0xFFB85C38),
    Color(0xFF6B8C6E),
    Color(0xFFD4830A),
    Color(0xFF7A6552),
    Color(0xFF4A7FA5),
    Color(0xFF9C6B3C),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookYourServiceController>(builder: (controller) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.listOfCategories.length,
        itemBuilder: (context, index) {
          if (controller.isCategoryLoading.value) {
            return Shimmer.fromColors(
              baseColor: _parchment,
              highlightColor: _cream,
              child: Container(
                width: 74,
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 62, height: 62, decoration: const BoxDecoration(color: _sand, shape: BoxShape.circle)),
                    const SizedBox(height: 8),
                    Container(width: 50, height: 10, color: _sand),
                  ],
                ),
              ),
            );
          }

          final cat = controller.listOfCategories[index];
          final accent = _accentColors[index % _accentColors.length];

          return GestureDetector(
            onTap: () => Get.to(() => AllProperties(
                  selectedCategory: cat.categoryname ?? '',
                  isFromCategory: true,
                )),
            child: Container(
              width: 74,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.28), width: 1.5),
                    ),
                    child: Center(
                      child: Image.asset(
                        cat.serviceimage ?? '',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Icon(Icons.build_outlined, size: 26, color: accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    cat.categoryname ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _walnut, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// ── OnGoing Task Widget ───────────────────────────────────────────────────────
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
    final HomeScreenController homeScreenController = Get.put(HomeScreenController());
    return GetBuilder<HomeScreenController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeScreenController.updateLoadingState();
          homeScreenController.getOrdersApiFunction();
        });
      },
      builder: (controller) {
        if (homeScreenController.isOrderLoading.value) {
          return SizedBox(height: 230, child: buildShimmerLoader());
        }
        if (homeScreenController.getOrderDetails.isEmpty) {
          return _EmptyCard(icon: Icons.task_alt_outlined, label: 'No ongoing tasks');
        }

        if (isVerticalScrollable) {
          if (status == 'created') {
            final orders = isForStatusScreen ? controller.todayCreatedOrders : controller.createdOrders;
            if (orders.isEmpty) return _EmptyCard(icon: Icons.inbox_outlined, label: 'No created orders');
            return ListView.builder(
              physics: isForStatusScreen ? null : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: maxItems != null ? (orders.length > maxItems! ? maxItems! : orders.length) : orders.length,
              itemBuilder: (context, index) => buildOrderItem(orders[index]),
            );
          }
          if (status == 'pending') {
            if (controller.pendingOrders.isEmpty) return _EmptyCard(icon: Icons.pending_actions_outlined, label: 'No pending orders');
            return ListView.builder(
              physics: isForStatusScreen ? null : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.pendingOrders.length,
              itemBuilder: (context, index) => buildOrderItem(controller.pendingOrders[index]),
            );
          }
          if (status == 'accepted') {
            if (controller.acceptedOrders.isEmpty) return _EmptyCard(icon: Icons.check_circle_outline, label: 'No accepted orders');
            return ListView.builder(
              physics: isForStatusScreen ? null : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.acceptedOrders.length,
              itemBuilder: (context, index) => buildOrderItem(controller.acceptedOrders[index]),
            );
          } else if (status == 'completed') {
            final completedList = controller.completedOrders;
            if (completedList.isEmpty) return _EmptyCard(icon: Icons.done_all_outlined, label: 'No completed tasks');
            return ListView.builder(
              physics: isForStatusScreen ? null : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: completedList.length,
              itemBuilder: (context, index) => buildOrderItem(completedList[index]),
            );
          } else if (status == 'active') {
            if (controller.activeOrders.isEmpty) return _EmptyCard(icon: Icons.play_circle_outline, label: 'No active orders');
            return ListView.builder(
              physics: isForStatusScreen ? null : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.activeOrders.length,
              itemBuilder: (context, index) => buildOrderItem(controller.activeOrders[index]),
            );
          } else {
            if (controller.todayOrders.isEmpty) {
              return _EmptyCard(
                icon: Icons.calendar_today_outlined,
                label: 'No orders today',
                action: GestureDetector(
                  onTap: () => Get.to(() => ViewAllOrdersScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: _espresso, borderRadius: BorderRadius.circular(30)),
                    child: const Text('Go to Inbox', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                itemBuilder: (context, index) => buildOrderItem(controller.todayOrders[index]),
              ),
            );
          }
        } else {
          if (controller.createdOrders.isEmpty) {
            return _EmptyCard(icon: Icons.inbox_outlined, label: 'No active orders yet');
          }
          return SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: maxItems != null
                  ? (controller.createdOrders.length > maxItems! ? maxItems! : controller.createdOrders.length)
                  : controller.createdOrders.length,
              itemBuilder: (context, index) => buildOrderItem(controller.createdOrders[index]),
            ),
          );
        }
      },
    );
  }

  Widget buildOrderItem(ServiceWrapper order) {
    final statusText = AppUtils().getOrderStatus(order);
    final statusCfg = _statusConfig(statusText);

    return GestureDetector(
      onTap: () {
        try {
          Get.to(() => OrderDetailScreen(
                tasks: (order.service?.description ?? '').toString().trim().isNotEmpty
                    ? [order.service?.description ?? '']
                    : [],
                suburb: order.service?.tenantId ?? '',
                address: AppUtils().formatAddress(order.service?.address),
                tenantName: order.service?.user?.name ?? '',
                propertyImage: (order.imageUrls ?? []).isNotEmpty ? order.imageUrls : [ImageAssetsConst.sampleRoomPage],
                date: AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime),
                tenantContactName:
                    order.service?.additionalDetail?['household']?['contactNo']?.toString() ?? '',
                type: statusText,
                orderID: order.service?.serviceRequestId ?? '',
                tenantLatitude: (order.service?.address?.latitude ?? 'N/A').toString(),
                tenantLongitude: (order.service?.address?.longitude ?? 'N/A').toString(),
                orderImages: [ImageAssetsConst.plotRolLogo],
                staffMobileNumber: '<Staff Contact No>',
                staffLocation: '<Staff Address>',
                staffName: '<Staff Name>',
                order: order,
                startDate: statusText == "created"
                    ? AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime)
                    : '',
                acceptedDate: statusText == "accepted"
                    ? AppUtils.timeStampToDate(order.service?.auditDetails?.lastModifiedTime)
                    : '',
                completedDate: statusText == "completed"
                    ? AppUtils.timeStampToDate(order.service?.auditDetails?.lastModifiedTime)
                    : '',
              ));
        } on Exception catch (e, s) {
          print(s);
        }
      },
      child: Container(
        width: 300,
        margin: isVerticalScrollable
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _dividerLine),
          boxShadow: [
            BoxShadow(color: _espresso.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with overlaid status badge
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: (order.imageUrls != null && order.imageUrls!.isNotEmpty)
                        ? ThumbCollage(
                            urls: order.imageUrls ?? [],
                            height: 140,
                            width: double.infinity,
                            borderRadius: 24,
                            spacing: 2,
                          )
                        : Container(
                            color: _parchment,
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 40, color: _sand),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusCfg['bg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusCfg['dot'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              color: statusCfg['text'] as Color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (statusText == 'completed') ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle, size: 10, color: statusCfg['dot'] as Color),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content - Optimized for no overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // City/Location text
                  Text(
                    order.service?.address?.city ?? 'Service Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _espresso,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Address row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: _sienna),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppUtils().formatAddress(order.service?.address),
                          style: const TextStyle(fontSize: 12, color: _steel, height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Description container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _siennaFade,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _siennaLight),
                    ),
                    child: Text(
                      order.service?.description ?? 'No description',
                      style: const TextStyle(fontSize: 12, color: _walnut, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Divider
                  Container(height: 1, color: _dividerLine),
                  const SizedBox(height: 8),
                  
                  // Date row
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 12, color: _steel),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime),
                          style: const TextStyle(fontSize: 12, color: _steel),
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

  Widget buildShimmerLoader() => Shimmer.fromColors(
        baseColor: _parchment,
        highlightColor: _cream,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            width: 300,
            margin: isVerticalScrollable
                ? const EdgeInsets.symmetric(vertical: 8)
                : const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(color: _parchment, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 140, color: _sand),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 16, width: 140, color: _sand),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 200, color: _sand),
                      const SizedBox(height: 10),
                      Container(height: 40, color: _sand),
                      const SizedBox(height: 10),
                      Container(height: 12, width: 100, color: _sand),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(dateString));
    } catch (_) {
      return '';
    }
  }
}

// ── Status config ─────────────────────────────────────────────────────────────
Map<String, dynamic> _statusConfig(String status) {
  switch (status) {
    case 'created':
      return {'bg': Colors.white.withOpacity(0.92), 'text': _espresso, 'dot': _sienna};
    case 'pending':
      return {'bg': _amberSoft, 'text': _amber, 'dot': _amber};
    case 'accepted':
      return {'bg': Colors.white.withOpacity(0.92), 'text': _walnut, 'dot': _steel};
    case 'active':
      return {'bg': _sageSoft, 'text': _sage, 'dot': _sage};
    case 'completed':
      return {'bg': _sageSoft, 'text': _sage, 'dot': _sage};
    default:
      return {'bg': _amberSoft, 'text': _amber, 'dot': _amber};
  }
}

BoxDecoration _getDecorationBasedOnStatus(String? status) {
  switch (status) {
    case 'created':
      return BoxDecoration(color: _siennaLight, borderRadius: BorderRadius.circular(12));
    case 'pending':
      return BoxDecoration(color: _amberSoft, borderRadius: BorderRadius.circular(12));
    case 'accepted':
      return BoxDecoration(color: _parchment, borderRadius: BorderRadius.circular(12));
    case 'active':
      return BoxDecoration(color: _sageSoft, borderRadius: BorderRadius.circular(12));
    case 'completed':
      return BoxDecoration(color: _sageSoft, borderRadius: BorderRadius.circular(12));
    default:
      return BoxDecoration(color: _amberSoft, borderRadius: BorderRadius.circular(12));
  }
}

// ── Empty Card ────────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? action;
  const _EmptyCard({required this.icon, required this.label, this.action});

  @override
  Widget build(BuildContext context) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: _parchment,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _dividerLine),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: _sand, width: 1.5),
                ),
                child: Icon(icon, size: 24, color: _steel),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _walnut)),
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          ),
        ),
      );
}

// ── Nav ───────────────────────────────────────────────────────────────────────
List<Widget> _widgetOptionsNearle() => <Widget>[
      HomeScreen(),
      ViewAllOrdersScreen(isFromNavigation: true),
      const OngoingTaskScreen(),
      Profile(),
    ];