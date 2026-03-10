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
            List<Widget> widgetList = [
              Row(
                children: [
                  const ReusableTextWidget(
                    text: 'Today Tasks',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Get.to(() => ViewAllOrdersScreen());
                    },
                    child: (controller.todayOrders.isNotEmpty)
                        ? const ReusableTextWidget(
                            text: 'View All',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            isUnderText: TextDecoration.underline,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
              SizedBox(
                height: 1.h,
              ),
              OnGoingTask(
                isVerticalScrollable: true,
                maxItems: 5,
              ),
              SizedBox(
                height: 2.5.h,
              ),
            ];
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: AppBar(
                  backgroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      CircleAvatar(
                        minRadius: 25,
                        maxRadius: 25,
                        backgroundColor: Colors.grey.withOpacity(0.4),
                        child: (controller.profileImage.value.isNotEmpty)
                            ? ClipOval(
                                child: !controller.isTenantDetailLoading.value
                                    ? Image.network(
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                        ImageAssetsConst.sampleUserProfile,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.network(
                                            ImageAssetsConst.sampleUserProfile,
                                            width: 120,
                                            height: 140,
                                            fit: BoxFit.fill,
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
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
                                            height: 140,
                                            width: 120,
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(
                                                      value: progress),
                                                  const SizedBox(height: 8),
                                                  if (progress != null)
                                                    Text(
                                                        '${(progress * 100).toStringAsFixed(0)}%'),
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
                                          width: 50,
                                          height: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                              )
                            : ReusableTextWidget(
                                text: authController.getInitials(
                                        controller.tenantFirstName.value ?? '',
                                        controller.tenantLastName.value) ??
                                    '',
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                      SizedBox(
                        width: 2.h,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(controller.notes[1]),
                          ReusableTextWidget(
                            text: 'Hi! ${controller.tenantFirstName.value}',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(
                            height: 1.h,
                          ),
                          const ReusableTextWidget(
                            text: 'Contribute more, earn more.',
                          ),
                        ],
                      ),
                      // const Spacer(),
                      // const Icon(Icons.notifications),
                    ],
                  ),
                ),
              ),
              body: Padding(
                padding: EdgeInsets.only(
                    left: 2.h, right: 2.h, top: 2.h, bottom: 2.h),
                child: ListView.builder(
                    itemCount: widgetList.length,
                    itemBuilder: (context, index) {
                      return widgetList[index];
                    }),
              ),
            );
          });
        },
      ),
    );
  }
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
    print('The status : $status');
    return GetBuilder<HomeScreenController>(
      initState: (_) {
        // homeScreenController.getOrdersApiFunction();
        // homeScreenController.isOrderLoading.value = true;
      },
      builder: (controller) {
        if (homeScreenController.getOrderDetails.isEmpty &&
            !controller.isOrderLoading.value) {
          return const SizedBox(
            height: 145,
            child: Center(
              child: ReusableTextWidget(
                text: 'No Task Found',
                fontSize: 15,
              ),
            ),
          );
        }

        if (homeScreenController.isOrderLoading.value) {
          return SizedBox(
            height: 500,
            child: buildShimmerLoader(),
          );
        }

        if (isVerticalScrollable) {
          if (status == 'accepted') {
            if (controller.acceptedOrders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: ReusableTextWidget(
                    text: 'No Accepted Tasks Found ☹',
                    fontSize: 15,
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
            if (controller.completedOrders.isEmpty) {
              return SizedBox(
                height: Get.height * 0.6,
                child: const Center(
                  child: ReusableTextWidget(
                    text: 'No Completed Tasks Found ☹',
                    fontSize: 15,
                  ),
                ),
              );
            }
            return ListView.builder(
              physics: isForStatusScreen
                  ? null
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.completedOrders.length,
              itemBuilder: (context, index) {
                return buildOrderItem(controller.completedOrders[index]);
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
                      const ReusableTextWidget(
                        text: 'No Tasks Found for Today ☹',
                        fontSize: 15,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          Get.to(() => ViewAllOrdersScreen());
                        },
                        child: const ReusableTextWidget(
                          text: 'Go to Inbox',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                          isUnderText: TextDecoration.underline,
                        ),
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
    return InkWell(
      onTap: () {
        /// Accepted, Completed, Pending
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
                tenantContactName: order.service?.additionalDetail?['household']?['contactNo'] ?? '',
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
        width: 280,
        margin: isVerticalScrollable
            ? const EdgeInsets.symmetric(vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
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
                          urls: order.imageUrls ??
                              [], // safe: already checked isNotEmpty
                          height: 80,
                          width: 80, // 👈 finite width!
                          borderRadius:
                              0, // parent ClipRRect already rounds corners
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
                  // const Icon(
                  //   size: 15,
                  //   Icons.date_range,
                  // ),
                  // const SizedBox(width: 3),
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

  Widget buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        //physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 10, // Placeholder item count for shimmer effect
        itemBuilder: (context, index) {
          return Container(
            height: 145,
            width: 280,
            margin: isVerticalScrollable
                ? const EdgeInsets.symmetric(vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 120,
                            height: 15,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 15,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        size: 15,
                        Icons.date_range,
                      ),
                      const SizedBox(width: 3),
                      Container(
                        height: 15,
                        width: 100,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
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
      return ''; // Return an empty string if parsing fails
    }
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
