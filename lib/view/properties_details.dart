import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/home_screen_controller.dart';
import 'package:plotrol/controller/properties_details_controller.dart';
import 'package:plotrol/globalWidgets/custom_scaffold_widget.dart';
import 'package:sizer/sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../globalWidgets/text_widget.dart';
import '../helper/const_assets_const.dart';
import 'home_screen.dart';

class PropertiesDetailsScreen extends StatelessWidget {
  final List<String>? propertyImage;
  final String? address;
  final String? contactNumber;

  PropertiesDetailsScreen({
    super.key,
    this.propertyImage,
    this.address,
    this.contactNumber,
  });

  final PropertiesDetailsController propertiesDetailsController =
      Get.put(PropertiesDetailsController());

  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return CustomScaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 60.h,
                          autoPlay: false,
                          enlargeCenterPage: false,
                          aspectRatio: 16 / 9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enableInfiniteScroll: true,
                          autoPlayAnimationDuration:
                              Duration(milliseconds: 800),
                          viewportFraction: 1,
                          onPageChanged: (index, reason) {
                            propertiesDetailsController.onPageChanged(index);
                          },
                        ),
                        items: propertyImage
                            ?.where((item) => item.isNotEmpty && (item.startsWith('http://') || item.startsWith('https://')))
                            .map((item) => Center(
                                  child: Image.network(item,
                                      fit: BoxFit.cover,
                                      height: 150.h,
                                      width: 1000,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        ImageAssetsConst.sampleRoomPage,
                                        width: 120,
                                        height: 140,
                                        fit: BoxFit.fill,
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;

                                      final total = loadingProgress.expectedTotalBytes;
                                      final loaded = loadingProgress.cumulativeBytesLoaded;
                                      final progress = total != null ? loaded / total : null;

                                      return SizedBox(
                                        height: 140,
                                        width: 120,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(value: progress),
                                              const SizedBox(height: 8),
                                              if (progress != null)
                                                Text('${(progress * 100).toStringAsFixed(0)}%'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                      Positioned(
                        top: 16,
                        left: 0,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            Get.back();
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons
                                    .location_on, // Choose the icon you want to use
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: ReusableTextWidget(
                                  text: address ?? '',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                  maxLines: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Obx(() {
                    return Center(
                      child: AnimatedSmoothIndicator(
                        activeIndex:
                            propertiesDetailsController.currentIndex.value,
                        count: propertyImage?.length ?? 0,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: Colors.black,
                          dotColor: Colors.grey,
                          dotHeight: 10.0,
                          dotWidth: 20.0,
                          spacing: 8.0,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(
                    height: 15,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: ReusableTextWidget(
                      text: 'Previous Services',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: SizedBox(
                      width: Get.width,
                      child: OnGoingTask(
                        isVerticalScrollable: true,
                        status: 'completed',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
