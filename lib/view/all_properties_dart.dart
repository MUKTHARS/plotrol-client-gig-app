import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/bottom_navigation_controller.dart';
import 'package:plotrol/controller/home_screen_controller.dart';
import 'package:plotrol/globalWidgets/custom_scaffold_widget.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/view/main_screen.dart';
import 'package:plotrol/view/properties_details.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shimmer/shimmer.dart';

import '../globalWidgets/text_widget.dart';
import 'book_your_service.dart';

// ── Design tokens (matching home screen) ─────────────────────────────────────
const _cream       = Color(0xFFF7F3EE);
const _parchment   = Color(0xFFEFE9DF);
const _sand        = Color(0xFFE4DAC8);
const _espresso    = Color(0xFF1C1510);
const _walnut      = Color(0xFF3D2B1F);
const _sienna      = Color(0xFFB85C38);
const _siennaLight = Color(0x1AB85C38);
const _steel       = Color(0xFF8C8480);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class AllProperties extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedCategoryID;
  final bool? isFromCategory;

  AllProperties({
    super.key,
    this.selectedCategory,
    this.selectedCategoryID,
    this.isFromCategory,
  });

  final HomeScreenController controller = Get.put(HomeScreenController());
  final BottomNavigationController bottomNavigationController =
      Get.put(BottomNavigationController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenController>(builder: (controller) {
      return CustomScaffold(
        body: Scaffold(
          backgroundColor: _cream,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: _espresso, size: 20),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              'All Properties',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _espresso,
                fontFamily: 'Raleway',
              ),
            ),
            centerTitle: false,
          ),
          body: controller.getPropertiesDetails.isEmpty
              ? _buildEmptyState(controller)
              : _buildPropertiesList(controller),
        ),
      );
    });
  }

  Widget _buildEmptyState(HomeScreenController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _parchment,
                shape: BoxShape.circle,
                border: Border.all(color: _sand, width: 1.5),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 40,
                color: _steel,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No properties yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _espresso,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your properties to book services',
              style: TextStyle(
                fontSize: 14,
                color: _steel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            RoundedLoadingButton(
              color: _sienna,
              controller: controller.btnController,
              onPressed: () {
                Get.to(() => HomeView(selectedIndex: 2));
                controller.btnController.reset();
              },
              borderRadius: 25,
              width: 160,
              height: 45,
              child: const Text(
                'Add Properties',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesList(HomeScreenController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: controller.getPropertiesDetails.length,
      itemBuilder: (context, index) {
        final prop = controller.getPropertiesDetails[index];
        final notes = prop.additionalFields?.fields
            ?.where((a) => a.key == 'notes')
            .firstOrNull
            ?.value ?? '';
        final contactNo = prop.additionalFields?.fields
            ?.where((a) => a.key == 'contactNo')
            .firstOrNull
            ?.value ?? '';

        return GestureDetector(
          onTap: () {
            Get.to(() => PropertiesDetailsScreen(
                  propertyImage: prop.imageUrls,
                  address: AppUtils().formatAddress(prop.address),
                  contactNumber: contactNo,
                ));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _dividerLine),
              boxShadow: [
                BoxShadow(
                  color: _espresso.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                // Image section - Fixed to fill container without gaps
ClipRRect(
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(20),
    bottomLeft: Radius.circular(20),
  ),
  child: Container(
    width: 120,
    height: 140,
    color: _parchment,
    child: Builder(builder: (context) {
      final imageUrls = prop.imageUrls;
      final validUrl = imageUrls?.firstWhere(
        (u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://')),
        orElse: () => '',
      ) ?? '';
      return validUrl.isNotEmpty
          ? Image.network(
              validUrl,
              fit: BoxFit.cover,
              width: 120,
              height: 140,
              errorBuilder: (context, error, _) => Container(
                width: 120,
                height: 140,
                color: _parchment,
                child: const Icon(Icons.image_outlined, size: 40, color: _sand),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 120,
                  height: 140,
                  color: _parchment,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_sienna),
                      ),
                    ),
                  ),
                );
              },
            )
          : Container(
              width: 120,
              height: 140,
              color: _parchment,
              child: const Icon(Icons.image_outlined, size: 40, color: _sand),
            );
    }),
  ),
),
                
                // Content section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notes.isNotEmpty ? notes : 'My Property',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _espresso,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: _sienna),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppUtils().formatAddress(prop.address),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _steel,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.phone, size: 14, color: _sienna),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contactNo.isNotEmpty ? contactNo : 'No contact',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _steel,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => BookYourService(
                                    tenantImage: [prop.imageUrls?.firstOrNull ?? ImageAssetsConst.sampleRoomPage],
                                    householdModel: prop,
                                    address: AppUtils().formatAddress(prop.address),
                                    contactNumber: contactNo,
                                    selectedCategory: selectedCategory ?? '',
                                    isFromCategories: isFromCategory,
                                  ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _espresso,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Book Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:plotrol/controller/bottom_navigation_controller.dart';
// import 'package:plotrol/controller/home_screen_controller.dart';
// import 'package:plotrol/globalWidgets/custom_scaffold_widget.dart';
// import 'package:plotrol/helper/const_assets_const.dart';
// import 'package:plotrol/helper/utils.dart';
// import 'package:plotrol/view/main_screen.dart';
// import 'package:plotrol/view/properties_details.dart';
// import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

// import '../globalWidgets/text_widget.dart';
// import 'book_your_service.dart';

// class AllProperties extends StatelessWidget {
//   final String? selectedCategory;
//   final String? selectedCategoryID;
//   final bool? isFromCategory;

//   AllProperties(
//       {super.key,
//       this.selectedCategory,
//       this.selectedCategoryID,
//       this.isFromCategory});

//   final HomeScreenController controller = Get.put(HomeScreenController());

//   final BottomNavigationController bottomNavigationController =
//       Get.put(BottomNavigationController());

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<HomeScreenController>(builder: (controller) {
//       return CustomScaffold(
//         body: Scaffold(
//           appBar: AppBar(
//             automaticallyImplyLeading: true,
//             backgroundColor: Colors.white,
//             title: const ReusableTextWidget(
//               text: 'All Properties',
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           body: controller.getPropertiesDetails.isEmpty
//               ? Padding(
//                   padding: const EdgeInsets.only(left: 10, right: 10),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const ReusableTextWidget(
//                         text: 'Please add properties to Book a service',
//                         fontSize: 18,
//                         maxLines: 2,
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 10),
//                       RoundedLoadingButton(
//                         color: Colors.black,
//                         controller: controller.btnController,
//                         onPressed: () {
//                           Get.to(() => HomeView(
//                                 selectedIndex: 2,
//                               ));
//                           controller.btnController.reset();
//                         },
//                         borderRadius: 10,
//                         child: const ReusableTextWidget(
//                           text: 'Add Properties',
//                           color: Colors.white,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : Padding(
//                   padding: const EdgeInsets.only(left: 10, right: 10),
//                   child: ListView.builder(
//                     itemCount: controller.getPropertiesDetails.length,
//                     itemBuilder: (context, index) {
//                       return InkWell(
//                         onTap: () {
//                           Get.to(() => PropertiesDetailsScreen(
//                                 propertyImage: controller
//                                     .getPropertiesDetails[
//                                 index].imageUrls,
//                                 address: AppUtils().formatAddress(controller.getPropertiesDetails[index].address),
//                             contactNumber: controller
//                                 .getPropertiesDetails[
//                             index]
//                                 .additionalFields?.fields?.where((a) => a.key == 'contactNo').firstOrNull?.value ??
//                                 '',
//                               ));
//                         },
//                         child: Card(
//                           color: Colors.white,
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10.0),
//                               side: const BorderSide(
//                                 color: Colors.grey,
//                                 width: 0.3,
//                               ) // Adjust radius
//                               ),
//                           child: SizedBox(
//                             height: 155,
//                             width: Get.width,
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ClipRRect(
//                                   borderRadius: const BorderRadius.only(
//                                     topLeft: Radius.circular(10.0),
//                                     bottomLeft: Radius.circular(10.0),
//                                   ),
//                                   child: Builder(builder: (context) {
//                                     final imageUrls = controller.getPropertiesDetails[index].imageUrls;
//                                     final validUrl = imageUrls?.firstWhere(
//                                       (u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://')),
//                                       orElse: () => '',
//                                     ) ?? '';
//                                     return validUrl.isNotEmpty
//                                         ? Image.network(
//                                             validUrl,
//                                             height: 155,
//                                             width: 110,
//                                             fit: BoxFit.cover,
//                                             errorBuilder: (context, error, _) => Container(
//                                               height: 155,
//                                               width: 110,
//                                               color: Colors.grey.shade200,
//                                               child: const Icon(Icons.image_outlined, color: Colors.grey),
//                                             ),
//                                             loadingBuilder: (context, child, progress) {
//                                               if (progress == null) return child;
//                                               return Container(
//                                                 height: 155,
//                                                 width: 110,
//                                                 color: Colors.grey.shade200,
//                                                 child: const Center(
//                                                   child: SizedBox(
//                                                     width: 20,
//                                                     height: 20,
//                                                     child: CircularProgressIndicator(strokeWidth: 2),
//                                                   ),
//                                                 ),
//                                               );
//                                             },
//                                           )
//                                         : Container(
//                                             height: 155,
//                                             width: 110,
//                                             color: Colors.grey.shade200,
//                                             child: const Icon(Icons.image_outlined, color: Colors.grey),
//                                           );
//                                   }),
//                                 ),
//                                 Expanded(
//                                   child: Padding(
//                                     padding: EdgeInsets.all(5),
//                                     child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           ReusableTextWidget(
//                                             text:
//                                                 '${controller.getPropertiesDetails[index].additionalFields?.fields?.where((a) => a.key == 'notes').firstOrNull?.value ?? ''}',
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 16,
//                                           ),
//                                           const SizedBox(
//                                             height: 10,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.start,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               const Icon(
//                                                 Icons.location_on,
//                                                 size: 15,
//                                               ),
//                                               Expanded(
//                                                 child: ReusableTextWidget(
//                                                   maxLines: 2,
//                                                   text: AppUtils().formatAddress(controller.getPropertiesDetails[index].address),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(
//                                             height: 5,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.start,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Icon(
//                                                 Icons.phone,
//                                                 size: 15,
//                                               ),
//                                               Expanded(
//                                                 child: ReusableTextWidget(
//                                                   maxLines: 2,
//                                                   text:
//                                                       '${controller.getPropertiesDetails[index].additionalFields?.fields?.where((a) => a.key == 'contactNo').firstOrNull?.value ?? ''}',
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(
//                                             height: 10,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.end,
//                                             children: [
//                                               SizedBox(
//                                                 height: 20,
//                                                 child: ElevatedButton(
//                                                   style: ButtonStyle(
//                                                     padding:
//                                                         WidgetStateProperty.all(
//                                                             EdgeInsets.only(
//                                                                 left: 5,
//                                                                 right: 5)),
//                                                     backgroundColor:
//                                                         WidgetStateProperty.all(
//                                                             Colors.black),
//                                                     foregroundColor:
//                                                         WidgetStateProperty.all(
//                                                             Colors.white),
//                                                     shape: WidgetStateProperty.all<
//                                                         RoundedRectangleBorder>(
//                                                       RoundedRectangleBorder(
//                                                         borderRadius:
//                                                             BorderRadius.circular(
//                                                                 5), // Adjust radius
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   onPressed: () {
//                                                     print("Household");
//                                                     print(controller.getPropertiesDetails[index].imageUrls);
//                                                     Get.to(
//                                                         () => BookYourService(
//                                                               tenantImage: [controller.getPropertiesDetails[index].imageUrls?.firstOrNull ?? ImageAssetsConst.sampleRoomPage],
//                                                               householdModel: controller.getPropertiesDetails[index],
//                                                               address: AppUtils().formatAddress(controller.getPropertiesDetails[index].address),
//                                                               contactNumber: controller
//                                                                       .getPropertiesDetails[
//                                                                           index]
//                                                                       .additionalFields?.fields?.where((a) => a.key == 'contactNo').firstOrNull?.value ??
//                                                                   '',
//                                                               selectedCategory:
//                                                                   selectedCategory ??
//                                                                       '',
//                                                               // locationID: controller
//                                                               //         .getPropertiesDetails[
//                                                               //             index]
//                                                               //         .locationid ??
//                                                               //     0,
//                                                               isFromCategories:
//                                                                   isFromCategory,
//                                                             ));
//                                                   },
//                                                   child:
//                                                       const ReusableTextWidget(
//                                                     text: 'BOOK SERVICE',
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ]),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//         ),
//       );
//     });
//   }
// }
