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

class ViewAllOrdersScreen extends StatelessWidget {
  final bool isFromNavigation;
  final bool backButton;

  ViewAllOrdersScreen({super.key, this.isFromNavigation = false, this.backButton = true,});

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

        final bodyContent = Column(
          children: [
            // Order Status Header with Date Range
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ReusableTextWidget(
                        text: 'Orders',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      InkWell(
                        onTap: () {
                          _showFilterDialog(context, controller);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ReusableTextWidget(
                              text: 'Filter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_list, color: Colors.black, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      ReusableTextWidget(
                        text: '${DateFormat('dd/MM/yyyy').format(controller.fromDate.value)} - ${DateFormat('dd/MM/yyyy').format(controller.toDate.value)}',
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // TabBarView
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
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
          ],
        );

        final tabBar = TabBar(
          controller: controller.tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.black,
          tabs: [
            if (!controller.isHelpDeskUser.value)
              Tab(
                child: ReusableTextWidget(
                  text: 'Pending (${controller.pendingOrders.length})',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            Tab(
              child: ReusableTextWidget(
                text: 'Ongoing (${controller.ongoingOrders.length})',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Tab(
              child: ReusableTextWidget(
                text: 'Completed (${controller.completedOrders.length})',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        );

        // If accessed from navigation, don't show AppBar to save space
        if (isFromNavigation) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // TabBar without AppBar
                Container(
                  color: Colors.white,
                  child: tabBar,
                ),
                // Body content
                Expanded(
                  child: bodyContent,
                ),
              ],
            ),
          );
        }

        // If accessed directly (like View All button), use CustomScaffold
        return CustomScaffold(
          automaticallyImplyLeading: false,
          bottomNavigationBar: SafeArea(
            child: backButton ? Padding(
              padding: EdgeInsets.only(
                left: 2.h,
                right: 2.h,
                bottom: 2.h,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(Get.width, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Get.back();
                },
                child: const ReusableTextWidget(
                  text: 'Go Back',
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ) : SizedBox.shrink(),
          ),
          bottom: tabBar,
          body: bodyContent,
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
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return buildOrderItem(orders[index]);
      },
    );
  }

  Widget buildOrderItem(ServiceWrapper order) {
    return InkWell(
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
                tenantContactName: order.service?.additionalDetail?['household']?['contactNo'],
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
        height: 180,
        width: double.infinity,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey, width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: InkWell(
                      onTap: () => Get.to(() => ImageGridScreen(
                            imageUrls: order.imageUrls ?? [],
                            title: 'Property Images',
                          )),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        child: ThumbCollage(
                          urls: order.imageUrls ?? [],
                          height: 80,
                          width: 80,
                          borderRadius: 0,
                          spacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: ReusableTextWidget(
                          text: order.service?.address?.city ?? '',
                          maxLines: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            size: 15,
                            Icons.location_on,
                          ),
                          const SizedBox(width: 3),
                          SizedBox(
                            width: 120,
                            child: ReusableTextWidget(
                              text: AppUtils()
                                  .formatAddress(order.service?.address),
                              maxLines: 4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration:
                        _getDecorationBasedOnStatus(AppUtils().getOrderStatus(
                      order,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ReusableTextWidget(
                            text: AppUtils().getOrderStatus(order),
                            color: Colors.white,
                            fontSize: 10,
                            textAlign: TextAlign.center,
                          ),
                          if (AppUtils().getOrderStatus(order) == 'completed')
                            const Icon(
                              size: 16,
                              Icons.check_circle,
                              color: Colors.white,
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ReusableTextWidget(
                        text: order.service?.description ?? '')),
              ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ReusableTextWidget(
                    text:
                        'Order Date : ${AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime)}',
                    fontSize: 13,
                  ),
                ],
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: const ReusableTextWidget(
            text: 'Filter Orders by Date',
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
                SizedBox(height: 2.h),
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
              child: const ReusableTextWidget(
                text: 'Cancel',
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                controller.fetchOrdersByDateRange();
              },
              child: const ReusableTextWidget(
                text: 'Apply Filter',
                color: Colors.white,
                fontSize: 15,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableTextWidget(
              text: label,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            SizedBox(height: 0.8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTextWidget(
                  text: DateFormat('dd/MM/yyyy').format(date),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.black,
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
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const ReusableTextWidget(
            text: 'No Orders Found',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          const ReusableTextWidget(
            text: 'Try adjusting your date range',
            fontSize: 14,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15),
            ),
          );
        },
      ),
    );
  }
}

BoxDecoration _getDecorationBasedOnStatus(String? status) {
  switch (status) {
    case 'created':
      return BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      );
    case 'pending':
      return BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      );
    case 'accepted':
      return BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
      );
    case 'active':
      return BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      );
    case 'completed':
      return BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      );
    default:
      return BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(10),
      );
  }
}
