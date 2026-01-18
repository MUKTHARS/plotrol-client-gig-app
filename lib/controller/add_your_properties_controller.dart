import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/data/repository/add_household_member/add_household_member_repository.dart';
import 'package:plotrol/data/repository/add_individual/add_individual_repository.dart';
import 'package:plotrol/data/repository/adding_properties/adding_properties_repository.dart';
import 'package:plotrol/data/repository/get_properties/get_properties_repository.dart';
import 'package:plotrol/globalWidgets/flutter_toast.dart';
import 'package:plotrol/helper/api_constants.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/model/response/adding_properties/adding_properties_response.dart';
import 'package:plotrol/model/response/adding_properties/get_properties_response.dart';
import 'package:plotrol/model/response/common_models.dart';
import 'package:plotrol/model/response/household_member/household_member_create_response.dart';
import 'package:plotrol/model/response/household_member/household_member_response.dart';
import 'package:plotrol/model/response/individual/individual_response.dart';
import 'package:plotrol/model/response/individual/inidividual_create_response.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helper/Logger.dart';
import '../globalWidgets/Googleplaces.dart';
import '../model/response/book_service/file_store_model.dart';
import '../view/main_screen.dart';
import '../widgets/location_map.dart';
import 'home_screen_controller.dart';

class AddYourPropertiesController extends GetxController {
  final RoundedLoadingButtonController btnController =
      RoundedLoadingButtonController();

  TextEditingController mobileNumberController = TextEditingController();

  TextEditingController notesController = TextEditingController();

  TextEditingController locationName = TextEditingController();

  TextEditingController suburbController = TextEditingController();

  TextEditingController cityController = TextEditingController();

  TextEditingController stateController = TextEditingController();

  TextEditingController postCodeController = TextEditingController();

  TextEditingController addressController = TextEditingController();

  final AuthenticationController _authenticationController =
      Get.put(AuthenticationController());

  // final CreateAccountController _createAccountController = Get.put(CreateAccountController());
  //
  final HomeScreenController _homeScreenController =
      Get.put(HomeScreenController());

  //
  // final BottomNavigationController _bottomNavigationController = Get.put(BottomNavigationController());

  AddPropertiesRepository addPropertiesRepository = AddPropertiesRepository();
  AddIndividualRepository addIndividualRepository = AddIndividualRepository();
  AddHouseholdMemberRepository addHouseholdMemberRepository =
      AddHouseholdMemberRepository();

  RxInt tenantId = 0.obs;

  RxList<String> uploadedImageList = <String>[].obs;

  final searchText = ''.obs;
  final predictions = <Map<String, dynamic>>[].obs;
  final selectedPlace = {}.obs;

  RxString userCurrentLocation = ''.obs;

  RxString latitude = ''.obs;

  RxString longitude = ''.obs;

  RxString currentLat = ''.obs;

  RxString currentLong = ''.obs;

  final GetPropertiesRepository _getPropertiesRepository =
      GetPropertiesRepository();

  final isDropdownOpened = false.obs;

  void toggleDropdown() {
    isDropdownOpened.value = !isDropdownOpened.value;
    update();
  }

  final GooglePlacesService placesService = GooglePlacesService();

  @override
  void onInit() {
    getLocation();
    // TODO: implement onInit
    super.onInit();
  }

  List<XFile>? images = [];

  final _picker = ImagePicker();
  // Add near the top of the controller
  static const int kMaxPhotos = 5;

  bool _canAddMorePhotos() {
    final current = images?.length ?? 0;
    if (current >= kMaxPhotos) {
      Toast.showToast('You already uploaded $kMaxPhotos photos');
      return false;
    }
    return true;
  }

  int _remainingSlots() => max(0, kMaxPhotos - (images?.length ?? 0));

  Future<bool> _ensureGalleryPerms() async {
    // Check current status first
    final status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) {
      // granted = full library; limited = user selected specific photos
      return true;
    }

    if (status.isDenied) {
      // This triggers the inbuilt Android popup ("Allow all / Select photos / Don't allow")
      final req = await Permission.photos.request();
      if (req.isGranted || req.isLimited) return true;

      if (req.isPermanentlyDenied) {
        // Only now suggest Settings
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

    return false;
  }

  Future<bool> _ensureCameraPerms() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> getImageFromGallery() async {
    // if (!await _ensureGalleryPerms()) {
    //   Toast.showToast('Please allow Photos permission in Settings');
    //   openAppSettings();
    //   return;
    // }

    if (!_canAddMorePhotos()) return;

    final allowed = _remainingSlots();
    // Respect remaining slots so we never exceed 5
    final picked = await _picker.pickMultiImage(limit: allowed);
    if (picked.isEmpty) return;

    // This is already capped by `limit`, but keep defensive code:
    final toAdd = picked.take(allowed).toList();
    if (toAdd.length < picked.length) {
      Toast.showToast('Only $kMaxPhotos photos allowed. Some were ignored.');
    }

    images!.addAll(toAdd);

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final ids = await uploadPickedImages(toAdd, 'pgr', accessToken!);
    if (ids.isNotEmpty) {
      uploadedImageList.addAll(ids.map((f) => f.fileStoreId.toString()));
    } else {
      images?.clear();
      update();
      Toast.showToast('Unable to upload file. Please try again later');
    }
    update();
  }

  Future<void> getImageFromCamera() async {
    if (!await _ensureCameraPerms()) {
      Toast.showToast('Please allow Camera permission in Settings');
      openAppSettings();
      return;
    }

    if (!_canAddMorePhotos()) return;

    final x =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x == null) return;

    images!.add(x);

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final ids = await uploadPickedImages([x], 'pgr', accessToken!);
    if (ids.isNotEmpty) {
      uploadedImageList.addAll(ids.map((f) => f.fileStoreId.toString()));
    } else {
      images?.clear();
      Toast.showToast('Unable to upload file. Please try again later');
      update();
    }
    update();
  }

  Future getImageList() async {
    if (!_canAddMorePhotos()) return;

    final allowed = _remainingSlots();
    // This legacy method was using limit:1 — keep behavior but still respect remaining
    final List<XFile> selectedImages =
        await _picker.pickMultiImage(limit: min(1, allowed), imageQuality: 90);

    if (selectedImages.isEmpty) return;

    images!.addAll(selectedImages);

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final fileStoreIds =
        await uploadPickedImages(selectedImages, 'pgr', accessToken!);
    if (fileStoreIds.isNotEmpty) {
      uploadedImageList
          .addAll(fileStoreIds.map((f) => f.fileStoreId.toString()));
    } else {
      images?.clear();
      update();
      Toast.showToast('Unable to upload file. Please try again later');
    }

    update();
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
    print(
        "FormData files: ${formData.files.map((entry) => entry.value.filename).toList()}");

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
      } else {
        Toast.showToast(response.data['Errors'][0]['message']);
      }
    } catch (e, st) {
      print("Upload error: $e\n$st");
    }

    return [];
  }

  // Future<List<FileStoreModel>> uploadPickedImages(List<XFile> xFiles, String moduleName, String authToken) async {
  //   var postUri = Uri.parse("${ApiConstants.host}${ApiConstants.fileUpload}");
  //
  //   var request = http.MultipartRequest("POST", postUri);
  //
  //   request.headers['auth-token'] = authToken;
  //
  //   for (var file in xFiles) {
  //     final mediaType = getMediaType(file.name);
  //     final multipartFile = await http.MultipartFile.fromPath(
  //       'file',
  //       file.path,
  //       contentType: mediaType,
  //     );
  //
  //     request.files.add(multipartFile);
  //   }
  //
  //   request.fields['tenantId'] = ApiConstants.tenantId;
  //   request.fields['module'] = moduleName;
  //
  //   final response = await request.send();
  //
  //   if (response.statusCode == 201) {
  //     final respStr = json.decode(await response.stream.bytesToString());
  //     return respStr['files']
  //         .map<FileStoreModel>((e) => FileStoreModel.fromJson(e))
  //         .toList();
  //   }
  //
  //   return <FileStoreModel>[];
  // }

  MediaType getMediaType(String? path) {
    if (path == null) return MediaType('', '');
    String? mimeStr = lookupMimeType(path);
    var fileType = mimeStr?.split('/');
    if (fileType != null && fileType.isNotEmpty) {
      return MediaType(fileType.first, fileType.last);
    } else {
      return MediaType('', '');
    }
  }

  void removeImageList(int index) {
    if (index >= 0 && index < (images?.length ?? 0)) {
      images?.removeAt(index);
    }
    if (index >= 0 && index < uploadedImageList.length) {
      uploadedImageList.removeAt(index);
    }
    update();
  }

  // uploadImageAndSave() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   tenantId.value = prefs.getInt('tenantId') ?? 0;
  //
  //   var httpClient = http.Client();
  //   var rng = Random();
  //
  //   dospace.Spaces spaces = dospace.Spaces(
  //     region: "sgp1",
  //     accessKey: "DO002QLRX23UD4C47RH7",
  //     secretKey: "1lPnl90eFhUtd4yegiH3q3QgiMUc6Cd9ybpLCyBf628",
  //     httpClient: httpClient,
  //   );
  //
  //   String bucketName = "nearle";
  //   String folderName = "plotrol";
  //
  //   // Iterate over each image in the list
  //   for (int i = 0; i < images!.length; i++) {
  //     String imagePath = images![i].path;
  //     String dir = path.dirname(imagePath.split('/').last);
  //     String newPath = path.join(
  //       dir,
  //       'profile-${rng.nextInt(100).toString()}-${tenantId.value}-$i.jpg',
  //     );
  //     print('NewPath: $newPath');
  //
  //     String fileName = newPath.split('/').last;
  //     print('filename: $fileName');
  //
  //     String? etag = await spaces.bucket(bucketName).uploadFile(
  //           '$folderName/$fileName',
  //           File(imagePath),
  //           'image',
  //           dospace.Permissions.public,
  //         );
  //     print('upload: $etag');
  //
  //     String fileUrl = "https://images.nearle.app/$folderName/$fileName";
  //     uploadedImageList.add(fileUrl);
  //     update();
  //     print("file================= $uploadedImageList");
  //   }
  //   await spaces.close();
  //   addNewProperty();
  //   // createNewUser();
  // }

  addYourPropertiesValidation() async {
    // if (images?.isEmpty ?? false) {
    //   btnController.reset();
    //   Toast.showToast('Please add your property Images');
    // } else
    // if (mobileNumberController.text.isEmpty) {
    //   btnController.reset();
    //   Toast.showToast('Please Enter the Mobile Number');
    // } else
    if (locationName.text.isEmpty) {
      btnController.reset();
      Toast.showToast('Please Enter the Location Name');
    } else if (locationName.text.length > 25) {
      btnController.reset();
      Toast.showToast('Location name must be 25 characters or less');
    } else if (notesController.text.isEmpty) {
      btnController.reset();
      Toast.showToast('Please add information to locate your property');
    } else {
      // uploadImageAndSave();
      await addYourPropertiesResult();
      btnController.reset();
    }
  }

  addNewProperty() {
    addYourPropertiesResult();
  }

  addYourPropertiesResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userUuid = prefs.getString('userUuid');
    String? tenantId = prefs.getString('tenantId');
    String? name = prefs.getString('name');
    String? mobileNumber = prefs.getString('mobileNumber');
    String? boundaryCode = prefs.getString('defaultBoundaryCode');
    String? individualClientReferenceId = IdGen.i.identifier;
    String? householdClientReferenceId = IdGen.i.identifier;
    String? householdMemberClientReferenceId = IdGen.i.identifier;
    AuditDetails auditDetails = AuditDetails(
      createdBy: userUuid,
      createdTime: AppUtils().millisecondsSinceEpoch(),
      lastModifiedBy: userUuid,
      lastModifiedTime: AppUtils().millisecondsSinceEpoch(),
    );
    IndividualCreateResponse? individualResponse =
        await addIndividualRepository.addIndividual(
      Individual(
        clientReferenceId: individualClientReferenceId,
        tenantId: tenantId,
        name: Name(
          givenName: name,
        ),
        rowVersion: 1,
        address: [
          Address(
            tenantId: tenantId,
            type: "CORRESPONDENCE",
            locality: Locality(code: "MICROPLAN_MO", name: cityController.text),
            addressLine1: (addressController.text ?? '').length > 20
                ? addressController.text.substring(0, 20)
                : addressController.text,
            addressLine2: (addressController.text ?? '').length > 20
                ? addressController.text.substring(20)
                : null,
            landmark: locationName.text,
            city: cityController.text,
            auditDetails: auditDetails,
            pincode: postCodeController.text,
          )
        ],
        auditDetails: auditDetails,
        mobileNumber: mobileNumber,
        identifiers: [
          Identifier(
            clientReferenceId: IdGen.i.identifier,
            identifierType: 'DEFAULT',
            identifierId: IdGen.i.identifier,
          )
        ],
        skills: [],
        photo: null,
        isDeleted: false,
        isSystemUser: false,
      ),
    );
    HouseholdCreateResponse? result =
        await addPropertiesRepository.addProperties(Household(
            clientReferenceId: householdClientReferenceId,
            householdType: "FAMILY",
            memberCount: 1,
            tenantId: tenantId,
            additionalFields: AdditionalFields(
              schema: 'Household',
              version: 1,
              fields: [
                if (notesController.text.trim().isNotEmpty)
                  AdditionalFieldEntry(
                    key: 'notes',
                    value: notesController.text,
                  ),
                if (mobileNumberController.text.trim().isNotEmpty)
                  AdditionalFieldEntry(
                    key: 'contactNo',
                    value: mobileNumberController.text,
                  ),
                if (uploadedImageList.isNotEmpty)
                  AdditionalFieldEntry(
                    key: 'imageIds', // NEW: full list of IDs in one field
                    value: jsonEncode(uploadedImageList),
                  ),
                if (uploadedImageList.isNotEmpty)
                  ...uploadedImageList.asMap().entries.map(
                        (entry) => AdditionalFieldEntry(
                          key: 'image_${entry.key + 1}',
                          value: entry.value,
                        ),
                      ),
              ],
            ),
            rowVersion: 1,
            nonRecoverableError: false,
            auditDetails: auditDetails,
            clientAuditDetails: auditDetails,
            address: Address(
                latitude: currentLat.value.isNotEmpty
                    ? double.parse(currentLat.value.toString())
                    : null,
                longitude: currentLong.value.isNotEmpty
                    ? double.parse(currentLong.value.toString())
                    : null,
                type: "CORRESPONDENCE",
                tenantId: tenantId,
                locality:
                    Locality(code: "MICROPLAN_MO", name: cityController.text),
                buildingName: locationName.text,
                street: AppUtils()
                    .parseAddressFromText(addressController.text ?? '')
                    .street,
                addressLine1: AppUtils()
                    .parseAddressFromText(addressController.text ?? '')
                    .addressLine1,
                addressLine2: AppUtils()
                    .parseAddressFromText(addressController.text ?? '')
                    .addressLine2,
                landmark: notesController.text,
                city: cityController.text,
                pincode: postCodeController.text)));
    if (individualResponse?.individual != null && result?.household != null) {
      HouseholdMemberCreateResponse? householdMemberResponse =
          await addHouseholdMemberRepository.addHouseholdMember(HouseholdMember(
        clientReferenceId: householdMemberClientReferenceId,
        individualClientReferenceId: individualClientReferenceId,
        householdClientReferenceId: householdClientReferenceId,
        isHeadOfHousehold: true,
        rowVersion: 1,
        auditDetails: auditDetails,
        clientAuditDetails: auditDetails,
        tenantId: tenantId,
      ));

      if (householdMemberResponse?.householdMember != null) {
        Get.offAll(() => HomeView(selectedIndex: 0));
        Toast.showToast('Your Properties Added SuccessFully');
        notesController.clear();
        uploadedImageList.clear();
        mobileNumberController.clear();
        locationName.clear();
        uploadedImageList.clear();
        images?.clear();
      } else {
        Toast.showToast(
            'There is some issue in adding your Properties Please Try Again Later');
      }
    } else {
      Toast.showToast(
          'There is some issue in adding your Properties Please Try Again Later');
    }
  }

  getLocation() async {
    /// checking the permission is granted or not
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        currentLat.value = position.latitude.toString();
        currentLong.value = position.longitude.toString();
        getAddressFromLatLng(double.parse(currentLat.toString()),
            double.parse(currentLong.toString()));
        logger
            .i('Current Location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      Toast.showToast('Please retry: ${e.toString()}');
    }
  }

  void showMap(
    BuildContext context, [
    bool? showCurrentLocation = true,
    double? latitude,
    double? longitude,
  ]) async {
    Position position = await Geolocator.getCurrentPosition();
    if (showCurrentLocation == false &&
        (latitude == null || longitude == null)) {
      Toast.showToast("Unable to get coordinates");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationMap(
            initialLatitude: (showCurrentLocation ?? true)
                ? position.latitude
                : latitude ?? 0,
            initialLongitude: (showCurrentLocation ?? true)
                ? position.longitude
                : longitude ?? 0,
            refreshLocation: (showCurrentLocation ?? true) ? getLocation : null,
          ),
        ),
      );
    }

    // print("Address: $address");
  }

  onSearchTextChanged(String text) async {
    searchText.value = text;
    if (text.length > 2) {
      try {
        final places = await placesService.getPlacesPredictions(text);
        print('PLACES: ${places}');
        predictions.assignAll(places);
        update();
      } catch (e) {
        logger.i('Error fetching predictions: $e');
      }
    } else {
      predictions.clear();
      update();
    }
  }

  getPlaceDetails(String placeId, locationAddress) async {
    try {
      final details = await placesService.getPlaceDetails(placeId);
      selectedPlace.value = details;
      logger.i(
          'getPlaceDetailslatitude ${selectedPlace['geometry']['location']['lat']}');
      logger.i(
          'getPlaceDetailslongitude ${selectedPlace['geometry']['location']['lng']}');
      getAddressFromLatLongs(selectedPlace['geometry']['location']['lat'],
          selectedPlace['geometry']['location']['lng'], locationAddress);
    } catch (e) {
      logger.i('Error fetching place details: $e');
    }
  }

  getAddressFromLatLongs(
      double latitudes, double longitudes, locationAddress) async {
    await placemarkFromCoordinates(latitudes, longitudes)
        .then((List<Placemark> placemarks) async {
      Placemark place = placemarks[0];
      cityController.text = '${place.locality}';
      stateController.text = '${place.administrativeArea}';
      suburbController.text =
          '${place.subLocality!.isNotEmpty ? place.subLocality : place.street}';
      postCodeController.text = '${place.postalCode}';
      addressController.text = locationAddress ?? '';
      latitude.value = double.parse(latitudes.toString()).toString();
      longitude.value = double.parse(longitudes.toString()).toString();
      predictions.clear();

      update();
      logger.i('latitude $latitude');
      logger.i('longitude $longitude');
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> getAddressFromLatLng(double latitudes, double longitudes) async {
    await placemarkFromCoordinates(latitudes, longitudes)
        .then((List<Placemark> placemarks) {
      /// Initializing the auto fill location.
      Placemark place = placemarks[0];
      latitude.value = double.parse(latitudes.toString()).toString();
      longitude.value = double.parse(longitudes.toString()).toString();
      suburbController.text = '${place.subLocality}';
      mobileNumberController.text =
          _homeScreenController.tenantContactNumber.value;
      cityController.text = '${place.locality}';
      stateController.text = '${place.administrativeArea}';
      postCodeController.text = '${place.postalCode}';
      addressController.text =
          '${place.street} ${place.subLocality} ${place.locality} ${place.administrativeArea} ${place.subAdministrativeArea} ${place.country} - ${place.postalCode}.';
      update();
    }).catchError((e) {
      Toast.showToast('Please retry: ${e.toString()}');
      debugPrint(e);
    });
  }

  // getProperties() {
  //   getPropertiesResult();
  // }
  //
  // getPropertiesResult() async {
  //   GetProperties? result = await _getPropertiesRepository.getProperties();
  //   if (result?.status == true) {
  //     List<PropertiesDetails> details = result?.details ?? [];
  //     for (var detail in details) {}
  //   }
  // }
}
