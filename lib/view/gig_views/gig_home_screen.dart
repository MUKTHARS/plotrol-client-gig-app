import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../../controller/autentication_controller.dart';
import '../../controller/create_account_controller.dart';
import '../../controller/home_screen_controller.dart';
import '../../globalWidgets/custom_scaffold_widget.dart';
import '../../globalWidgets/text_widget.dart';
import '../../helper/const_assets_const.dart';
import '../../helper/utils.dart';
import '../../model/response/book_service/pgr_create_response.dart';
import '../../widgets/thumbnail_collage.dart';
import '../image_grid_screen.dart';
import '../order_details.dart';
import '../view_all_orders_screen.dart';

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream = Color(0xFFF7F3EE);
const _parchment = Color(0xFFEFE9DF);
const _sand = Color(0xFFE4DAC8);
const _espresso = Color(0xFF1C1510);
const _walnut = Color(0xFF3D2B1F);
const _sienna = Color(0xFFB85C38);
const _siennaLight = Color(0x1AB85C38);
const _steel = Color(0xFF8C8480);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class GigHomeScreen extends StatelessWidget {
  GigHomeScreen({super.key});

  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  final AuthenticationController authController =
      Get.put(AuthenticationController());

  final CreateAccountController createAccountController =
      Get.put(CreateAccountController());

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: Sizer(
        builder: (BuildContext context, Orientation orientation, deviceType) {
          return GetBuilder<HomeScreenController>(initState: (_) {
            homeScreenController.getTenantApiFunction();
            homeScreenController.getOrdersApiFunction();
          }, builder: (controller) {
            return Scaffold(
              backgroundColor: _cream,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: AppBar(
                  backgroundColor: _cream,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _sand,
                            border: Border.all(color: _sienna, width: 2),
                          ),
                          child: ClipOval(
                            child: (controller.profileImage.value.isNotEmpty)
                                ? !controller.isTenantDetailLoading.value
                                    ? Image.network(
                                        fit: BoxFit.cover,
                                        width: 48,
                                        height: 48,
                                        controller.tenantProfileImage.value,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildInitialsAvatar(controller);
                                        },
                                      )
                                    : _shimmerCircle(48)
                                : _buildInitialsAvatar(controller),
                          ),
                        ),
                        SizedBox(width: 2.h),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi! ${controller.tenantFirstName.value}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _espresso,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              const Text(
                                'Contribute more, earn more.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _steel,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: Padding(
                padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 2.h),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Today Tasks Header
                    Row(
                      children: [
                        const Text(
                          'Today Tasks',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _espresso,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        if (controller.isGigWorker.value 
                            ? controller.acceptedOrders.isNotEmpty 
                            : controller.createdOrders.isNotEmpty)
                          InkWell(
                            onTap: () {
                              Get.to(() => ViewAllOrdersScreen());
                            },
                            child: const Text(
                              'View all →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _sienna,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    
                    // Tasks List
                    OnGoingTask(
                      isVerticalScrollable: true,
                      maxItems: 5,
                      status: controller.isGigWorker.value ? 'accepted' : 'created',
                    ),
                    
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildInitialsAvatar(HomeScreenController controller) {
    final initials = authController.getInitials(
      controller.tenantFirstName.value ?? '',
      controller.tenantLastName.value
    ) ?? 'U';
    
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: _sienna,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _shimmerCircle(double size) => Shimmer.fromColors(
        baseColor: _sand,
        highlightColor: _cream,
        child: Container(width: size, height: size, color: _sand),
      );
}

class OnGoingTask extends StatelessWidget {
  final bool isVerticalScrollable;
  final bool isForStatusScreen;
  final String status;
  final int? maxItems;

  OnGoingTask({
    super.key,
    this.isVerticalScrollable = false,
    this.isForStatusScreen = false,
    this.status = '',
    this.maxItems,
  });

  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenController>(
      builder: (controller) {
        if (homeScreenController.getOrderDetails.isEmpty &&
            !controller.isOrderLoading.value) {
          return _EmptyCard(
            icon: Icons.task_alt_outlined,
            label: 'No Tasks Found',
          );
        }

        if (homeScreenController.isOrderLoading.value) {
          return buildShimmerLoader();
        }

        if (isVerticalScrollable) {
          if (status == 'created') {
            if (controller.createdOrders.isEmpty) {
              return _EmptyCard(
                icon: Icons.inbox_outlined,
                label: 'No Created Tasks',
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: maxItems != null
                  ? (controller.createdOrders.length > maxItems!
                      ? maxItems!
                      : controller.createdOrders.length)
                  : controller.createdOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.createdOrders[index]);
              },
            );
          } else if (status == 'accepted') {
            if (controller.acceptedOrders.isEmpty) {
              return _EmptyCard(
                icon: Icons.pending_actions_outlined,
                label: 'No Accepted Tasks',
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.acceptedOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.acceptedOrders[index]);
              },
            );
          } else if (status == 'completed') {
            if (controller.completedOrders.isEmpty) {
              return _EmptyCard(
                icon: Icons.done_all_outlined,
                label: 'No Completed Tasks',
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.completedOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.completedOrders[index]);
              },
            );
          } else {
            if (controller.todayOrders.isEmpty) {
              return _EmptyCard(
                icon: Icons.calendar_today_outlined,
                label: 'No Tasks for Today',
                action: GestureDetector(
                  onTap: () {
                    Get.to(() => ViewAllOrdersScreen());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _espresso,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Go to Inbox',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: maxItems != null
                  ? (controller.todayOrders.length > maxItems!
                      ? maxItems!
                      : controller.todayOrders.length)
                  : controller.todayOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.todayOrders[index]);
              },
            );
          }
        } else {
          return SizedBox(
            height: 145,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: maxItems != null
                  ? (controller.todayOrders.length > maxItems!
                      ? maxItems!
                      : controller.todayOrders.length)
                  : controller.todayOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.todayOrders[index]);
              },
            ),
          );
        }
      },
    );
  }

  Widget buildOrderItem(ServiceWrapper order) {
    final statusText = AppUtils().getOrderStatus(order);
    final statusCfg = _statusConfig(statusText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
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
                  propertyImage: order.imageUrls,
                  date: AppUtils.timeStampToDate(
                      order.service?.auditDetails?.createdTime),
                  tenantContactName: order.service?.additionalDetail?['household']?['contactNo']?.toString() ?? '',
                  type: statusText,
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
                  startDate: statusText == "created"
                      ? AppUtils.timeStampToDate(
                          order.service?.auditDetails?.createdTime)
                      : '',
                  acceptedDate: statusText == "accepted"
                      ? AppUtils.timeStampToDate(
                          order.service?.auditDetails?.lastModifiedTime)
                      : '',
                  completedDate: statusText == "completed"
                      ? AppUtils.timeStampToDate(
                          order.service?.auditDetails?.lastModifiedTime)
                      : '',
                ));
          } on Exception catch (e, s) {
            print(s);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _dividerLine),
            boxShadow: [
              BoxShadow(
                color: _espresso.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image section with status badge
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: (order.imageUrls != null && order.imageUrls!.isNotEmpty)
                          ? ThumbCollage(
                              urls: order.imageUrls ?? [],
                              height: 160,
                              width: double.infinity,
                              borderRadius: 24,
                              spacing: 2,
                            )
                          : Container(
                              color: _parchment,
                              child: Center(
                                child: Icon(Icons.image_outlined, size: 48, color: _sand),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              // Content section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: _sienna),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppUtils().formatAddress(order.service?.address),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _steel,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _siennaLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _siennaLight),
                      ),
                      child: Text(
                        order.service?.description ?? 'No description',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _walnut,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: _dividerLine),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 12, color: _steel),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Order Date: ${AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _steel,
                              fontWeight: FontWeight.w500,
                            ),
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
      ),
    );
  }

  Widget buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: _parchment,
      highlightColor: _cream,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            height: 260,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _parchment,
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }
}

// ── Status configuration ─────────────────────────────────────────────────────
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

// ── Empty Card Widget ────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? action;

  const _EmptyCard({
    required this.icon,
    required this.label,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _walnut,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// Additional color constants needed
const _amber = Color(0xFFD4830A);
const _amberSoft = Color(0x1AD4830A);
const _sage = Color(0xFF6B8C6E);
const _sageSoft = Color(0x1A6B8C6E);