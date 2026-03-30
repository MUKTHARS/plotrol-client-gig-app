import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:plotrol/controller/order_details_controlller.dart';
import 'package:plotrol/globalWidgets/custom_scaffold_widget.dart';
import 'package:plotrol/globalWidgets/flutter_toast.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/model/response/employee_response/employee_search_response.dart';
import 'package:plotrol/view/image_grid_screen.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../controller/home_screen_controller.dart';
import '../globalWidgets/dropdown_widget.dart';
import '../globalWidgets/employee_table.dart';
import '../globalWidgets/text_widget.dart';
import '../model/response/book_service/pgr_create_response.dart';
import '../widgets/thumbnail_collage.dart';
import 'main_screen.dart';

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
const _amber = Color(0xFFD4830A);
const _sage = Color(0xFF6B8C6E);
// ─────────────────────────────────────────────────────────────────────────────

class OrderDetailScreen extends StatelessWidget {
  final String address;
  final String suburb;
  final String date;
  final String tenantName;
  final String tenantContactName;
  final List<String> tasks;
  final List<String>? propertyImage;
  final List<String>? orderImages;
  final String type;
  final String orderID;
  final String tenantLatitude;
  final String tenantLongitude;
  final String staffName;
  final String staffMobileNumber;
  final String staffLocation;
  final String acceptedDate;
  final String startDate;
  final String completedDate;
  final ServiceWrapper order;

  OrderDetailScreen({
    super.key,
    this.suburb = '',
    this.date = '',
    this.tenantName = '',
    this.address = '',
    this.tenantContactName = '',
    this.tenantLatitude = '',
    this.tenantLongitude = '',
    this.staffLocation = '',
    this.staffMobileNumber = '',
    this.staffName = '',
    required this.tasks,
    required this.propertyImage,
    this.orderImages,
    this.startDate = '',
    this.completedDate = '',
    this.acceptedDate = '',
    required this.type,
    required this.orderID,
    required this.order,
  });

  final OrderDetailsController orderDetailsController =
      Get.put(OrderDetailsController());

  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> additionalDetailMap =
        order.service!.additionalDetail != null
            ? Map<String, dynamic>.from(order.service!.additionalDetail!)
            : {};
    return GetBuilder<OrderDetailsController>(initState: (_) {
      orderDetailsController.getCheckList();
      orderDetailsController.getAssignees(order);
      if (type == 'completed') {
        orderDetailsController.setItems(tasks);
      }
    }, builder: (controller) {
      return Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          elevation: 0,
          title: const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _espresso,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          centerTitle: false,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Card
                  Container(
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
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                          child: SizedBox(
                            width: 120,
                            height: 140,
                            child: InkWell(
                              onTap: () => Get.to(() => ImageGridScreen(
                                    imageUrls: propertyImage ?? [],
                                    title: 'Property Images',
                                  )),
                              child: ThumbCollage(
                                urls: propertyImage ?? [],
                                height: 140,
                                width: 120,
                                borderRadius: 0,
                                spacing: 2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (order.service?.address?.geoLocation?.latitude != null &&
                                        order.service?.address?.geoLocation?.longitude != null) {
                                      await AppUtils().openMap(
                                        order.service?.address?.geoLocation?.latitude ?? 0,
                                        order.service?.address?.geoLocation?.longitude ?? 0);
                                    } else {
                                      Toast.showToast("Couldn't get coordinates. Please contact Admin.");
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: _sienna),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          address,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _walnut,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                          maxLines: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _getStatusColor(type),
                                      letterSpacing: 0.5,
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
                  const SizedBox(height: 24),
                  
                  // Task Details Header
                  const Text(
                    'Task Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _espresso,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Task List - Preserve completed tasks display
                  type == 'completed'
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _dividerLine),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: List.generate(controller.items.length, (index) {
                                return CheckboxListTile(
                                  checkColor: Colors.white,
                                  activeColor: _sienna,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    controller.items[index]['name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _walnut,
                                    ),
                                  ),
                                  value: true,
                                  onChanged: null, // Disabled for completed tasks
                                  controlAffinity: ListTileControlAffinity.trailing,
                                );
                              }),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tasks.map((task) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _siennaLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _siennaLight),
                            ),
                            child: Text(
                              task,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _walnut,
                              ),
                            ),
                          )).toList(),
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Staff Details (if applicable)
                  if (controller.isPGRAdmin && 
                      (order.workflow?.action != "CREATE" && order.service?.applicationStatus != "RESOLVED")) ...[
                    const Text(
                      'Staff Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _espresso,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _dividerLine),
                      ),
                      child: controller.isAssigneesLoading.value
                          ? _buildShimmerCard(context)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _siennaLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person_outline, size: 18, color: _sienna),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        controller.assignedStaff?.user?.name ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _espresso,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 16, color: _steel),
                                    const SizedBox(width: 12),
                                    Text(
                                      controller.assignedStaff?.user?.mobileNumber ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _walnut,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.date_range_outlined, size: 16, color: _steel),
                                    const SizedBox(width: 12),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _walnut,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Task Timeline
                  const Text(
                    'Task Timeline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _espresso,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _dividerLine),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTimelineItem('Created', Icons.lock_clock_outlined, startDate, _sienna),
                        _buildTimelineItem('Started', Icons.hourglass_bottom_outlined, acceptedDate, _amber),
                        _buildTimelineItem('Completed', Icons.check_circle_outlined, completedDate, _sage),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Employee Table (if applicable)
                  if (controller.isAssigneesLoading.value)
                    _buildShimmerCard(context)
                  else if (order.service?.applicationStatus != "RESOLVED" && controller.isPGRAdmin)
                    EmployeeTable(
                      employees: controller.assignees ?? [],
                      controller: controller,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Location Question - Preserve for completed/disabled state
                  if (order.service?.applicationStatus == "RESOLVED") ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _parchment,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _dividerLine),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Are you able to locate the property?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _espresso,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (_) {
                              final dynamic _utlRaw = additionalDetailMap['unableToLocateProperty'];
                              final bool _utlValue = (_utlRaw is bool)
                                  ? _utlRaw
                                  : (_utlRaw is String
                                      ? _utlRaw.toLowerCase() == 'true'
                                      : false);
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildRadioOptionDisabled(
                                      'No',
                                      true,
                                      _utlValue,
                                      Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildRadioOptionDisabled(
                                      'Yes',
                                      false,
                                      _utlValue,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (order.service?.applicationStatus != "RESOLVED" && controller.isHelpDeskUser) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _parchment,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _dividerLine),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Are you able to locate the property?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _espresso,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRadioOption(
                                  'No',
                                  true,
                                  controller.unableToLocate.value,
                                  Colors.red,
                                  () {
                                    controller.unableToLocate.value = true;
                                    if (controller.unableToLocate.value) {
                                      controller.selectedCheckBoxItems.clear();
                                      controller.images?.clear();
                                    }
                                    controller.update();
                                  },
                                ),
                              ),
                              Expanded(
                                child: _buildRadioOption(
                                  'Yes',
                                  false,
                                  controller.unableToLocate.value,
                                  Colors.green,
                                  () {
                                    controller.unableToLocate.value = false;
                                    controller.update();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Attached Evidence for Completed Tasks
                  if (order.service?.applicationStatus == "RESOLVED" && !controller.unableToLocate.value)
                    Builder(
                      builder: (context) {
                        final urls = (order.reportUrls ?? const <String>[])
                            .where((e) => (e).toString().trim().isNotEmpty)
                            .cast<String>()
                            .toList();
                        if (urls.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attached Evidence',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _espresso,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                Get.to(() => ImageGridScreen(
                                      imageUrls: urls,
                                      title: 'Attached Evidence',
                                    ));
                              },
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: _parchment,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _dividerLine),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.photo_library_outlined, size: 40, color: _steel),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${urls.length} image${urls.length == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _walnut,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  
                  // Image Upload Section (Active only)
                  if (order.service?.applicationStatus != "RESOLVED" &&
                      controller.isHelpDeskUser &&
                      !controller.unableToLocate.value) ...[
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Wrap(children: [
                              ListTile(
                                leading: const Icon(Icons.photo_camera, color: _sienna),
                                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () {
                                  Navigator.pop(context);
                                  controller.getImageFromCamera();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library, color: _sienna),
                                title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () {
                                  Navigator.pop(context);
                                  controller.getImageList();
                                },
                              ),
                            ]),
                          ),
                        );
                      },
                      child: DottedBorder(
                        dashPattern: [6, 6],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(16),
                        color: _steel,
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          child: Container(
                            height: 160,
                            width: Get.width,
                            color: _parchment,
                            child: (controller.images?.isEmpty ?? false)
                                ? Column(
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
                                        child: const Icon(Icons.add, size: 24, color: _steel),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Upload Images',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _walnut,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Tap to add evidence photos',
                                        style: TextStyle(fontSize: 11, color: _steel),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: controller.images!.length,
                                    itemBuilder: (context, index) {
                                      final XFile image = controller.images![index];
                                      return Container(
                                        width: 140,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                File(image.path),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => controller.removeImageList(index),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _espresso.withOpacity(0.8),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Checklist - Preserve completed checklist display
                  if (order.service?.applicationStatus == "RESOLVED" && !controller.unableToLocate.value)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completed Checklist',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _espresso,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _dividerLine),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                if (additionalDetailMap['checklist'] != null)
                                  ...additionalDetailMap['checklist']
                                      .toString()
                                      .split("|")
                                      .map((option) {
                                    String? displayName = controller.checkBoxOptions.firstWhere(
                                      (item) => item['key'] == option,
                                      orElse: () => {'name': option},
                                    )['name'];
                                    return CheckboxListTile(
                                      title: Text(
                                        displayName.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _walnut,
                                        ),
                                      ),
                                      value: true,
                                      onChanged: null,
                                      activeColor: _sienna,
                                      controlAffinity: ListTileControlAffinity.trailing,
                                      contentPadding: EdgeInsets.zero,
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  // Active Checklist
                  if (order.service?.applicationStatus != "RESOLVED" &&
                      controller.isHelpDeskUser &&
                      !controller.unableToLocate.value)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Checklist',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _espresso,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _dividerLine),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: List.generate(controller.checkBoxOptions.length, (index) {
                                Map<String, String>? option = controller.checkBoxOptions[index];
                                bool isChecked = controller.selectedCheckBoxItems.contains(option["key"]);
                                return CheckboxListTile(
                                  title: Text(
                                    option["name"].toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    if (value == true) {
                                      controller.selectedCheckBoxItems.add(option["key"].toString());
                                    } else {
                                      controller.selectedCheckBoxItems.remove(option["key"].toString());
                                    }
                                    controller.update();
                                  },
                                  activeColor: _sienna,
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  // Remarks - Preserve disabled remarks for completed tasks
                  if (order.service?.applicationStatus == "RESOLVED" && additionalDetailMap['remarks'].toString().isNotEmpty) ...[
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _parchment,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _dividerLine),
                      ),
                      child: TextFormField(
                        initialValue: additionalDetailMap['remarks'] ?? '',
                        readOnly: true,
                        enabled: false,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _steel,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Remarks',
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                  
                  // Active Remarks
                  if (order.service?.applicationStatus != "RESOLVED" && controller.isHelpDeskUser) ...[
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _dividerLine),
                      ),
                      child: TextFormField(
                        initialValue: controller.remarksCtrl.value,
                        onChanged: (v) => controller.remarksCtrl.value = v,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Enter remarks...',
                          hintStyle: TextStyle(color: _steel),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: RoundedLoadingButton(
              width: Get.width,
              color: _espresso,
              onPressed: () async {
                controller.updateBooking(order);
              },
              borderRadius: 14,
              controller: controller.btnController,
              child: Text(
                controller.isPGRAdmin && order.service?.applicationStatus != "RESOLVED"
                    ? 'Assign'
                    : controller.isHelpDeskUser && order.service?.applicationStatus != "RESOLVED"
                        ? 'Submit Report'
                        : 'Back',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _parchment,
      highlightColor: _cream,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: _parchment,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, IconData icon, String date, Color color) {
    final hasDate = date.isNotEmpty;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasDate ? color.withOpacity(0.1) : _parchment,
            shape: BoxShape.circle,
            border: Border.all(color: hasDate ? color : _dividerLine, width: 1.5),
          ),
          child: Icon(icon, size: 20, color: hasDate ? color : _steel),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: hasDate ? _espresso : _steel,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasDate ? _formatDate(date) : 'Pending',
          style: TextStyle(
            fontSize: 10,
            color: hasDate ? _steel : _steel.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, bool value, bool groupValue, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: groupValue == value ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: groupValue == value ? color : _dividerLine),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: groupValue == value ? color : _steel, width: 2),
              ),
              child: groupValue == value
                  ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: groupValue == value ? color : _steel)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOptionDisabled(String label, bool value, bool groupValue, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: groupValue == value ? color.withOpacity(0.1) : _parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: groupValue == value ? color : _dividerLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: groupValue == value ? color : _steel, width: 2),
            ),
            child: groupValue == value
                ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)))
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: groupValue == value ? color : _steel)),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM').format(date);
    } catch (_) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created': return _sienna;
      case 'pending': return _amber;
      case 'accepted': return _steel;
      case 'active': return _sage;
      case 'completed': return _sage;
      default: return _steel;
    }
  }
}
// import 'dart:convert';
// import 'dart:io';

// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:plotrol/controller/order_details_controlller.dart';
// import 'package:plotrol/globalWidgets/custom_scaffold_widget.dart';
// import 'package:plotrol/globalWidgets/flutter_toast.dart';
// import 'package:plotrol/helper/const_assets_const.dart';
// import 'package:plotrol/helper/utils.dart';
// import 'package:plotrol/model/response/employee_response/employee_search_response.dart';
// import 'package:plotrol/view/image_grid_screen.dart';
// import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:timeline_tile/timeline_tile.dart';

// import '../controller/home_screen_controller.dart';
// import '../globalWidgets/dropdown_widget.dart';
// import '../globalWidgets/employee_table.dart';
// import '../globalWidgets/text_widget.dart';
// import '../model/response/book_service/pgr_create_response.dart';
// import '../widgets/thumbnail_collage.dart';
// import 'main_screen.dart';

// // ── Design tokens (matching home screen) ────────────────────────────────────
// const _cream = Color(0xFFF7F3EE);
// const _parchment = Color(0xFFEFE9DF);
// const _sand = Color(0xFFE4DAC8);
// const _espresso = Color(0xFF1C1510);
// const _walnut = Color(0xFF3D2B1F);
// const _sienna = Color(0xFFB85C38);
// const _siennaLight = Color(0x1AB85C38);
// const _steel = Color(0xFF8C8480);
// const _dividerLine = Color(0xFFDDD5C8);
// const _amber = Color(0xFFD4830A);
// const _sage = Color(0xFF6B8C6E);
// // ─────────────────────────────────────────────────────────────────────────────

// class OrderDetailScreen extends StatelessWidget {
//   final String address;
//   final String suburb;
//   final String date;
//   final String tenantName;
//   final String tenantContactName;
//   final List<String> tasks;
//   final List<String>? propertyImage;
//   final List<String>? orderImages;
//   final String type;
//   final String orderID;
//   final String tenantLatitude;
//   final String tenantLongitude;
//   final String staffName;
//   final String staffMobileNumber;
//   final String staffLocation;
//   final String acceptedDate;
//   final String startDate;
//   final String completedDate;
//   final ServiceWrapper order;

//   OrderDetailScreen({
//     super.key,
//     this.suburb = '',
//     this.date = '',
//     this.tenantName = '',
//     this.address = '',
//     this.tenantContactName = '',
//     this.tenantLatitude = '',
//     this.tenantLongitude = '',
//     this.staffLocation = '',
//     this.staffMobileNumber = '',
//     this.staffName = '',
//     required this.tasks,
//     required this.propertyImage,
//     this.orderImages,
//     this.startDate = '',
//     this.completedDate = '',
//     this.acceptedDate = '',
//     required this.type,
//     required this.orderID,
//     required this.order,
//   });

//   final OrderDetailsController orderDetailsController =
//       Get.put(OrderDetailsController());

//   final HomeScreenController homeScreenController =
//       Get.put(HomeScreenController());

//   @override
//   Widget build(BuildContext context) {
//     final Map<String, dynamic> additionalDetailMap =
//         order.service!.additionalDetail != null
//             ? Map<String, dynamic>.from(order.service!.additionalDetail!)
//             : {};
//     return GetBuilder<OrderDetailsController>(initState: (_) {
//       orderDetailsController.getCheckList();
//       orderDetailsController.getAssignees(order);
//       if (type == 'completed') {
//         orderDetailsController.setItems(tasks);
//       }
//     }, builder: (controller) {
//       return Scaffold(
//         backgroundColor: _cream,
//         appBar: AppBar(
//           backgroundColor: _cream,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios, size: 20, color: _espresso),
//             onPressed: () => Get.back(),
//           ),
//           title: const Text(
//             'Order Details',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.w800,
//               color: _espresso,
//               letterSpacing: -0.8,
//               height: 1.1,
//             ),
//           ),
//         ),
//         body: LayoutBuilder(builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             physics: const BouncingScrollPhysics(),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(minHeight: constraints.maxHeight),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Property Card
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(24),
//                       border: Border.all(color: _dividerLine),
//                       boxShadow: [
//                         BoxShadow(
//                           color: _espresso.withOpacity(0.06),
//                           blurRadius: 24,
//                           offset: const Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         ClipRRect(
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(24),
//                             bottomLeft: Radius.circular(24),
//                           ),
//                           child: SizedBox(
//                             width: 120,
//                             height: 140,
//                             child: InkWell(
//                               onTap: () => Get.to(() => ImageGridScreen(
//                                     imageUrls: propertyImage ?? [],
//                                     title: 'Property Images',
//                                   )),
//                               child: ThumbCollage(
//                                 urls: propertyImage ?? [],
//                                 height: 140,
//                                 width: 120,
//                                 borderRadius: 0,
//                                 spacing: 2,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 GestureDetector(
//                                   onTap: () async {
//                                     if (order.service?.address?.geoLocation?.latitude != null &&
//                                         order.service?.address?.geoLocation?.longitude != null) {
//                                       await AppUtils().openMap(
//                                         order.service?.address?.geoLocation?.latitude ?? 0,
//                                         order.service?.address?.geoLocation?.longitude ?? 0);
//                                     } else {
//                                       Toast.showToast("Couldn't get coordinates. Please contact Admin.");
//                                     }
//                                   },
//                                   child: Row(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Icon(Icons.location_on_outlined, size: 16, color: _sienna),
//                                       const SizedBox(width: 6),
//                                       Expanded(
//                                         child: Text(
//                                           address,
//                                           style: const TextStyle(
//                                             fontSize: 13,
//                                             color: _walnut,
//                                             fontWeight: FontWeight.w500,
//                                             height: 1.4,
//                                           ),
//                                           maxLines: 3,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: _getStatusColor(type).withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     type.toUpperCase(),
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w800,
//                                       color: _getStatusColor(type),
//                                       letterSpacing: 0.5,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
                  
//                   // Task Details Header
//                   const Text(
//                     'Task Details',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w800,
//                       color: _espresso,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   // Task List - Preserve completed tasks display
//                   type == 'completed'
//                       ? Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: _dividerLine),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8),
//                             child: Column(
//                               children: List.generate(controller.items.length, (index) {
//                                 return CheckboxListTile(
//                                   checkColor: Colors.white,
//                                   activeColor: _sienna,
//                                   contentPadding: EdgeInsets.zero,
//                                   title: Text(
//                                     controller.items[index]['name'],
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                       color: _walnut,
//                                     ),
//                                   ),
//                                   value: true,
//                                   onChanged: null, // Disabled for completed tasks
//                                   controlAffinity: ListTileControlAffinity.trailing,
//                                 );
//                               }),
//                             ),
//                           ),
//                         )
//                       : Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: tasks.map((task) => Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: _siennaLight,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: _siennaLight),
//                             ),
//                             child: Text(
//                               task,
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: _walnut,
//                               ),
//                             ),
//                           )).toList(),
//                         ),
                  
//                   const SizedBox(height: 24),
                  
//                   // Staff Details (if applicable)
//                   if (controller.isPGRAdmin && 
//                       (order.workflow?.action != "CREATE" && order.service?.applicationStatus != "RESOLVED")) ...[
//                     const Text(
//                       'Staff Details',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w800,
//                         color: _espresso,
//                         letterSpacing: -0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: _dividerLine),
//                       ),
//                       child: controller.isAssigneesLoading.value
//                           ? _buildShimmerCard(context)
//                           : Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Container(
//                                       width: 36,
//                                       height: 36,
//                                       decoration: BoxDecoration(
//                                         color: _siennaLight,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: const Icon(Icons.person_outline, size: 18, color: _sienna),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text(
//                                         controller.assignedStaff?.user?.name ?? '',
//                                         style: const TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w600,
//                                           color: _espresso,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 12),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.phone_outlined, size: 16, color: _steel),
//                                     const SizedBox(width: 12),
//                                     Text(
//                                       controller.assignedStaff?.user?.mobileNumber ?? '',
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         color: _walnut,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.date_range_outlined, size: 16, color: _steel),
//                                     const SizedBox(width: 12),
//                                     Text(
//                                       date,
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         color: _walnut,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                     ),
//                     const SizedBox(height: 24),
//                   ],
                  
//                   // Task Timeline
//                   const Text(
//                     'Task Timeline',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w800,
//                       color: _espresso,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Container(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: _dividerLine),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildTimelineItem('Created', Icons.lock_clock_outlined, startDate, _sienna),
//                         _buildTimelineItem('Started', Icons.hourglass_bottom_outlined, acceptedDate, _amber),
//                         _buildTimelineItem('Completed', Icons.check_circle_outlined, completedDate, _sage),
//                       ],
//                     ),
//                   ),
                  
//                   const SizedBox(height: 24),
                  
//                   // Employee Table (if applicable)
//                   if (controller.isAssigneesLoading.value)
//                     _buildShimmerCard(context)
//                   else if (order.service?.applicationStatus != "RESOLVED" && controller.isPGRAdmin)
//                     EmployeeTable(
//                       employees: controller.assignees ?? [],
//                       controller: controller,
//                     ),
                  
//                   const SizedBox(height: 16),
                  
//                   // Location Question - Preserve for completed/disabled state
//                   if (order.service?.applicationStatus == "RESOLVED") ...[
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: _parchment,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: _dividerLine),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Are you able to locate the property?',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w800,
//                               color: _espresso,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Builder(
//                             builder: (_) {
//                               final dynamic _utlRaw = additionalDetailMap['unableToLocateProperty'];
//                               final bool _utlValue = (_utlRaw is bool)
//                                   ? _utlRaw
//                                   : (_utlRaw is String
//                                       ? _utlRaw.toLowerCase() == 'true'
//                                       : false);
//                               return Row(
//                                 children: [
//                                   Expanded(
//                                     child: _buildRadioOptionDisabled(
//                                       'No',
//                                       true,
//                                       _utlValue,
//                                       Colors.red,
//                                     ),
//                                   ),
//                                   Expanded(
//                                     child: _buildRadioOptionDisabled(
//                                       'Yes',
//                                       false,
//                                       _utlValue,
//                                       Colors.green,
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ] else if (order.service?.applicationStatus != "RESOLVED" && controller.isHelpDeskUser) ...[
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: _parchment,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: _dividerLine),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Are you able to locate the property?',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w800,
//                               color: _espresso,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildRadioOption(
//                                   'No',
//                                   true,
//                                   controller.unableToLocate.value,
//                                   Colors.red,
//                                   () {
//                                     controller.unableToLocate.value = true;
//                                     if (controller.unableToLocate.value) {
//                                       controller.selectedCheckBoxItems.clear();
//                                       controller.images?.clear();
//                                     }
//                                     controller.update();
//                                   },
//                                 ),
//                               ),
//                               Expanded(
//                                 child: _buildRadioOption(
//                                   'Yes',
//                                   false,
//                                   controller.unableToLocate.value,
//                                   Colors.green,
//                                   () {
//                                     controller.unableToLocate.value = false;
//                                     controller.update();
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
                  
//                   // Attached Evidence for Completed Tasks
//                   if (order.service?.applicationStatus == "RESOLVED" && !controller.unableToLocate.value)
//                     Builder(
//                       builder: (context) {
//                         final urls = (order.reportUrls ?? const <String>[])
//                             .where((e) => (e).toString().trim().isNotEmpty)
//                             .cast<String>()
//                             .toList();
//                         if (urls.isEmpty) return const SizedBox.shrink();
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Attached Evidence',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w800,
//                                 color: _espresso,
//                                 letterSpacing: -0.5,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             InkWell(
//                               onTap: () {
//                                 Get.to(() => ImageGridScreen(
//                                       imageUrls: urls,
//                                       title: 'Attached Evidence',
//                                     ));
//                               },
//                               child: Container(
//                                 width: 120,
//                                 height: 120,
//                                 decoration: BoxDecoration(
//                                   color: _parchment,
//                                   borderRadius: BorderRadius.circular(16),
//                                   border: Border.all(color: _dividerLine),
//                                 ),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(Icons.photo_library_outlined, size: 40, color: _steel),
//                                     const SizedBox(height: 8),
//                                     Text(
//                                       '${urls.length} image${urls.length == 1 ? '' : 's'}',
//                                       style: const TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w600,
//                                         color: _walnut,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//                           ],
//                         );
//                       },
//                     ),
                  
//                   // Image Upload Section (Active only)
//                   if (order.service?.applicationStatus != "RESOLVED" &&
//                       controller.isHelpDeskUser &&
//                       !controller.unableToLocate.value) ...[
//                     InkWell(
//                       onTap: () {
//                         showModalBottomSheet(
//                           context: context,
//                           builder: (_) => SafeArea(
//                             child: Wrap(children: [
//                               ListTile(
//                                 leading: const Icon(Icons.photo_camera, color: _sienna),
//                                 title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   controller.getImageFromCamera();
//                                 },
//                               ),
//                               ListTile(
//                                 leading: const Icon(Icons.photo_library, color: _sienna),
//                                 title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   controller.getImageList();
//                                 },
//                               ),
//                             ]),
//                           ),
//                         );
//                       },
//                       child: DottedBorder(
//                         dashPattern: [6, 6],
//                         borderType: BorderType.RRect,
//                         radius: const Radius.circular(16),
//                         color: _steel,
//                         padding: const EdgeInsets.all(6),
//                         child: ClipRRect(
//                           borderRadius: const BorderRadius.all(Radius.circular(16)),
//                           child: Container(
//                             height: 160,
//                             width: Get.width,
//                             color: _parchment,
//                             child: (controller.images?.isEmpty ?? false)
//                                 ? Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Container(
//                                         width: 52,
//                                         height: 52,
//                                         decoration: BoxDecoration(
//                                           color: _cream,
//                                           shape: BoxShape.circle,
//                                           border: Border.all(color: _sand, width: 1.5),
//                                         ),
//                                         child: const Icon(Icons.add, size: 24, color: _steel),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       const Text(
//                                         'Upload Images',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w700,
//                                           color: _walnut,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       const Text(
//                                         'Tap to add evidence photos',
//                                         style: TextStyle(fontSize: 11, color: _steel),
//                                       ),
//                                     ],
//                                   )
//                                 : ListView.builder(
//                                     scrollDirection: Axis.horizontal,
//                                     itemCount: controller.images!.length,
//                                     itemBuilder: (context, index) {
//                                       final XFile image = controller.images![index];
//                                       return Container(
//                                         width: 140,
//                                         margin: const EdgeInsets.symmetric(horizontal: 4),
//                                         child: Stack(
//                                           fit: StackFit.expand,
//                                           children: [
//                                             ClipRRect(
//                                               borderRadius: BorderRadius.circular(12),
//                                               child: Image.file(
//                                                 File(image.path),
//                                                 fit: BoxFit.cover,
//                                               ),
//                                             ),
//                                             Positioned(
//                                               top: 4,
//                                               right: 4,
//                                               child: GestureDetector(
//                                                 onTap: () => controller.removeImageList(index),
//                                                 child: Container(
//                                                   decoration: BoxDecoration(
//                                                     color: _espresso.withOpacity(0.8),
//                                                     shape: BoxShape.circle,
//                                                   ),
//                                                   child: const Icon(Icons.close, size: 20, color: Colors.white),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
                  
//                   // Checklist - Preserve completed checklist display
//                   if (order.service?.applicationStatus == "RESOLVED" && !controller.unableToLocate.value)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Completed Checklist',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w800,
//                             color: _espresso,
//                             letterSpacing: -0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: _dividerLine),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8),
//                             child: Column(
//                               children: [
//                                 if (additionalDetailMap['checklist'] != null)
//                                   ...additionalDetailMap['checklist']
//                                       .toString()
//                                       .split("|")
//                                       .map((option) {
//                                     String? displayName = controller.checkBoxOptions.firstWhere(
//                                       (item) => item['key'] == option,
//                                       orElse: () => {'name': option},
//                                     )['name'];
//                                     return CheckboxListTile(
//                                       title: Text(
//                                         displayName.toString(),
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w500,
//                                           color: _walnut,
//                                         ),
//                                       ),
//                                       value: true,
//                                       onChanged: null,
//                                       activeColor: _sienna,
//                                       controlAffinity: ListTileControlAffinity.trailing,
//                                       contentPadding: EdgeInsets.zero,
//                                     );
//                                   }).toList(),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
                  
//                   // Active Checklist
//                   if (order.service?.applicationStatus != "RESOLVED" &&
//                       controller.isHelpDeskUser &&
//                       !controller.unableToLocate.value)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Checklist',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w800,
//                             color: _espresso,
//                             letterSpacing: -0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: _dividerLine),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8),
//                             child: Column(
//                               children: List.generate(controller.checkBoxOptions.length, (index) {
//                                 Map<String, String>? option = controller.checkBoxOptions[index];
//                                 bool isChecked = controller.selectedCheckBoxItems.contains(option["key"]);
//                                 return CheckboxListTile(
//                                   title: Text(
//                                     option["name"].toString(),
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                   value: isChecked,
//                                   onChanged: (bool? value) {
//                                     if (value == true) {
//                                       controller.selectedCheckBoxItems.add(option["key"].toString());
//                                     } else {
//                                       controller.selectedCheckBoxItems.remove(option["key"].toString());
//                                     }
//                                     controller.update();
//                                   },
//                                   activeColor: _sienna,
//                                   controlAffinity: ListTileControlAffinity.trailing,
//                                   contentPadding: EdgeInsets.zero,
//                                 );
//                               }),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
                  
//                   // Remarks - Preserve disabled remarks for completed tasks
//                   if (order.service?.applicationStatus == "RESOLVED" && additionalDetailMap['remarks'].toString().isNotEmpty) ...[
//                     const Text(
//                       'Remarks',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: _espresso,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: _parchment,
//                         borderRadius: BorderRadius.circular(14),
//                         border: Border.all(color: _dividerLine),
//                       ),
//                       child: TextFormField(
//                         initialValue: additionalDetailMap['remarks'] ?? '',
//                         readOnly: true,
//                         enabled: false,
//                         maxLines: 3,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: _steel,
//                         ),
//                         decoration: const InputDecoration(
//                           hintText: 'Remarks',
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                           contentPadding: EdgeInsets.all(16),
//                         ),
//                       ),
//                     ),
//                   ],
                  
//                   // Active Remarks
//                   if (order.service?.applicationStatus != "RESOLVED" && controller.isHelpDeskUser) ...[
//                     const Text(
//                       'Remarks',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: _espresso,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(14),
//                         border: Border.all(color: _dividerLine),
//                       ),
//                       child: TextFormField(
//                         initialValue: controller.remarksCtrl.value,
//                         onChanged: (v) => controller.remarksCtrl.value = v,
//                         maxLines: 3,
//                         style: const TextStyle(fontSize: 14),
//                         decoration: const InputDecoration(
//                           hintText: 'Enter remarks...',
//                           hintStyle: TextStyle(color: _steel),
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                           contentPadding: EdgeInsets.all(16),
//                         ),
//                       ),
//                     ),
//                   ],
                  
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//           );
//         }),
//         bottomNavigationBar: SafeArea(
//           child: Container(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//             child: RoundedLoadingButton(
//               width: Get.width,
//               color: _espresso,
//               onPressed: () async {
//                 controller.updateBooking(order);
//               },
//               borderRadius: 14,
//               controller: controller.btnController,
//               child: Text(
//                 controller.isPGRAdmin && order.service?.applicationStatus != "RESOLVED"
//                     ? 'Assign'
//                     : controller.isHelpDeskUser && order.service?.applicationStatus != "RESOLVED"
//                         ? 'Submit Report'
//                         : 'Back',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildShimmerCard(BuildContext context) {
//     return Shimmer.fromColors(
//       baseColor: _parchment,
//       highlightColor: _cream,
//       child: Container(
//         height: 150,
//         decoration: BoxDecoration(
//           color: _parchment,
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }

//   Widget _buildTimelineItem(String title, IconData icon, String date, Color color) {
//     final hasDate = date.isNotEmpty;
//     return Column(
//       children: [
//         Container(
//           width: 44,
//           height: 44,
//           decoration: BoxDecoration(
//             color: hasDate ? color.withOpacity(0.1) : _parchment,
//             shape: BoxShape.circle,
//             border: Border.all(color: hasDate ? color : _dividerLine, width: 1.5),
//           ),
//           child: Icon(icon, size: 20, color: hasDate ? color : _steel),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             color: hasDate ? _espresso : _steel,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           hasDate ? _formatDate(date) : 'Pending',
//           style: TextStyle(
//             fontSize: 10,
//             color: hasDate ? _steel : _steel.withOpacity(0.6),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRadioOption(String label, bool value, bool groupValue, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: groupValue == value ? color.withOpacity(0.1) : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: groupValue == value ? color : _dividerLine),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 18,
//               height: 18,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: groupValue == value ? color : _steel, width: 2),
//               ),
//               child: groupValue == value
//                   ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)))
//                   : null,
//             ),
//             const SizedBox(width: 8),
//             Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: groupValue == value ? color : _steel)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRadioOptionDisabled(String label, bool value, bool groupValue, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       decoration: BoxDecoration(
//         color: groupValue == value ? color.withOpacity(0.1) : _parchment,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: groupValue == value ? color : _dividerLine),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 18,
//             height: 18,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: groupValue == value ? color : _steel, width: 2),
//             ),
//             child: groupValue == value
//                 ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)))
//                 : null,
//           ),
//           const SizedBox(width: 8),
//           Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: groupValue == value ? color : _steel)),
//         ],
//       ),
//     );
//   }

//   String _formatDate(String dateString) {
//     if (dateString.isEmpty) return '';
//     try {
//       final date = DateTime.parse(dateString);
//       return DateFormat('dd MMM').format(date);
//     } catch (_) {
//       return '';
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'created': return _sienna;
//       case 'pending': return _amber;
//       case 'accepted': return _steel;
//       case 'active': return _sage;
//       case 'completed': return _sage;
//       default: return _steel;
//     }
//   }
// }