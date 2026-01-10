import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/book_your_service_controller.dart';
import 'package:plotrol/globalWidgets/custom_scaffold_widget.dart';
import 'package:plotrol/globalWidgets/flutter_toast.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';

import '../Helper/Logger.dart';
import '../globalWidgets/text_widget.dart';
import '../model/response/adding_properties/get_properties_response.dart';
import '../widgets/thumbnail_collage.dart';
import 'image_grid_screen.dart';

class BookYourService extends StatelessWidget {
  final List<String>? tenantImage;
  final String address;
  final String contactNumber;
  final int locationID;
  final bool? isFromCategories;
  late final String selectedCategoryId;
  late final String selectedCategory;
  final Household householdModel;

  BookYourService({
    super.key,
    this.tenantImage,
    this.isFromCategories,
    this.address = '',
    this.contactNumber = '',
    this.selectedCategory = '',
    this.locationID = 0,
    this.selectedCategoryId = '',
    required this.householdModel,
  });

  final BookYourServiceController bookServiceController =
      Get.put(BookYourServiceController());

  final nowTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    print(tenantImage);
    return GetBuilder<BookYourServiceController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isFromCategories ?? false) {
            bookServiceController.selectedCategoryNames.add(selectedCategory);
          }
          //controller.selectedCategoryId.add(selectedCategoryId);
          bookServiceController.getCheckList();
          logger.i(
              'selectedCat : ${bookServiceController.selectedCategoryNames}');
          logger.i('selectedId : ${bookServiceController.selectedCategoryId}');
          bookServiceController.initializeSelection(
              selectedCategory, selectedCategoryId);
        });
      },
      builder: (controller) {
        return CustomScaffold(
          automaticallyImplyLeading: false,
          body: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  controller.selectedCategoryId.clear();
                  controller.selectedCategoryNames.clear();
                  controller.resetSelection();
                  Get.back();
                },
              ),
              title: const ReusableTextWidget(
                text: 'Book Your Service',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SingleChildScrollView(
                child: Sizer(
                  builder: (BuildContext context, Orientation orientation,
                      deviceType) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ReusableTextWidget(
                          text: 'Property Details',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (householdModel.address?.latitude != null &&
                                householdModel.address?.longitude != null) {
                              await AppUtils().openMap(
                                  householdModel.address?.latitude ?? 0,
                                  householdModel.address?.longitude ?? 0);
                            } else {
                              Toast.showToast(
                                  "Couldn't get coordinates. Please contact Admin");
                            }
                          },
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: const BorderSide(
                                  color: Colors.grey,
                                  width: 0.3,
                                ) // Adjust radius
                                ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 140,
                                  child: InkWell(
                                    onTap: () => Get.to(() => ImageGridScreen(
                                          imageUrls: tenantImage ?? [],
                                          title: 'Property Images',
                                        )),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomLeft: Radius.circular(10),
                                      ),
                                      child: ThumbCollage(
                                        urls: tenantImage ??
                                            [], // safe: already checked isNotEmpty
                                        height: 140,
                                        width: 120, // 👈 finite width!
                                        borderRadius:
                                            0, // parent ClipRRect already rounds corners
                                        spacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5, right: 5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 20,
                                            ),
                                            Expanded(
                                              child: SizedBox(
                                                width: Get.width * 0.40,
                                                child: ReusableTextWidget(
                                                  text: address,
                                                  fontSize: 13,
                                                  maxLines: 3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Row(
                                        //   children: [
                                        //     const Icon(
                                        //       Icons.phone,
                                        //       size: 20,
                                        //     ),
                                        //     ReusableTextWidget(
                                        //       text: '+91 $contactNumber',
                                        //       fontSize: 13,
                                        //     ),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        // EasyInfiniteDateTimeLine(
                        //   physics: const NeverScrollableScrollPhysics(),
                        //   controller: controller.dateTimelineController,
                        //   onDateChange: null,
                        //   firstDate: DateTime(
                        //       nowTime.year - 5, nowTime.month, nowTime.day),
                        //   focusDate: controller.dateTime.value,
                        //   lastDate: DateTime(
                        //       nowTime.year + 1, nowTime.month, nowTime.day),
                        //   dayProps: EasyDayProps(
                        //     height: 80,
                        //     width: 50,
                        //     inactiveDayNumStyle:
                        //         const TextStyle(color: Colors.grey),
                        //     todayStyle: DayStyle(
                        //       dayStrStyle:
                        //           const TextStyle(fontFamily: 'Raleway'),
                        //       decoration: BoxDecoration(
                        //         color: Colors.grey.withOpacity(0.5),
                        //         borderRadius:
                        //             const BorderRadius.all(Radius.circular(8)),
                        //       ),
                        //     ),
                        //     inactiveDayStyle: DayStyle(
                        //       dayStrStyle: const TextStyle(
                        //           fontFamily: 'Raleway', color: Colors.grey),
                        //       decoration: BoxDecoration(
                        //         color: Colors.grey.withOpacity(0.5),
                        //         borderRadius:
                        //             const BorderRadius.all(Radius.circular(8)),
                        //       ),
                        //     ),
                        //     dayStructure: DayStructure.dayStrDayNum,
                        //     activeDayStyle: const DayStyle(
                        //       dayStrStyle: TextStyle(fontFamily: 'Raleway'),
                        //       decoration: BoxDecoration(
                        //         borderRadius:
                        //             BorderRadius.all(Radius.circular(8)),
                        //         color: Colors.grey,
                        //         gradient: LinearGradient(
                        //           begin: Alignment.topCenter,
                        //           end: Alignment.bottomLeft,
                        //           colors: [
                        //             Colors.grey,
                        //             Colors.black54,
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(
                          height: 15,
                        ),
                        const ReusableTextWidget(
                          text: 'Select Services',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: controller.listOfCategories.length,
                          itemBuilder: (context, index) {
                            var categories = controller.listOfCategories[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: InkWell(
                                onTap: () {
                                  controller.toggleSelection(index);
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(width: 0.5),
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          minRadius: 15,
                                          maxRadius: 15,
                                          child: ClipOval(
                                            child: Image.asset(
                                              height: 30,
                                              width: 30,
                                              controller.listOfCategories[index]
                                                      .serviceimage ??
                                                  '',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        ReusableTextWidget(
                                          text: controller
                                                  .listOfCategories[index]
                                                  .categoryname ??
                                              '',
                                          fontSize: 16,
                                        ),
                                        const Spacer(),
                                        // Replace this with your conditional icon based on selection
                                        controller.isSelected[index]
                                            ? const Icon(Icons.check)
                                            : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // const ReusableTextWidget(
                        //   text: 'Additional Options',
                        //   fontSize: 17,
                        //   fontWeight: FontWeight.w600,
                        // ),
                      ],
                    );
                  },
                ),
              ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
              padding: const EdgeInsets.all(14),
              child: RoundedLoadingButton(
                width: Get.width,
                color: Colors.black,
                onPressed: () {
                  // ApiConstants.bookService = ApiConstants.bookServicesLive;
                  // controller.locationId.value = locationID;
                  // controller.bookServiceProperty();
                  // controller.bookYourServiceValidation();
                  // controller.resetSelection();
                  // controller.btnController.reset();
                  controller.bookYourServiceValidation(
                      locationID, householdModel);
                },
                borderRadius: 10,
                controller: controller.btnController,
                child: const ReusableTextWidget(
                  text: 'Place Order',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}
