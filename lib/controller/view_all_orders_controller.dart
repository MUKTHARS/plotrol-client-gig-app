import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/data/repository/orders/orders_repository.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/model/response/book_service/pgr_create_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../globalWidgets/flutter_toast.dart';
import '../helper/api_constants.dart';
import '../model/response/autentication_response/autentication_response.dart';
import '../model/response/book_service/file_store_model.dart';

class ViewAllOrdersController extends GetxController with GetTickerProviderStateMixin {
  // TabController
  late TabController tabController;

  // Observable properties
  RxBool isLoading = true.obs;
  RxBool isHelpDeskUser = false.obs;
  RxBool isPGRAdmin = false.obs;
  RxBool isScreenLoading = true.obs;
  Rx<DateTime> fromDate = DateTime.now().obs;
  Rx<DateTime> toDate = DateTime.now().obs;

  // Orders list
  List<ServiceWrapper> filteredOrders = [];
  List<ServiceWrapper> pendingOrders = [];
  List<ServiceWrapper> ongoingOrders = [];
  List<ServiceWrapper> completedOrders = [];

  final GetOrdersRepository _getOrdersRepository = GetOrdersRepository();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
  }

  // Check user role
  Future<void> checkForRole() async {
    isScreenLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userInfoString = prefs.getString('userInfo');
      if (userInfoString != null && userInfoString.isNotEmpty) {
        UserRequest? user = UserRequest.fromJson(jsonDecode(userInfoString));
        isHelpDeskUser.value = AppUtils().checkIsGig(user.roles ?? []);
        isPGRAdmin.value = AppUtils().checkIsPGRAdmin(user.roles ?? []);
      }
      final int tabCount = isHelpDeskUser.value ? 2 : 3;
      if (tabController.length != tabCount) {
        final oldController = tabController;
        tabController = TabController(length: tabCount, vsync: this);
        WidgetsBinding.instance.addPostFrameCallback((_) => oldController.dispose());
      }
    } catch (e) {
      print('Error in checkForRole: $e');
    }
    isScreenLoading.value = false;
    update();
  }

  // Initialize with last 2 days as default
  void initializeDateRange() {
    final now = DateTime.now();
    toDate.value = now;
    fromDate.value = now.subtract(const Duration(days: 2));
    update();
  }

  // Fetch orders by custom date range
  Future<void> fetchOrdersByDateRange() async {
    // Validate date range
    if (fromDate.value.isAfter(toDate.value)) {
      Toast.showErrorToast('From Date cannot be after To Date');
      return;
    }

    isLoading.value = true;
    update();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final mobileNumber = prefs.getString('mobileNumber');
      String? userInfoString = prefs.getString('userInfo');
      UserRequest? userRequest = (userInfoString ?? "").isNotEmpty
          ? UserRequest.fromJson(jsonDecode(userInfoString!))
          : null;

      // Get start and end of selected days
      final fromDayRange = AppUtils.getDayStartAndEnd(fromDate.value);
      final toDayRange = AppUtils.getDayStartAndEnd(toDate.value);

      PgrServiceResponse? result = await _getOrdersRepository.getOrders(
        AppUtils().checkIsHousehold(userRequest?.roles ?? []) &&
        (!AppUtils().checkIsPGRAdmin(userRequest?.roles ?? []))
          ? {
              'mobileNumber': mobileNumber,
              "fromDate": fromDayRange.startMillis.toString(),
              "toDate": toDayRange.endMillis.toString(),
            }
          : {
              "fromDate": fromDayRange.startMillis.toString(),
              "toDate": toDayRange.endMillis.toString(),
            }
      );

      if (result == null) {
        Toast.showErrorToast('Failed to fetch orders. Please try again.');
        filteredOrders.clear();
      } else if ((result.serviceWrappers ?? []).isNotEmpty) {
        // Filter orders to only show PLOTROL app records
        final plotrolOrders = result.serviceWrappers
            ?.where((s) => s.service?.additionalDetail?['appSource'] == 'PLOTROL')
            .toList() ?? [];

        // Get enriched orders with images
        // For Gig workers: only show assigned orders or resolved orders
        // For PGR admin/Household: show all orders
        final allOrders = AppUtils().checkIsGig(userRequest?.roles ?? [])
            ? await enrichOrdersWithImageUrls(
                plotrolOrders
                        .where((s) =>
                            (s.workflow?.assignes ?? []).contains(userRequest?.uuid) ||
                            s.service?.applicationStatus == "RESOLVED")
                        .toList(),
                ApiConstants.tenantId)
            : await enrichOrdersWithImageUrls(
                plotrolOrders,
                ApiConstants.tenantId);

        // Filter by lastModifiedTime
        filteredOrders = filterOrdersByLastModifiedDate(
          allOrders,
          fromDayRange.startMillis,
          toDayRange.endMillis,
        );

        // Categorize orders by status
        pendingOrders.clear();
        ongoingOrders.clear();
        completedOrders.clear();

        for (var order in filteredOrders) {
          final status = AppUtils().getOrderStatus(order);
          if (status == 'created' || status == 'pending') {
            pendingOrders.add(order);
          } else if (status == 'accepted' || status == 'active') {
            ongoingOrders.add(order);
          } else if (status == 'completed') {
            completedOrders.add(order);
          }
        }

        if (filteredOrders.isEmpty) {
          Toast.showInfoToast('No orders found for the selected date range');
        }
      } else {
        filteredOrders.clear();
        Toast.showInfoToast('No orders found for the selected date range');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      Toast.showErrorToast('Error fetching orders. Please check your connection and try again.');
      filteredOrders.clear();
    }

    isLoading.value = false;
    update();
  }

  // Filter orders by lastModifiedTime
  List<ServiceWrapper> filterOrdersByLastModifiedDate(
    List<ServiceWrapper> orders,
    int fromMillis,
    int toMillis,
  ) {
    return orders.where((order) {
      final lastModifiedTime = order.service?.auditDetails?.lastModifiedTime ?? 0;
      return lastModifiedTime >= fromMillis && lastModifiedTime <= toMillis;
    }).toList();
  }

  // Enrich orders with image URLs (copied from HomeScreenController)
  Future<List<ServiceWrapper>> enrichOrdersWithImageUrls(
      List<ServiceWrapper> orders,
      String tenantId,
      ) async {
    try {
      // ---------- HOUSEHOLD: image_1...image_n ----------
      // Keep per-order ordered ids, and a global set for a single fetch
      final Map<ServiceWrapper, List<String>> orderToHouseholdIds = {};
      final Set<String> allHouseholdIds = {};

      for (final ord in orders) {
        final Map<String, dynamic>? detail = ord.service?.additionalDetail;
        if (detail == null) continue;

        final hhDyn = detail['household'];
        final Map<String, dynamic>? hh =
        (hhDyn is Map) ? hhDyn.cast<String, dynamic>() : null;
        if (hh == null) continue;

        // collect (index, id) from image_1...image_n
        final List<MapEntry<int, String>> indexed = [];
        for (final entry in hh.entries) {
          final key = entry.key?.toString() ?? '';
          if (!key.startsWith('image_')) continue;

          final id = entry.value?.toString() ?? '';
          if (id.trim().isEmpty) continue;

          final idx = int.tryParse(key.substring('image_'.length)) ?? -1;
          if (idx > 0) indexed.add(MapEntry(idx, id));
        }

        if (indexed.isEmpty) continue;

        indexed.sort((a, b) => a.key.compareTo(b.key));
        final ids = indexed.map((e) => e.value).toList();

        orderToHouseholdIds[ord] = ids;
        allHouseholdIds.addAll(ids);
      }

      if (allHouseholdIds.isNotEmpty) {
        final models = await fetchFiles(allHouseholdIds.toList(), tenantId);
        final Map<String, String> idToUrl = {
          for (final f in (models ?? <FileStoreModel>[]))
            if ((f.url ?? '').isNotEmpty && (f.id ?? '').isNotEmpty) f.id.toString(): f.url!.split(',').first
        };

        for (final entry in orderToHouseholdIds.entries) {
          final urls = <String>[];
          for (final id in entry.value) {
            final url = idToUrl[id];
            if (url != null && url.isNotEmpty) urls.add(url);
          }
          // dedupe, keep order
          final seen = <String>{};
          entry.key.imageUrls = urls.where((u) => seen.add(u)).toList();
        }
      }

      // ---------- REPORT: report_1...report_n (unchanged) ----------
      final Map<String, List<ServiceWrapper>> reportFileIdToOrders = {};
      for (final order in orders) {
        final Map<String, dynamic>? detail = order.service?.additionalDetail;
        if (detail == null) continue;

        for (final entry in detail.entries) {
          final key = entry.key.toString() ?? '';
          if (!key.startsWith('report_')) continue;
          final id = entry.value?.toString() ?? '';
          if (id.trim().isEmpty) continue;
          reportFileIdToOrders.putIfAbsent(id, () => <ServiceWrapper>[]).add(order);
        }
      }

      if (reportFileIdToOrders.isNotEmpty) {
        final reportIds = reportFileIdToOrders.keys.toList();
        final models = await fetchFiles(reportIds, tenantId);
        final Map<String, String> idToUrl = {
          for (final f in (models ?? <FileStoreModel>[]))
            if ((f.url ?? '').isNotEmpty && (f.id ?? '').isNotEmpty) f.id.toString() : f.url!.split(',').first
        };

        for (final id in reportFileIdToOrders.keys) {
          final url = idToUrl[id];
          if (url == null || url.isEmpty) continue;
          for (final ord in reportFileIdToOrders[id]!) {
            ord.reportUrls ??= <String>[];
            if (!ord.reportUrls!.contains(url)) ord.reportUrls!.add(url);
          }
        }
      }

      return orders;
    } catch (_) {
      return orders; // fail-soft
    }
  }

  // Fetch file metadata (copied from HomeScreenController)
  Future<List<FileStoreModel>?> fetchFiles(List<String> storeIds, String tenantId) async {
    List<FileStoreModel>? fileStoreIds;
    FileStoreListModel? fileStoreListModel;

    final uri = Uri.parse(
      '${ApiConstants.host}${ApiConstants.fileFetch}?tenantId=$tenantId&fileStoreIds=${storeIds.join(",")}',
    );

    final headers = {
      'accept': 'application/json, text/plain, */*',
    };

    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      fileStoreListModel = FileStoreListModel.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    } else {
      print('Failed to fetch files: ${res.statusCode} ${res.body}');
    }

    return fileStoreListModel?.fileStoreIds;
  }

  // Select From Date
  Future<void> selectFromDate(BuildContext context) async {
    final DateTime oneYearAgo = DateTime.now().subtract(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate.value,
      firstDate: oneYearAgo,
      lastDate: toDate.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != fromDate.value) {
      fromDate.value = picked;
      update();
    }
  }

  // Select To Date
  Future<void> selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate.value,
      firstDate: fromDate.value,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != toDate.value) {
      toDate.value = picked;
      update();
    }
  }
}
