import 'package:get/get.dart';
import 'package:ble_for_cycle_test/model/connection_info/device_list.dart';
import 'package:ble_for_cycle_test/model/connection_info/service_list.dart';

/// Setting Controller
class SettingController extends GetxController {
  String selectedUuidValue = uuidList[0];
  String selectedCharRxValue = charRxList[0];
  String selectedCharTxValue = charTxList[0];
  String selectedDeviceName = deviceNameList[0];
  int selectedType = -1;

  onChange(String title, String value) {
    switch (title) {
      case 'SERVICE_UUID':
        selectedUuidValue = value;
        break;
      case 'CHARACTERISTIC_UUID_RX':
        selectedCharRxValue = value;
        break;
      case 'CHARACTERISTIC_UUID_TX':
        selectedCharTxValue = value;
        break;
      case 'DEVICE_NAME':
        selectedDeviceName = value;
        break;
      default: // for safety
        break;
    }
    update();
  }

  void findList(String title) {
    int temp = cycleList.indexWhere((element) => element.contains(selectedDeviceName));
    if (temp != -1) {
      selectedType = 4;
      return;
    }
  }

  String findName(int num) {
    switch (num) {
      case 0:
        return "사이클";
      default:
        return "등록되지 않은 운동!";
    }
  }
}