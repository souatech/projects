import 'package:driver/constant/constant.dart';
import 'package:driver/controllers/parcel_home_controller.dart';
import 'package:driver/themes/round_button_fill.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as location;
import '../../controllers/parcel_tracking_controller.dart';
import '../../themes/app_them_data.dart';
import '../../widget/driver_app_shell.dart';

class ParcelTrackingScreen extends StatelessWidget {
  const ParcelTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<ParcelTrackingController>(
      init: ParcelTrackingController(),
      builder: (controller) {
        final isDark = Get.find<ThemeController>().isDark.value;
        return DriverAppShell(
          title: controller.orderModel.value.status == Constant.driverAccepted
              ? "Aller au ramassage".tr
              : "Itinéraire livraison".tr,
          child: controller.isLoading.value
              ? Constant.loader()
              : Constant.selectedMapType == 'osm'
                  ? flutterMap.FlutterMap(
                      mapController: controller.osmMapController,
                      options: flutterMap.MapOptions(
                        initialCenter: location.LatLng(
                            Constant.locationDataFinal?.latitude?.toDouble() ??
                                Constant.userModel?.location?.latitude
                                    ?.toDouble() ??
                                45.521563,
                            Constant.locationDataFinal?.longitude?.toDouble() ??
                                Constant.userModel?.location?.longitude
                                    ?.toDouble() ??
                                -122.677433),
                        initialZoom: 14,
                      ),
                      children: [
                        flutterMap.TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.joxmako.driver',
                        ),
                        flutterMap.MarkerLayer(markers: controller.osmMarkers),
                        if (controller.routePoints.isNotEmpty)
                          flutterMap.PolylineLayer(
                            polylines: [
                              flutterMap.Polyline(
                                points: controller.routePoints,
                                strokeWidth: 5.0,
                                color: AppThemeData.primary300,
                              ),
                            ],
                          ),
                      ],
                    )
                  : Obx(
                      () => GoogleMap(
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.terrain,
                        zoomControlsEnabled: false,
                        polylines:
                            Set<Polyline>.of(controller.polyLines.values),
                        padding: const EdgeInsets.only(top: 22.0),
                        markers: Set<Marker>.of(controller.markers.values),
                        onMapCreated: (GoogleMapController mapController) {
                          controller.mapController = mapController;
                          controller.moveToDriverPosition();
                        },
                        initialCameraPosition: CameraPosition(
                          zoom: 14,
                          target: LatLng(
                            (Constant.locationDataFinal?.latitude ??
                                    Constant.userModel?.location?.latitude ??
                                    45.521563)
                                .toDouble(),
                            (Constant.locationDataFinal?.longitude ??
                                    Constant.userModel?.location?.longitude ??
                                    -122.677433)
                                .toDouble(),
                          ),
                        ),
                      ),
                    ),
          bottomNavigationBar: controller.isLoading.value
              ? null
              : _buildActionBar(context, controller, isDark),
        );
      },
    );
  }

  Widget? _buildActionBar(
      BuildContext context, ParcelTrackingController controller, bool isDark) {
    final status = controller.orderModel.value.status;

    if (status == Constant.driverAccepted) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: RoundedButtonFill(
            title: "Ramasser le colis".tr,
            height: 6,
            color: AppThemeData.success400,
            textColor: AppThemeData.grey50,
            onPress: () async {
              final homeCtrl = Get.find<ParcelHomeController>();
              await homeCtrl.pickupParcel(controller.orderModel.value);
            },
          ),
        ),
      );
    }

    if (status == Constant.orderInTransit) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: RoundedButtonFill(
            title: "Livrer le colis".tr,
            height: 6,
            color: AppThemeData.success400,
            textColor: AppThemeData.grey50,
            onPress: () {
              _showDeliveryDialog(context, controller, isDark);
            },
          ),
        ),
      );
    }

    return null;
  }

  void _showDeliveryDialog(BuildContext context,
      ParcelTrackingController controller, bool isDark) {
    final parcelData = controller.orderModel.value;
    String selectedMethod = 'Espèces';
    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor:
              isDark ? const Color(0xFF1E1E1E) : AppThemeData.grey50,
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Le client a payé via :".tr,
                          style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                          ),
                        ),
                      ),
                      InkWell(
                          onTap: () => Get.back(),
                          child: const Icon(Icons.close, size: 22)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'Espèces',
                    groupValue: selectedMethod,
                    activeColor: AppThemeData.primary300,
                    title: Text("Espèces".tr,
                        style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium)),
                    onChanged: (v) => setState(() => selectedMethod = v!),
                  ),
                  RadioListTile<String>(
                    value: 'Wave',
                    groupValue: selectedMethod,
                    activeColor: AppThemeData.primary300,
                    title: Text("Wave",
                        style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium)),
                    onChanged: (v) => setState(() => selectedMethod = v!),
                  ),
                  RadioListTile<String>(
                    value: 'Orange Money',
                    groupValue: selectedMethod,
                    activeColor: AppThemeData.primary300,
                    title: Text("Orange Money",
                        style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium)),
                    onChanged: (v) => setState(() => selectedMethod = v!),
                  ),
                  // Récapitulatif GP (si colis GP)
                  Builder(builder: (_) {
                    final double driverFee =
                        double.tryParse(parcelData.collectionFee ?? '0') ?? 0;
                    if (driverFee <= 0) return const SizedBox.shrink();
                    final double gpAmount =
                        double.tryParse(parcelData.subTotal ?? '0') ?? 0;
                    final double commDriver =
                        parcelData.driverAdminCommAmount ?? 0;
                    final double commGp = parcelData.gpAdminCommAmount ?? 0;
                    final double gainDriver = parcelData.driverEarning ??
                        (driverFee - commDriver);
                    final double gainGp =
                        parcelData.gpEarning ?? (gpAmount - commGp);
                    final bool driverCollectsGP =
                        parcelData.customerPaysFullAmountToDriver == true;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFFFCC00)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Récapitulatif Colis GP',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF6B4F00))),
                              const SizedBox(height: 8),
                              _gpRow('Frais livreur :',
                                  Constant.amountShow(amount: driverFee.toString())),
                              _gpRow('Montant GP :',
                                  Constant.amountShow(amount: gpAmount.toString())),
                              const Divider(
                                  color: Color(0xFFFFCC00), height: 12),
                              _gpRow('Commission admin (livraison) :',
                                  Constant.amountShow(amount: commDriver.toString())),
                              _gpRow('Commission admin (GP) :',
                                  Constant.amountShow(amount: commGp.toString())),
                              const Divider(
                                  color: Color(0xFFFFCC00), height: 12),
                              _gpRow('Gain livreur net :',
                                  Constant.amountShow(amount: gainDriver.toString())),
                              _gpRow('Gain GP net :',
                                  Constant.amountShow(amount: gainGp.toString())),
                              if (driverCollectsGP) ...[
                                const Divider(
                                    color: Color(0xFFFFCC00), height: 12),
                                _gpRow(
                                    'Cash à remettre (GP) :',
                                    Constant.amountShow(
                                        amount: gpAmount.toString())),
                                const SizedBox(height: 4),
                                const Text(
                                    '⚠️ Le montant GP collecté est à remettre à l\'admin',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B4F00),
                                        fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.primary300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Get.back();
                        await Get.find<ParcelHomeController>()
                            .completeParcel(parcelData,
                                collectedPaymentMethod: selectedMethod);
                      },
                      child: Text(
                        "Confirmer la livraison".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _gpRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B4F00))),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B4F00))),
        ],
      ),
    );
  }
}
