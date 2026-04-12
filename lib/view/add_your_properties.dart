import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plotrol/controller/add_your_properties_controller.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/globalWidgets/text_widget.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';

import '../globalWidgets/text_field_widget.dart';
import '../helper/api_constants.dart';

// reuse the home screen design tokens to keep layout consistency
const _cream = Color(0xFFF7F3EE);
const _parchment = Color(0xFFEFE9DF);
const _sand = Color(0xFFE4DAC8);
const _espresso = Color(0xFF1C1510);
const _walnut = Color(0xFF3D2B1F);
const _sienna = Color(0xFFB85C38);
const _siennaLight = Color(0x1AB85C38);
const _steel = Color(0xFF8C8480);
const _dividerLine = Color(0xFFDDD5C8);

class AddYourProperties extends StatelessWidget {
  AddYourProperties({super.key});

  final AddYourPropertiesController addPropertiesController =
      Get.put(AddYourPropertiesController());
  final AuthenticationController authenticationController =
  Get.put(AuthenticationController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddYourPropertiesController>(initState: (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        addPropertiesController.getLocation();
      });
    }, builder: (controller) {
      return Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _cream,
          elevation: 0,
          title: const Text(
            'Add Your Properties',
            style: TextStyle(
              color: _espresso,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(children: [
                          ListTile(
                            leading: const Icon(Icons.photo_camera, color: _walnut),
                            title: const Text(
                              'Camera',
                              style: TextStyle(
                                color: _espresso,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () { Navigator.pop(context); controller.getImageFromCamera(); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: _walnut),
                            title: const Text(
                              'Gallery',
                              style: TextStyle(
                                color: _espresso,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () { Navigator.pop(context); controller.getImageFromGallery(); },
                          ),
                        ]),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: DottedBorder(
                          dashPattern: [6, 6],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(20),
                          color: _steel,
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                            child: Container(
                              height: 180,
                              width: Get.width,
                              color: _parchment,
                              child: (controller.images?.isEmpty ?? false)
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: _cream,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: _sand, width: 1.5),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 24,
                                            color: _steel,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Upload Image',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _walnut,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tap to add property photos',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _steel,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: controller.images!.length,
                                      itemBuilder: (context, index) {
                                        final XFile image =
                                            controller.images![index];
                                        return Container(
                                          width: 160,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Image.file(
                                                  File(image.path),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color: _parchment,
                                                      child: const Icon(
                                                        Icons.error_outline,
                                                        color: _steel,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    controller.removeImageList(index);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: _espresso.withOpacity(0.8),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
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
                    ],
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _siennaLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: _sienna),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please fill your work location and other details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _walnut,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Offstage(
                  child: CustomTextFormField(
                    controller: controller.mobileNumberController,
                    labelText: 'Mobile Number',
                    keyboardType: TextInputType.number,
                    onChanged: (text) {
                      if (text.length == 10) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                CustomTextFormField(
                  controller: controller.notesController,
                  labelText: 'Information to locate the property',
                  maxLines: 5,
                ),
                const SizedBox(
                  height: 20,
                ),
                CustomTextFormField(
                  controller: controller.locationName,
                  labelText: 'Location Name',
                  maxLines: 2,
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _siennaLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, size: 16, color: _sienna),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Address Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _espresso,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      Obx(() {
                        return GestureDetector(
                          onTap: () {
                            controller.toggleDropdown();
                            controller.update();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              controller.isDropdownOpened.value
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: _steel,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                // Location method toggle: Map vs what3words
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.locationMethod.value = 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: controller.locationMethod.value == 0 ? _sienna : _parchment,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: controller.locationMethod.value == 0 ? _sienna : _dividerLine,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 14,
                                  color: controller.locationMethod.value == 0 ? Colors.white : _steel),
                              const SizedBox(width: 4),
                              Text('Map',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: controller.locationMethod.value == 0 ? Colors.white : _steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.locationMethod.value = 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: controller.locationMethod.value == 1 ? _sienna : _parchment,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: controller.locationMethod.value == 1 ? _sienna : _dividerLine,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon(Icons.grid_3x3, size: 14,
                              //     color: controller.locationMethod.value == 1 ? Colors.white : _steel),
                              const SizedBox(width: 4),
                              Text('///what3words',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: controller.locationMethod.value == 1 ? Colors.white : _steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 8),
                // Map / address search input
                Obx(() => Offstage(
                  offstage: controller.isDropdownOpened.value || controller.locationMethod.value == 1,
                  child: CustomTextFormField(
                    controller: controller.addressController,
                    labelText: 'Search address',
                    maxLines: 3,
                    onChanged: (value) {
                      controller.onSearchTextChanged(value);
                    },
                    suffixIcon: GestureDetector(
                        onTap: () {
                          controller.showMap(context);
                        },
                        child: const Icon(Icons.gps_fixed_outlined, color: _sienna)),
                  ),
                )),
                // what3words input
                Obx(() => Offstage(
                  offstage: controller.isDropdownOpened.value || controller.locationMethod.value == 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: controller.w3wController,
                          labelText: '///word.word.word',
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.convertW3WToCoords(controller.w3wController.text),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _sienna,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                )),
                controller.predictions.isNotEmpty
                    ? Container(
                        height: Get.height * 0.20,
                        width: Get.width,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _dividerLine)),
                        child: Obx(() {
                          return ListView.builder(
                            itemCount: controller.predictions.length,
                            itemBuilder: (context, index) {
                              final prediction =
                                  controller.predictions[index]['description'];
                              return ListTile(
                                title: Text(
                                  prediction,
                                  style: const TextStyle(
                                    color: _espresso,
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {
                                  final placeId =
                                      controller.predictions[index]['place_id'];
                                  controller.getPlaceDetails(
                                      placeId, prediction);
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              );
                            },
                          );
                        }),
                      )
                    : const SizedBox(),
                controller.isDropdownOpened.value
                    ? Column(
                        children: [
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: controller.suburbController,
                            labelText: 'Suburb',
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: controller.cityController,
                            labelText: 'City',
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: controller.stateController,
                            labelText: 'State',
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: controller.postCodeController,
                            labelText: 'Pincode',
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            )))),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: RoundedLoadingButton(
              width: MediaQuery.of(context).size.width,
              color: _sienna,
              onPressed: () async {
                ApiConstants.addProperties = ApiConstants.addPropertiesLive;
                controller.addYourPropertiesValidation();
                controller.btnController.reset();
              },
              borderRadius: 14,
              controller: controller.btnController,
              child: const Text(
                'Create Property',
                style: TextStyle(
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
}