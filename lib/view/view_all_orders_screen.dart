import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../controller/view_all_orders_controller.dart';
import '../globalWidgets/custom_scaffold_widget.dart';
import '../globalWidgets/text_widget.dart';
import '../helper/const_assets_const.dart';
import '../helper/utils.dart';
import '../model/response/book_service/pgr_create_response.dart';
import '../widgets/thumbnail_collage.dart';
import 'image_grid_screen.dart';
import 'order_details.dart';

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream       = Color(0xFFF7F3EE);
const _parchment   = Color(0xFFEFE9DF);
const _sand        = Color(0xFFE4DAC8);
const _espresso    = Color(0xFF1C1510);
const _walnut      = Color(0xFF3D2B1F);
const _sienna      = Color(0xFFB85C38);
const _siennaLight = Color(0x1AB85C38);
const _sage        = Color(0xFF6B8C6E);
const _sageSoft    = Color(0x1A6B8C6E);
const _amber       = Color(0xFFD4830A);
const _amberSoft   = Color(0x1AD4830A);
const _steel       = Color(0xFF8C8480);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class ViewAllOrdersScreen extends StatelessWidget {
  final bool isFromNavigation;
  final bool backButton;

  ViewAllOrdersScreen({
    super.key, 
    this.isFromNavigation = false, 
    this.backButton = true,
  });

  final ViewAllOrdersController controller = Get.put(ViewAllOrdersController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewAllOrdersController>(
      initState: (_) {
        controller.tabController.index = 0;
        controller.checkForRole();
        controller.initializeDateRange();
        controller.fetchOrdersByDateRange();
      },
      builder: (controller) {
        if (controller.isScreenLoading.value) {
          return _buildShimmerLoader();
        }

        final tabBar = Container(
          color: _cream,
          child: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _sienna,
            indicatorWeight: 3,
            labelColor: _espresso,
            unselectedLabelColor: _steel,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            tabs: [
              if (!controller.isHelpDeskUser.value)
                Tab(
                  child: Text('Pending (${controller.pendingOrders.length})'),
                ),
              Tab(
                child: Text('Ongoing (${controller.ongoingOrders.length})'),
              ),
              Tab(
                child: Text('Completed (${controller.completedOrders.length})'),
              ),
            ],
          ),
        );

        final bodyContent = Column(
          children: [
            // Order Status Header with Date Range
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              decoration: BoxDecoration(
                color: _cream,
                border: Border(
                  bottom: BorderSide(color: _dividerLine, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _espresso,
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _showFilterDialog(context, controller);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _parchment,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _dividerLine, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_list, size: 16, color: _walnut),
                              const SizedBox(width: 6),
                              const Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _walnut,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: _steel),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(controller.fromDate.value)} - ${DateFormat('dd/MM/yyyy').format(controller.toDate.value)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _steel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // TabBarView
            Expanded(
              child: Container(
                color: _cream,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: TabBarView(
                    controller: controller.tabController,
                    children: [
                      if (!controller.isHelpDeskUser.value)
                        _buildOrdersList(controller.pendingOrders, controller),
                      _buildOrdersList(controller.ongoingOrders, controller),
                      _buildOrdersList(controller.completedOrders, controller),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        // If accessed from navigation, don't show AppBar to save space
        if (isFromNavigation) {
          return Scaffold(
            backgroundColor: _cream,
            body: Column(
              children: [
                tabBar,
                Expanded(child: bodyContent),
              ],
            ),
          );
        }

       // If accessed directly (like View All button), use CustomScaffold
return CustomScaffold(
  automaticallyImplyLeading: false,
  bottomNavigationBar: backButton
      ? SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 2.h),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _espresso,
                minimumSize: Size(Get.width, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Get.back();
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        )
      : const SizedBox.shrink(),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(56.0),
    child: tabBar,
  ),
  body: Container(
    color: _cream,
    child: bodyContent,
  ),
);
      },
    );
  }

  Widget _buildOrdersList(List<ServiceWrapper> orders, ViewAllOrdersController controller) {
    if (controller.isLoading.value) {
      return _buildShimmerLoader();
    }

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return buildOrderItem(orders[index]);
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
                  tasks: (order.service?.description ?? '').toString().trim().isNotEmpty
                      ? [order.service?.description ?? '']
                      : [],
                  suburb: order.service?.tenantId ?? '',
                  address: AppUtils().formatAddress(order.service?.address),
                  tenantName: order.service?.user?.name ?? '',
                  propertyImage: order.imageUrls,
                  date: AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime),
                  tenantContactName: order.service?.additionalDetail?['household']?['contactNo']?.toString() ?? '',
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _dividerLine, width: 1),
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
                    // City/Location
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
                    
                    // Address
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
                    
                    // Description container
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
                    
                    // Divider
                    Container(height: 1, color: _dividerLine),
                    const SizedBox(height: 10),
                    
                    // Order date
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

  void _showFilterDialog(BuildContext context, ViewAllOrdersController controller) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Filter Orders by Date',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _espresso,
              letterSpacing: -0.5,
            ),
          ),
          content: SizedBox(
            width: Get.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // From Date
                _buildDateField(
                  label: 'From Date',
                  date: controller.fromDate.value,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await controller.selectFromDate(context);
                    _showFilterDialog(context, controller);
                  },
                ),
                const SizedBox(height: 16),
                // To Date
                _buildDateField(
                  label: 'To Date',
                  date: controller.toDate.value,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await controller.selectToDate(context);
                    _showFilterDialog(context, controller);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _steel,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _espresso,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                controller.fetchOrdersByDateRange();
              },
              child: const Text(
                'Apply Filter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
        decoration: BoxDecoration(
          color: _parchment,
          border: Border.all(color: _dividerLine, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _sienna,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _espresso,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: _steel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _parchment,
              shape: BoxShape.circle,
              border: Border.all(color: _sand, width: 1.5),
            ),
            child: Icon(Icons.inbox_outlined, size: 36, color: _steel),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _espresso,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your date range',
            style: TextStyle(
              fontSize: 13,
              color: _steel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: _parchment,
      highlightColor: _cream,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
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

// ── Status configuration (matching home screen) ──────────────────────────────
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