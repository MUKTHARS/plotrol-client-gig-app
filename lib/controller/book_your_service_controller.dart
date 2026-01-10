import 'dart:convert';

import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:plotrol/controller/add_your_properties_controller.dart';
import 'package:plotrol/data/repository/categories/get_categories_repository.dart';
import 'package:plotrol/helper/api_constants.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/model/request/book_service/book_service.dart';
import 'package:plotrol/model/response/adding_properties/get_properties_response.dart';
import 'package:plotrol/model/response/autentication_response/autentication_response.dart';
import 'package:plotrol/model/response/book_service/book_service.dart';
import 'package:plotrol/model/response/book_service/pgr_create_response.dart';
import 'package:plotrol/view/main_screen.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/Logger.dart';
import '../data/repository/book_your_service/book_your_service_repository.dart';
import '../globalWidgets/flutter_toast.dart';
import '../helper/utils.dart';
import '../model/response/categories/get_categories.dart';
import '../model/response/common_models.dart';
import '../widgets/success_screen.dart';
import 'autentication_controller.dart';
import 'home_screen_controller.dart';


class BookYourServiceController extends GetxController {


  final EasyInfiniteDateTimelineController dateTimelineController = EasyInfiniteDateTimelineController();

  final GetCategoriesRepository _getCategoriesRepository = GetCategoriesRepository();

  final RoundedLoadingButtonController btnController = RoundedLoadingButtonController();

  var dateTime = DateTime.now().obs;

  var selectedToTime = TimeOfDay.now().obs;

  var selectedFromTime = TimeOfDay.now().obs;

  RxList<bool> isSelected = RxList<bool>([false, false, false, false, false].obs); // Initial selection states

  final AuthenticationController _authenticationController = Get.put(AuthenticationController());

   final HomeScreenController _homeScreenController = Get.put(HomeScreenController());

  final AddYourPropertiesController _addYourPropertiesController = Get.put(AddYourPropertiesController());

  BookServiceRepository addPropertiesRepository = BookServiceRepository();

  RxBool isCategoryLoading = true.obs;

  RxInt locationId = 0.obs;

  List<String> selectedCategoryNames = [];

  List<Map<String, String>> checkBoxOptions = [];
  List<String> selectedCheckBoxItems = [];

  List<String> selectedCategoryId = [];

  List<CategoryDetails> listOfCategories = [];

  void toggleSelection(int index) {
    // Clear previous selections
    for (int i = 0; i < isSelected.length; i++) {
      isSelected[i] = false;
    }

    // Clear old selections
    selectedCategoryNames.clear();
    selectedCategoryId.clear();

    // Set current selection
    isSelected[index] = true;
    selectedCategoryNames.add(listOfCategories[index].categoryname ?? '');
    selectedCategoryId.add(listOfCategories[index].categoryid.toString());

    print('SelectedCategoryName : $selectedCategoryNames');
    update();  // Update UI when selection changes/ Update UI when selection changes
  }

  void resetCategoryList() {
    selectedCategoryNames.clear();
    selectedCategoryId.clear();
  }

  void showMap(BuildContext context, double? latitude, double? longitude,) {
    _addYourPropertiesController.showMap(context, false, latitude, longitude);
  }
  void initializeSelection(String selectedCategory, String categoryId, {bool isUncheck = false}) {
    int index = listOfCategories.indexWhere((detail) => detail.categoryname == selectedCategory);
    if (index != -1) {
      isSelected[index] = true;
    }
  }

  void resetSelection() {
    isSelected.value = List<bool>.filled(listOfCategories.length, false); // Uncheck all categories
    update();
  }

  void updateDateTime(DateTime newDateTime) {
    dateTime.value = newDateTime;
    update();
  }

  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();  // "jm" for "5:08 PM"
    return format.format(dt);
  }

  bookYourServiceValidation(int locationID, Household household) {
    if(selectedCategoryNames.isEmpty) {
      Toast.showToast('Please Select Your Service');
      btnController.reset();
    }
    else {
      ApiConstants.bookService = ApiConstants.bookServicesLive;
      locationId.value = locationID;
      bookServiceProperty(household);
      resetSelection();
      btnController.reset();
      _homeScreenController.getOrdersApiFunction();
    }
  }

  bookYourServiceApiFunction(locationId) {
  }

  void updateSelectedTime(TimeOfDay time) {
    selectedToTime.value = time;
    update();
  }

  getCategories() {
    ApiConstants.getCategories = ApiConstants.getCategoriesLive;
    getCategoriesResult();
  }
  getCheckList() {
    checkBoxOptions = [
      {'key': 'fences_intact', 'name': 'Fences/Boundaries intact'},
      {'key': 'free_from_encroachment', 'name': 'Free from enroachment'},
      {'key': 'no_vehicles_parked', 'name': 'No vehicles parked'},
      {'key': 'garbage_dumped', 'name': 'Garbage or waste dumped'},
      {'key': 'overgrown_brushes', 'name': 'Are brushes/weeds overgrown inside or along the edges'},
    ];
    update();
  }

  getCategoriesResult() async {
    CategoriesResponse? result = CategoriesResponse.fromJson({
      "code": 200,
      "status": true,
      "message": "Categories fetched successfully",
      "details": [
        {
          "categoryid": 1,
          "servicegroup": 101,
          "categorytype": 1,
          "categoryname": "One Time Evaluation",
          "icon": "https://example.com/icons/healthcare.png",
          "serviceimage": ImageAssetsConst.oneTimeEvaluationIcon,
          "status": 1
        },
        // {
        //   "categoryid": 2,
        //   "servicegroup": 102,
        //   "categorytype": 2,
        //   "categoryname": " Grass Cleaning",
        //   "icon": "https://example.com/icons/education.png",
        //   "serviceimage": ImageAssetsConst.grassCleaning,
        //   "status": 1
        // }
      ]
    }
    ) ;
    if(result.status == true) {
      listOfCategories = result.details ?? [];
      isCategoryLoading.value = false;
      update();
      logger.i('valueof the loader : ${isCategoryLoading.value}');
      isSelected.value = List<bool>.filled(listOfCategories.length, false);

    }
  }

  bookServiceProperty(Household household) {
    bookServiceResult(household,);
  }

  bookServiceResult(Household household) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userUuid = prefs.getString('userUuid');
    String? tenantId = prefs.getString('tenantId');
    String? name = prefs.getString('name');
    String? mobileNumber = prefs.getString('mobileNumber');
    String? boundaryCode = prefs.getString('defaultBoundaryCode');
    String? userInfoString =  prefs.getString('userInfo');
    UserRequest? user = UserRequest.fromJson(jsonDecode(userInfoString.toString()));
    AuditDetails auditDetails = AuditDetails(
      createdBy: userUuid,
      createdTime: AppUtils().millisecondsSinceEpoch(),
      lastModifiedBy: userUuid,
      lastModifiedTime: AppUtils().millisecondsSinceEpoch(),
    );
    final fields = household.additionalFields?.fields ?? [];

// contact number (safe)
    String? _getField(String k) {
      final hits = fields.where((f) => f.key == k);
      return hits.isNotEmpty ? hits.first.value?.toString() : null;
    }

// collect image_* fields with numeric suffix and sort by index
    final imageEntries = fields
        .where((f) => ((f.key ?? '').startsWith('image_')) && (f.value != null))
        .toList()
      ..sort((a, b) {
        int ai = int.tryParse((a.key ?? '').split('_').last) ?? 0;
        int bi = int.tryParse((b.key ?? '').split('_').last) ?? 0;
        return ai.compareTo(bi);
      });

// build the household detail map with id, contactNo and all image_* pairs
    final Map<String, dynamic> householdDetail = {
      "id": household.id,
      if (_getField('contactNo') != null) "contactNo": _getField('contactNo'),
    };

// add image_1...image_n -> fileStoreId
    for (final f in imageEntries) {
      if ((f.key ?? '').isNotEmpty && (f.value?.toString().isNotEmpty ?? false)) {
        householdDetail[f.key!] = f.value.toString();
      }
    }
    PgrServiceResponse? result = await addPropertiesRepository.bookService(
        ServiceWrapper(
          service: Service(
            active: true,
            rowVersion: 1,
            auditDetails: auditDetails,
            description: selectedCategoryNames.first,
            applicationStatus: "CREATED",
            serviceCode: "PerformanceIssue",
            source: "web",
            tenantId: tenantId,
            user: user,
            additionalDetail: {
              "household": householdDetail,
              "appSource": "PLOTROL"
            },
            address: Address(
              tenantId: household.address?.tenantId,
              doorNo: household.address?.doorNo,
              street: household.address?.buildingName != null ? household.address?.addressLine1 : household.address?.addressLine2,
              buildingName: household.address?.buildingName ?? household.address?.addressLine1,
              addressLine1: household.address?.addressLine1,
              addressLine2: household.address?.addressLine2,
              auditDetails: auditDetails,
              city: household.address?.city,
              longitude: household.address?.longitude,
              latitude: household.address?.latitude,
              landmark: household.address?.landmark,
              locationAccuracy: household.address?.locationAccuracy,
              pincode: household.address?.pincode,
              type: household.address?.type,
              locality: Locality(
                code: "MICROPLAN_MO",
              ),
              geoLocation: GeoLocation(
                latitude: household.address?.latitude,
                longitude: household.address?.longitude,
              ),
            ),
          ),
          workflow: Workflow(
            action: "CREATE",
            assignes: [],
            comments: household.id,
            hrmsAssignes: [],
          ),
        ));
    if((result?.serviceWrappers ?? []).isNotEmpty) {
      resetCategoryList();
      Get.offAll(() => SuccessScreen(
        onGoHome: () => Get.offAll(() => HomeView(selectedIndex: 1)),
      ));
      // Toast.showToast("Thank you for requesting our service. A local Plotrol representative will contact you soon. We appreciate your support in shaping thr future of secure land monitoring.");
      // Get.offAll(() => HomeView(selectedIndex: 1));
    }
    else {
      Toast.showToast('There is some issue in placing Your order Please try again later');
    }
  }
}