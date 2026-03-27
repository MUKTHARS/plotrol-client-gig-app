import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'dart:math' as math;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plotrol/data/repository/assignees/get_assignees_repo.dart';
import 'package:plotrol/model/response/book_service/pgr_create_response.dart';
import 'package:plotrol/model/response/employee_response/employee_search_response.dart';
import 'package:plotrol/view/gig_views/gig_home_view.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio;
import '../data/repository/book_your_service/book_your_service_repository.dart';
import '../globalWidgets/flutter_toast.dart';
import '../helper/api_constants.dart';
import '../helper/utils.dart';
import '../model/response/autentication_response/autentication_response.dart';
import '../model/response/book_service/file_store_model.dart';
import '../model/response/common_models.dart';
import '../view/main_screen.dart';

class OrderDetailsController extends GetxController {
  final RoundedLoadingButtonController btnController =
      RoundedLoadingButtonController();

  GetAssigneesRepository assigneesRepository = GetAssigneesRepository();
  BookServiceRepository updatePropertiesRepository = BookServiceRepository();

  RxInt currentIndex = 0.obs;
  RxBool isAssigneesLoading = true.obs;
  RxList<String> uploadedImageList = <String>[].obs;
  RxBool unableToLocate = false.obs;                         // <— add
  RxString  remarksCtrl = ''.obs;
  final RxMap<String, String> imagePathToFileStoreId = <String, String>{}.obs;

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  var items = <Map<String, dynamic>>[].obs;
  List<Employee>? assignees;
  Employee? selectedAssignee;
  bool isDistributor = false;
  bool isHelpDeskUser = false;
  bool isPGRAdmin = false;
  Employee? assignedStaff;
  List<Map<String, String>> checkBoxOptions = [];
  List<String> selectedCheckBoxItems = [];
  List<XFile>? images = [];

  final _picker = ImagePicker();

  static const int _maxImages = 5;

  bool _canAddMorePhotos() {
    final current = images?.length ?? 0;
    if (current >= _maxImages) {
      Toast.showToast('You can upload up to $_maxImages images');
      return false;
    }
    return true;
  }

  int _remainingSlots() => (_maxImages - (images?.length ?? 0)).clamp(0, _maxImages);


// ===== ANDROID 13+ Photos permission (with legacy fallback) =====
  Future<bool> _ensurePhotosPermission() async {
    // On Android 13/14 this maps to READ_MEDIA_IMAGES and shows:
    // "Allow all photos / Select photos / Don't allow"
    final status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      final req = await Permission.photos.request();
      if (req.isGranted || req.isLimited) return true;

      if (req.isPermanentlyDenied) {
        Toast.showToast('Allow Photos access in Settings to continue');
        await openAppSettings();
      } else {
        Toast.showToast('Photos permission denied');
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      Toast.showToast('Allow Photos access in Settings to continue');
      await openAppSettings();
      return false;
    }

    // If you also support API 32 and below, you can optionally fall back:
    // final legacy = await Permission.storage.request();
    // if (legacy.isGranted) return true;

    return false;
  }

// ===== ANDROID Camera permission =====
  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final req = await Permission.camera.request();
      if (req.isGranted) return true;

      if (req.isPermanentlyDenied) {
        Toast.showToast('Enable Camera permission in Settings');
        await openAppSettings();
      } else {
        Toast.showToast('Camera permission denied');
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      Toast.showToast('Enable Camera permission in Settings');
      await openAppSettings();
      return false;
    }

    return false;
  }

// ===== Pick multiple PHOTOS (system Photos permission) =====
  Future<void> getImageList() async {
    if (!await _ensurePhotosPermission()) return;

    if (!_canAddMorePhotos()) return;

    final remaining = _remainingSlots();
    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    // Defensive: in case platform returns > remaining
    final toAdd = picked.take(remaining).toList();
    if (toAdd.length < picked.length) {
      Toast.showToast('Only $_maxImages photos allowed. Extra images were ignored.');
    }

    await _handlePickedFiles(toAdd);
  }


// ===== Pick single photo from CAMERA =====
  Future<void> getImageFromCamera() async {
    if (!await _ensureCameraPermission()) return;
    if (!_canAddMorePhotos()) return;

    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (shot == null) return;

    await _handlePickedFiles([shot]);
  }


// ===== Common uploader (keep your existing one if you already have it) =====

  Future<void> _handlePickedFiles(List<XFile> picked) async {
    images ??= [];
    images!.addAll(picked); // optimistic UI

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final ids = await uploadPickedImages(picked, 'pgr', accessToken!);

    if (ids.isNotEmpty) {
      // Map each picked file to the returned id (best-effort if partial)
      final int n = math.min(ids.length, picked.length);
      for (var i = 0; i < n; i++) {
        final id = ids[i].fileStoreId?.toString();
        if (id != null) {
          imagePathToFileStoreId[picked[i].path] = id;
        }
      }
      // Keep your existing list of ids (use only those we actually mapped)
      uploadedImageList.addAll(
        ids.take(n).map((f) => f.fileStoreId.toString()),
      );

      // If some picks failed (partial success), roll back the failed ones
      if (n < picked.length) {
        final failed = picked.sublist(n);
        images!.removeWhere((x) => failed.any((f) => f.path == x.path));
        Toast.showToast('Some images failed to upload');
      }

      update();
    } else {
      // All failed -> rollback optimistic add
      images!.removeWhere((x) => picked.any((p) => p.path == x.path));
      Toast.showToast('Unable to upload file. Please try a different image');
      update();
    }
  }



  Future<List<FileStoreModel>> uploadPickedImages(
      List<XFile> xFiles,
      String moduleName,
      String authToken,
      ) async {
    final dioClient = dio.Dio();

    final List<dio.MultipartFile> fileList = [];
    for (final file in xFiles) {
      final fileExists = await File(file.path).exists();
      print("File: ${file.path}, exists? $fileExists");
      if (!fileExists) {
        print("Skipping missing file: ${file.path}");
        continue;
      }

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      final multipartFile = await dio.MultipartFile.fromFile(
        file.path,
        filename: file.name.replaceAll(' ', '_'),
        contentType: MediaType(parts[0], parts[1]),
      );
      fileList.add(multipartFile);
    }

    if (fileList.isEmpty) {
      print("No valid files to upload!");
      return [];
    }

    final formData = dio.FormData.fromMap({
      'file': fileList,
      'tenantId': ApiConstants.tenantId,
      'module': moduleName,
    });

    print("FormData fields: ${formData.fields}");
    print("FormData files: ${formData.files.map((entry) => entry.value.filename).toList()}");

    try {
      final response = await dioClient.post(
        "${ApiConstants.host}${ApiConstants.fileUpload}",
        data: formData,
        options: dio.Options(
          headers: {
            'auth-token': authToken,
            // no manual content-type here
          },
        ),
      );

      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 201 && response.data['files'] != null) {
        return (response.data['files'] as List)
            .map<FileStoreModel>((e) => FileStoreModel.fromJson(e))
            .toList();
      }
    } catch (e, st) {
      images?.clear();
      Toast.showToast('Unable to upload file. Please try a different image');
      print("Upload error: $e\n$st");
    }

    return [];
  }

  void setItems(List<String> itemList) {
    items.value =
        itemList.map((item) => {"name": item, "isChecked": false}).toList();
  }

  void toggleCheck(int index) {
    items[index]['isChecked'] = !items[index]['isChecked'];
    items.refresh();
  }
  XFile? fileAtIndex(List<XFile>? images, int val) {
    if (images == null || val < 0 || val >= images.length) {
      Toast.showToast('Please try re-uploading images');
      return null;
    }
    else {
      return images[val];
    }
  }

  void removeImageList(int index) {
    final list = images;
    if (list == null || index < 0 || index >= list.length) {
      Toast.showToast('Please try re-uploading images');
      return;
    }

    // Get the file we're removing
    final XFile removedFile = list.removeAt(index);

    // Remove matching fileStoreId if we have it
    final String? id = imagePathToFileStoreId.remove(removedFile.path);
    if (id != null) {
      uploadedImageList.remove(id);
    } else if (index < uploadedImageList.length) {
      // Fallback: keep lists aligned by index
      uploadedImageList.removeAt(index);
    }

    update();
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

  selectAssignee(Employee? selectedEmployee) {
    selectedAssignee = selectedEmployee;
  }

  getAssignees(ServiceWrapper? order) {
    checkForRole();
    getFilteredAssignees(order);
    getStaffAssigned(order);
  }

  getStaffAssigned(ServiceWrapper? order) async {
    if ((order?.workflow?.assignes ?? []).isNotEmpty) {
      isAssigneesLoading.value = true;
      EmployeeResponse? assignee = await assigneesRepository.getAssignees({
        "uuid": order?.workflow?.assignes?.first,
      });
      assignedStaff = (assignee?.employees ?? []).isNotEmpty ? assignee!.employees.first : null;
      isAssigneesLoading.value = false;
      update();
    }
  }

  checkForRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoString = prefs.getString('userInfo');
    UserRequest? user =
        UserRequest.fromJson(jsonDecode(userInfoString.toString()));
    isDistributor = AppUtils().checkIsHousehold(user.roles ?? []);
    isHelpDeskUser = AppUtils().checkIsGig(user.roles ?? []);
    isPGRAdmin = AppUtils().checkIsPGRAdmin(user.roles ?? []);
    update();
  }

  getFilteredAssignees(ServiceWrapper? order) async {
    isAssigneesLoading.value = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoString = prefs.getString('userInfo');
    String? userUuid = prefs.getString('userUuid');
    UserRequest? userRequest = (userInfoString ?? "").isNotEmpty
        ? UserRequest.fromJson(jsonDecode(userInfoString!))
        : null;
    bool isHelpDeskUser = AppUtils().checkIsGig(userRequest?.roles ?? []);
    bool isDistributor = AppUtils().checkIsHousehold(userRequest?.roles ?? []);
    EmployeeResponse? employeeResponse =
        await assigneesRepository.getAssignees({"roles": "HELPDESK_USER"});

    List<Employee>? filteredEmployees =
        employeeResponse?.employees.where((employee) {
      return employee.user?.uuid != null && (employee.isActive ?? true);
    }).toList();

    if (filteredEmployees != null && filteredEmployees.isNotEmpty) {
      assignees = filteredEmployees;
    }

    isAssigneesLoading.value = false;
    update();
  }

  updateBooking(ServiceWrapper order) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userUuid = prefs.getString('userUuid');
    String? tenantId = prefs.getString('tenantId');

    String? userInfoString = prefs.getString('userInfo');
    UserRequest? user =
        UserRequest.fromJson(jsonDecode(userInfoString.toString()));
    if ((isPGRAdmin &&
            selectedAssignee != null &&
            order.service?.applicationStatus != "RESOLVED") ||
        (isHelpDeskUser && order.service?.applicationStatus != "RESOLVED")) {
      final isUTL = unableToLocate.value;

      // If NOT unable to locate, require checklist and images as before
      if ((isHelpDeskUser && !isUTL) && (selectedCheckBoxItems.isEmpty || uploadedImageList.isEmpty)) {
        Toast.showToast(selectedCheckBoxItems.isEmpty
            ? 'Please verify checklist items'
            : 'Please upload images for verification');
        btnController.reset();
        return;
      } else {
        try {

          final Map<String, dynamic> additionalDetailMap =
          order.service!.additionalDetail != null
              ? Map<String, dynamic>.from(order.service!.additionalDetail!)
              : {};
          final bool isUTL = unableToLocate.value;
        AuditDetails auditDetails = AuditDetails(
          createdBy: order.service?.auditDetails?.createdBy,
          createdTime: order.service?.auditDetails?.createdTime,
          lastModifiedBy: userUuid,
          lastModifiedTime: AppUtils().millisecondsSinceEpoch(),
        );
        Service? service = order.service != null
            ? Service.fromJson(order.service!.toJson())
            : null;

        Workflow? workflow = order.workflow != null
            ? Workflow.fromJson(order.workflow!.toJson())
            : null;
        service?.applicationStatus = order.service?.applicationStatus;
        service?.auditDetails = auditDetails;
        final bool isGig = AppUtils().checkIsGig(user.roles ?? []);
        workflow?.action = isGig ? "RESOLVE" : "ASSIGN";
        workflow?.assignes = isGig
            ? null
            : selectedAssignee?.user?.userServiceUuid != null
                ? [selectedAssignee?.user?.userServiceUuid]
                : [];
        service?.additionalDetail = isGig
            ? {
                ...additionalDetailMap,
                if (uploadedImageList.isNotEmpty)
                  "checklist": selectedCheckBoxItems.join("|").toString(),
                "unableToLocateProperty": isUTL,
                "remarks": remarksCtrl.value ?? '',
                "appSource": "PLOTROL",
                if (uploadedImageList.isNotEmpty)
                  ...Map.fromEntries(
                    uploadedImageList.asMap().entries.map(
                          (entry) => MapEntry(
                        'report_${entry.key + 1}',
                        entry.value,
                      ),
                    ),
                  ),
              }
            : order.service?.additionalDetail;
        workflow?.hrmsAssignes = isGig ? null : [selectedAssignee?.user?.uuid];
        PgrServiceResponse? result =
        await updatePropertiesRepository.updateBooking(ServiceWrapper(
          service: service,
          workflow: workflow,
        ));
        if ((result?.serviceWrappers ?? []).isNotEmpty) {
          Toast.showToast(isPGRAdmin ? 'Booking has been assigned successfully' : "Task completed successfully");
          Get.offAll(() => GigHomeView(selectedIndex: 0));
        } else {
          btnController.reset();
          Toast.showToast(
              'There is some issue in assigning the booking, Please Try Again Later');
        }
      }
      catch (e) {
          btnController.reset();
        Toast.showToast(
            'There is some issue in assigning the booking, Please Try Again Later');
      }
      }
    } else {
      if ((isPGRAdmin &&
          selectedAssignee == null &&
          order.service?.applicationStatus == "PENDING_ASSIGNMENT")) {
        btnController.reset();
        Toast.showToast('Please select whom you want to assign');
      } else {
        Get.offAll(() => isDistributor
            ? HomeView(selectedIndex: 0)
            : GigHomeView(selectedIndex: 0));
      }
    }
  }

  // New observable for selected item
  RxnString? selectedCity = RxnString();
}
