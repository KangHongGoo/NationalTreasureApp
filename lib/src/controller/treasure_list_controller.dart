import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapmapmap/src/detail//treasure_detail.dart';
import 'package:xml2json/xml2json.dart';
import 'package:http/http.dart' as http;

class TreasureListController extends GetxController {
  RxDouble lat1 = 0.0.obs;
  RxDouble lng1 = 0.0.obs;

  var isToggleActive = false.obs;
  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  var treasureRegionData = <String, String>{
    '서울': '11',
    '부산': '21',
    '대구': '22',
    '인천': '23',
    '광주': '24',
    '대전': '25',
    '울산': '26',
    '세종': '45',
    '경기': '31',
    '강원': '32',
    '충북': '33',
    '충남': '34',
    '전북': '35',
    '전남': '36',
    '경북': '37',
    '경남': '38',
    '제주': '50',
  };

  String selectedTreasureRegionCode = '11';

  void updateTreasureSelectedRegion(String ccbaCtcd) {
    selectedTreasureRegionCode = ccbaCtcd;
    polylines.clear();
    loadData();
  }

  void toggleMarkers() {
    isToggleActive.value = !isToggleActive.value;
  }

  Future<Set<Marker>> loadData() async {
    markers.value = await LoadTreasureListData(selectedTreasureRegionCode);
    return markers;
  }

  Future<List<dynamic>> LoadPositions(
      double lat1, double lng1, double lat2, double lng2) async {
    String url =
        'https://naveropenapi.apigw.ntruss.com/map-direction-15/v1/driving?start=${lat1},${lng1}&goal=${lat2},${lng2}&option=traoptimal';

    final response = await http.get(Uri.parse(url), headers: {
      "X-NCP-APIGW-API-KEY-ID": "ywb9wu3rko",
      "X-NCP-APIGW-API-KEY": "0yBiwksBvWSLSLkVzNzszVsiIeLqCA3AeEj7QXpk",
    });
    Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

    Map<String, dynamic> data1 = data['route'];

    List<dynamic> data2 = data1['traoptimal'];

    List<dynamic> positions = data2[0]['path'];

    return positions;
  }

  Future<Set<Marker>> LoadTreasureListData(String ccbaCtcd) async {
    String url =
        "http://www.cha.go.kr/cha/SearchKindOpenapiList.do?ccbaKdcd=12&pageUnit=3000&ccbaCtcd=${ccbaCtcd}";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
    );
    final getXmlData = response.body;
    final Xml2JsonData = Xml2Json()..parse(getXmlData);
    final jsonData = Xml2JsonData.toParker();

    Map<String, dynamic> data = jsonDecode(jsonData);

    List<dynamic> items = data['result']['item'];

    Set<Marker> markers = {};
    Set<Marker> tempMarkers = {};

    for (var item in items) {
      String ccbaAsno = item['ccbaAsno'];
      String ccbaCtcd = item['ccbaCtcd'];

      BitmapDescriptor customMarkerIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(1, 1)),
        'assets/pin_treasure1.png',
      );

      Marker marker = Marker(
          markerId: MarkerId(item['no']),
          infoWindow: InfoWindow(
              title: "${item['ccbaMnm1']}",
              snippet: "${item['ccbaAdmin']}",
              onTap: () {
                Get.to(TreasureDetail(ccbaAsno: ccbaAsno, ccbaCtcd: ccbaCtcd));
              }),
          position: LatLng(
              double.parse(item['latitude']), double.parse(item['longitude'])),
          icon: customMarkerIcon,
          onTap: () async {
            List<dynamic> coordinatesData = await LoadPositions(
                lng1.toDouble(),
                lat1.toDouble(),
                double.parse(item['longitude']),
                double.parse(item['latitude']));
            List<List<double>> newData = coordinatesData
                .map<List<double>>((e) => List<double>.from(e))
                .toList();
            List<LatLng> positions =
                newData.map((e) => LatLng(e[1], e[0])).toList();
            polylines.value = {
              (Polyline(
                polylineId: PolylineId("1"),
                points: positions,
                width: 5,
                color: Color.fromRGBO(255, 0, 0, 0.5),
                patterns: [PatternItem.dash(10), PatternItem.gap(10)],
              ))
            };
          });
      tempMarkers.add(marker);
    }
    markers = tempMarkers;
    return markers;
  }
}
