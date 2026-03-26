import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:intl/intl.dart';
import 'package:plotrol/Helper/Logger.dart';
import 'package:plotrol/data/repository/Tenant_Details/get_tenant_repository.dart';
import 'package:plotrol/data/repository/orders/orders_repository.dart';
import 'package:plotrol/helper/api_constants.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/model/response/autentication_response/autentication_response.dart';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository/autentication/login_repository.dart';
import '../data/repository/get_properties/get_properties_repository.dart';
import '../data/repository/get_properties/get_property_member.dart';
import '../model/response/adding_properties/get_properties_response.dart';
import '../model/response/book_service/file_store_model.dart';
import '../model/response/book_service/pgr_create_response.dart';
import '../model/response/household_member/household_member_response.dart';
import '../model/response/individual/individual_response.dart';

class HomeScreenController extends GetxController {
  RxInt selectedIndex = 0.obs;

  RxString name = ''.obs;

  RxString lastName = ''.obs;

  RxString profileImage = ''.obs;

  RxString email = ''.obs;

  RxString tenantId = ''.obs;

  PageController pageController = PageController();

  RxBool isPropertyLoading = true.obs;

  RxBool isOrderLoading = true.obs;

  RxBool isTenantDetailLoading = true.obs;

  final GetPropertiesRepository _getPropertiesRepository =
      GetPropertiesRepository();

  final GetOrdersRepository _getOrdersRepository = GetOrdersRepository();

  final GetTenantRepository _getTenantRepository = GetTenantRepository();
  LoginRepository loginRepository = LoginRepository();
  GetHouseholdMemberRepository householdMemberRepository = GetHouseholdMemberRepository();

  GetPropertiesRepository householdRepository = GetPropertiesRepository();

  final RoundedLoadingButtonController btnController =
      RoundedLoadingButtonController();

  List<ServiceWrapper> todayOrders = [];

  List<ServiceWrapper> otherOrders = [];

  List<ServiceWrapper> activeOrders = [];

  List<ServiceWrapper> completedOrders = [];

  List<ServiceWrapper> acceptedOrders = [];

  List<ServiceWrapper> pendingOrders = [];

  List<ServiceWrapper> createdOrders = [];

  List<String> address = [];

  List<String> notes = [];

  List<String> phoneNumber = [];

  List<List<String>> tenantImages = [];

  List<Household> getPropertiesDetails = [];

  List<ServiceWrapper> getOrderDetails = [];

  RxString tenantFirstName = ''.obs;

  RxString tenantLastName = ''.obs;

  RxString tenantProfileImage = ''.obs;

  RxString tenantEmail = ''.obs;

  RxInt tenantStaffId = 0.obs;

  RxString tenantContactNumber = ''.obs;

  RxString tenantLocation = ''.obs;

  RxString tenantSuburb = ''.obs;

  RxString tenantCity = ''.obs;

  RxString tenantState = ''.obs;

  RxString tenantPinCode = ''.obs;

  RxString tenantAccountNumber = ''.obs;

  RxString tenantAccountName = ''.obs;

  RxString tenantIfSSSCode = ''.obs;

  RxString tenantBankName = ''.obs;

  RxString tenantBranchName = ''.obs;

  RxString tenantAccountType = ''.obs;
  RxBool isDistributor = false.obs;
  RxBool isGigWorker = false.obs;
  RxBool isPGRAdmin = false.obs;


  void getDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    name.value = prefs.getString('name') ?? '';
    lastName.value = prefs.getString('lastName') ?? '';
    profileImage.value = prefs.getString('tenantImage') ?? 'https://plus.unsplash.com/premium_photo-1697729606469-027395aadb6f?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    email.value = prefs.getString('EmailId') ?? '';
    tenantId.value = prefs.getString('tenantId') ?? 'mz';
    tenantFirstName.value = prefs.getString('name') ?? '';
    String? userInfoString = prefs.getString('userInfo');
    UserRequest? userRequest = (userInfoString ?? "").isNotEmpty ? UserRequest.fromJson(jsonDecode(userInfoString!)) : null;
    isDistributor.value = AppUtils().checkIsHousehold(userRequest?.roles ?? []);
    isPGRAdmin.value = AppUtils().checkIsPGRAdmin(userRequest?.roles ?? []);
    isGigWorker.value = AppUtils().checkIsGig(userRequest?.roles ?? []);
    update();
  }

  void onTapped(int index) {
    selectedIndex.value = index;
    update();
  }

  void updateLoadingState() {
    isOrderLoading.value = true;
    update();
  }

  getPropertiesApiFunction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ApiConstants.tenantId = prefs.getInt('tenantId') ?? 0;
    print('tenatIdLocation : ${ApiConstants.tenantId}');
    ApiConstants.getProperties = ApiConstants.getPropertiesLive;
    getProperties();
  }

  getOrdersApiFunction() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    //ApiConstants.tenantId = prefs.getInt('tenantId') ?? 0;
    print('TenantIdForOrders : ${ApiConstants.tenantId}');
    ApiConstants.getOrders = ApiConstants.getOrderLive;
    //[TODO: Get Complaints Logic Implementation
    getOrders();
  }

  getProperties() {
    getPropertiesResult();
  }

  getPropertiesResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userMobileNumber = prefs.getString('mobileNumber');
    String? userInfoString = prefs.getString('userInfo');
    Map? userInfo = userInfoString != null ? jsonDecode(userInfoString) : null;
    IndividualsResponse? individualsResponse = await loginRepository.getIndividual({
      "Individual": {
        "mobileNumber": userMobileNumber != null && userMobileNumber.toString().trim().isNotEmpty ? [ userMobileNumber.toString().trim() ] : null
      }
    }, userInfo);
    // Store user details
    if(individualsResponse != null ){

      final loggedInIndividual = individualsResponse.individuals;

      HouseholdMembersResponse? householdMembers = await householdMemberRepository.getHouseholdMember({
        "HouseholdMember" : {
          "individualId": loggedInIndividual?.map((i) => i.id).toList()
        }
      });
    HouseholdsResponse? result = await _getPropertiesRepository.getProperties((householdMembers?.householdMembers ?? []).isNotEmpty ? householdMembers!.householdMembers!.map((h) => h.householdClientReferenceId! ).toList() : []);
    if ((result?.households ?? []).isNotEmpty) {
      getPropertiesDetails = await enrichHouseholdsWithImageUrls(result?.households ?? [], ApiConstants.tenantId);
      isPropertyLoading.value = false;
      update();
     }
    }
  }

  // Future<List<FileStoreModel>?> fetchFiles(List<String> storeIds, String tenantId) async {
  //   List<FileStoreModel>? fileStoreIds;
  //   FileStoreListModel? fileStoreListModel;
  //
  //   final uri = Uri.parse(
  //     '${ApiConstants.host}${ApiConstants.fileFetch}?tenantId=$tenantId&fileStoreIds=${storeIds.join(",")}',
  //   );
  //
  //   final res = await http.get(uri);
  //
  //   if (res.statusCode == 200) {
  //     fileStoreListModel = FileStoreListModel.fromJson(
  //       json.decode(res.body) as Map<String, dynamic>,
  //     );
  //   }
  //
  //   return fileStoreListModel?.fileStoreIds;
  // }

  Future<List<FileStoreModel>?> fetchFiles(List<String> storeIds, String tenantId) async {
    List<FileStoreModel>? fileStoreIds;
    FileStoreListModel? fileStoreListModel;

    final uri = Uri.parse(
      '${ApiConstants.host}${ApiConstants.fileFetch}?tenantId=$tenantId&fileStoreIds=${storeIds.join(",")}',
    );

    final headers = {
      'accept': 'application/json, text/plain, */*',
      // 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36',
      // Add referer if your backend requires it
      // 'referer': 'https://qa.digit.org/digit-ui/employee/dss/dashboard/fsm',
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

  Future<List<Household>> enrichHouseholdsWithImageUrls(
      List<Household> households, String tenantId) async {
    // Step 1: Build map of fileStoreId → Household
    final Map<String, Household> fileStoreIdToHousehold = {};

    for (var hh in households) {
      final imageFields = hh.additionalFields
          ?.fields?.where((f) => f.key?.toLowerCase().contains('image') ?? false) ?? [];

      for (var field in imageFields) {
        final fileStoreId = field.value;
        if (fileStoreId != null && fileStoreId.trim().isNotEmpty) {
          fileStoreIdToHousehold[fileStoreId] = hh;
        }
      }
    }

    final allFileStoreIds = fileStoreIdToHousehold.keys.toSet().toList();
    if (allFileStoreIds.isEmpty) return households;

    // Step 2: Fetch file metadata
    final List<FileStoreModel>? fileStoreModels = await fetchFiles(allFileStoreIds, tenantId);
    if (fileStoreModels == null) return households;

    // Step 3: Map each URL to the correct household
    for (var file in fileStoreModels) {
      final hh = fileStoreIdToHousehold[file.id];
      if (hh != null) {
        hh.imageUrls ??= [];
        if (file.url != null && file.url!.isNotEmpty) {
          hh.imageUrls!.add(file.url!.split(',').first);
        }
      }
    }

    return households;
  }


  getOrders() {
    getOrdersResult();
  }

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


  getOrdersResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final mobileNumber = prefs.getString('mobileNumber') ;
    String? userInfoString = prefs.getString('userInfo');
    String? userUuid = prefs.getString('userUuid');
    UserRequest? userRequest = (userInfoString ?? "").isNotEmpty ? UserRequest.fromJson(jsonDecode(userInfoString!)) : null;

    PgrServiceResponse? result = await _getOrdersRepository.getOrders(
        AppUtils().checkIsHousehold(userRequest?.roles ?? []) && !AppUtils().checkIsPGRAdmin(userRequest?.roles ?? []) ? {
      'mobileNumber' : mobileNumber,
    } : {
          "fromDate": AppUtils.getDayStartAndEnd().startMillis.toString(),
          "toDate": AppUtils.getDayStartAndEnd().endMillis.toString(),
        });
    if ((result?.serviceWrappers ?? []).isNotEmpty) {

      getOrderDetails.clear();
      // Filter orders to only show PLOTROL app records
      final plotrolOrders = result?.serviceWrappers
          ?.where((s) => s.service?.additionalDetail?['appSource'] == 'PLOTROL')
          .toList() ?? [];

      getOrderDetails = AppUtils().checkIsGig(userRequest?.roles ?? [])
          ? await enrichOrdersWithImageUrls(
              plotrolOrders
                  .where((s) => (s.workflow?.assignes ?? []).contains(userRequest?.uuid) ||
                      s.service?.applicationStatus == "RESOLVED")
                  .toList(),
              ApiConstants.tenantId)
          : await enrichOrdersWithImageUrls(plotrolOrders, ApiConstants.tenantId);
      pendingOrders.clear();
      todayOrders.clear();
      otherOrders.clear();
      acceptedOrders.clear();
      createdOrders.clear();
      activeOrders.clear();
      completedOrders.clear();
      DateTime now = DateTime.now();
      String today =
          DateFormat('dd/MM/yyyy').format(now); // Format to match assignDate
      // Start of the day: 12:00 AM
      DateTime startDateTime = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
      int startDate = startDateTime.millisecondsSinceEpoch;
      print("StartDate: ${startDate}");
      // End of the day: 11:59:59.999 PM
      DateTime endDateTime = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      int endDate = endDateTime.millisecondsSinceEpoch;
      print("EndDate: ${endDate}");

      for (var order in getOrderDetails) {
        if (order.workflow?.action == 'CREATE') {
          createdOrders.add(order);
        }
        String? assignDate;
        try {
          assignDate = AppUtils.timeStampToDate(order.service?.auditDetails?.createdTime);
        } catch (e) {
          continue;
        }

        if ((order.service?.auditDetails?.createdTime ?? 0) >= startDate && (order.service?.auditDetails?.createdTime ?? 0) <=  endDate ) {
          todayOrders.add(order);
        } else {
          otherOrders.add(order);
        }
        if (order.workflow?.action == 'ASSIGN') {
          createdOrders.add(order);
          acceptedOrders.add(order);
        }
        // else if (order.orderstatus == 'active') {
        //   activeOrders.add(order);
        // }
        else if (order.workflow?.action == 'RESOLVE') {
          completedOrders.add(order);
        }

        // else if (order.orderstatus == 'pending') {
        //   pendingOrders.add(order);
        // }
      }
      logger.i('Todays Order : ${todayOrders}');
      logger.i('Other Orders : ${otherOrders}');
      logger.i('accepted friends : ${acceptedOrders}');
      logger.i('active Orders : ${activeOrders}');
      logger.i('completed orders : ${completedOrders}');
      logger.i('The whole response : ${getOrderDetails}');
      logger.i('The Created Orders : ${createdOrders}');
    }
    isOrderLoading.value = false;
    update();
  }

  getAssigneeDetails() async {

  }

  getTenantApiFunction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    ApiConstants.tenantId = prefs.getString('tenantId') ?? 'mz';
    logger.i('UsersStaffIdForOrders : ${ApiConstants.tenantId}');
    ApiConstants.getTenant = ApiConstants.getTenantLive;
    getTenant();
  }

  getTenant() async {
    await getTenantDetailResult();
  }

  getTenantDetailResult() async {
    UserSearchResponse? result = await _getTenantRepository.getTenant();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if ((result?.user ?? []).isNotEmpty) {
      tenantFirstName.value = result?.user?.first.name?.split(' ').first ?? '';
      tenantLastName.value = (result?.user?.first.name?.split(' ').length ?? 0) > 1 ? (result?.user?.first.name?.split(' ').last ?? '') : '';
      tenantEmail.value = result?.user?.first.emailId ?? '';
      tenantContactNumber.value = result?.user?.first.mobileNumber ?? '';
      // tenantSuburb.value = result?.details?.suburb ?? '';
      tenantCity.value = result?.user?.first.permanentCity ?? '';
      // tenantState.value = result?.details?.state ?? '';
      tenantPinCode.value = result?.user?.first.permanentPinCode ?? '';
      // tenantLocation.value = result?.details?.address ?? '';
      tenantProfileImage.value = result?.user?.first.photo ?? ImageAssetsConst.sampleUserProfile;
      isTenantDetailLoading.value = false;
      update();
    }
  }
}
