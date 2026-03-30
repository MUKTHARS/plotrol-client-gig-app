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
const _steel = Color(0xFF8C8480);

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
              letterSpacing: -0.5,
              height: 1.0,
              fontFamily: 'Raleway',
            ),
          ),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: _parchment,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16.0),
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
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Camera'),
                            onTap: () { Navigator.pop(context); controller.getImageFromCamera(); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () { Navigator.pop(context); controller.getImageFromGallery(); },
                          ),
                        ]),
                      ),
                    );
                    // controller.getImageList();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: DottedBorder(
                          dashPattern: [6, 6],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(12),
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12)),
                            child: Container(
                              height: 180,
                              width: Get.width,
                              color: Colors.grey.withOpacity(0.5),
                              child: (controller.images?.isEmpty ?? false)
                                  ? const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 8),
                                        ReusableTextWidget(
                                          text: 'Upload Image',
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        )
                                      ],
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: controller.images!.length,
                                      itemBuilder: (context, index) {
                                        final XFile image =
                                            controller.images![index];
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal:
                                                  5.0), // Add margin for spacing
                                          child: Stack(children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                  8.0), // Add rounded corners (optional)
                                              child: Image.file(
                                                File(image.path),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              top:
                                                  -2, // Adjust position as needed
                                              right:
                                                  -2, // Adjust position as needed
                                              child: IconButton(
                                                icon: const Icon(Icons.cancel,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  controller
                                                      .removeImageList(index);
                                                },
                                              ),
                                            ),
                                          ]),
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
                  height: 25,
                ),
                const Text(
                  'Please fill your work location and other details*',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _walnut,
                    height: 1.3,
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
                // const SizedBox(
                //   height: 20,
                // ),
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
                Row(
                  children: [
                    const Icon(Icons.location_on, color: _sienna),
                    const SizedBox(width: 6),
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                      ),
                    ),
                    const Spacer(),
                    Obx(() {
                      return GestureDetector(
                        onTap: () {
                          controller.toggleDropdown();
                          controller.update();
                        },
                        child: Icon(controller.isDropdownOpened.value
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                      );
                    }),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Offstage(
                  offstage: controller.isDropdownOpened.value,
                  child: CustomTextFormField(
                    controller: controller.addressController,
                    maxLines: 3,
                    onChanged: (value) {
                      controller.onSearchTextChanged(value);
                    },
                    suffixIcon: GestureDetector(
                        onTap: () {
                          controller.showMap(context);
                        },
                        child: const Icon(Icons.gps_fixed_outlined)),
                  ),
                ),
                controller.predictions.isNotEmpty
                    ? Container(
                        height: Get.height * 0.20,
                        width: Get.width,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15)),
                        child: Obx(() {
                          return ListView.builder(
                            itemCount: controller.predictions.length,
                            itemBuilder: (context, index) {
                              final prediction =
                                  controller.predictions[index]['description'];
                              return ListTile(
                                title: Text(
                                  prediction,
                                  style: const TextStyle(color: Colors.black),
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
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: controller.suburbController,
                            labelText: 'Suburb',
                          ),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: controller.cityController,
                            labelText: 'City',
                          ),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: controller.stateController,
                            labelText: 'State',
                          ),
                          SizedBox(height: 4.h),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: RoundedLoadingButton(
              width: MediaQuery.of(context).size.width,
              color: _sienna,
              onPressed: () async {
                ApiConstants.addProperties = ApiConstants.addPropertiesLive;
                controller.addYourPropertiesValidation();
                // authenticationController.updateHouseDetails();
                controller.btnController.reset();
              },
              borderRadius: 10,
              controller: controller.btnController,
              child: const Text(
                'Create',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
