import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Connect',
      home: ESPTest(),
    );
  }
}

class ESPTest extends StatefulWidget {
  @override
  _ESPTestState createState() => _ESPTestState();
}

class _ESPTestState extends State<ESPTest> {
  final String SERVICE_UUID =           "82e5f314-f248-4c9d-b802-385aa7fcaf24";
  final String CHARACTERISTIC_UUID_RX = "b203f809-4542-47d2-a3b3-b662074bd171";
  final String CHARACTERISTIC_UUID_TX = "25c48cde-1b14-4975-b95a-ebe47cf76aec";
  final String TARGET_DEVICE_NAME =     "CYCLE_TEST";

  var cycleModel = CycleModel(total: 0, speed: 0).obs; // for safety

  void espInit() {
    //cardioModel.value = CardioModel(total: 0, speed: 0, level: 0);
    cycleModel.value = CycleModel(total: 0, speed: 0);
    //range.value = 0;
    //weight.value = 0;
    //face.value = 0.0;
  }

  //EspController espController = Get.find<EspController>();

  // 메시지를 보내기 위한 컨트롤러
  TextEditingController msgController = TextEditingController();

  // Obtain an instance for FlutterBlue
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  bool isDevice = false;
  bool isConnected = false;

  late List<ScanResult> scanResult; // Bluetooth Device Scan List

  late BluetoothDevice targetDevice;
  late BluetoothCharacteristic targetCharacteristicRx;
  late BluetoothCharacteristic targetCharacteristicTx;

  String connectionText = "No connection";
  String receivedValue ="";

  // Scan을 시작함. List에 넣기만 하는 함수.
  Future<void> startScan() async {
    print("Start Scan!");
    setState(() {
      connectionText = "Start Scanning";
    });

    // Start scanning 3초간 진행됨.
    flutterBlue.startScan(timeout: const Duration(seconds:3), allowDuplicates: false);

    // Scan이 시작되는 동안에 받는 listener 관련 액션을 수행함.
    flutterBlue.scanResults.listen((results) {
    },onError: (e) =>print(e)
    ).onData((data) {
      print(data.length);
      scanResult = data;});
    // Stop scanning
    flutterBlue.stopScan();
    Future.delayed(const Duration(seconds: 5) , (){print("5초기다림ㅋ Listen 끝!"); scanDevice();});

  }

  // Scan List에 있는 Device들 중, 내가 원하는 Device를 찾는 함수
  Future<void> scanDevice() async {
    for (ScanResult r in scanResult) {
      //print('${r.device.name} detected! / rssi: ${r.rssi}');
      if (r.device.name == TARGET_DEVICE_NAME)
      {
        print("Target : ${r.device.name} Found!");
        if (!isConnected) {
          targetDevice = r.device;
          print("*****************Target Device Info*******************\nTarget Device:$targetDevice");
          // Device Connect를 여기서 함.
          await connectToDevice(targetDevice);
        }
      }
    }
  }

  // 디바이스 연결을 위한 함수
  Future<void> connectToDevice(BluetoothDevice device) async {
    print('*******************.....CONNECTING.....*********************');
    setState(() {
      connectionText = "Connect To Device";
    });
    if (device == null) return;

    if (!isConnected) {
      await device.connect();
      isConnected = true;
      isDevice = true;
      print('*********************DEVICE CONNECTED*********************');
      await discoverServices(device);
    }
  }

  disconnectFromDevice() {
    if (targetDevice == null) {
      print("No Device");
      return;
    }
    targetCharacteristicTx.setNotifyValue(false);
    targetDevice.disconnect();
    flutterBlue = FlutterBluePlus.instance;

    setState(() {
      isDevice = false;
      isConnected = false;
      connectionText = "Device Disconnected";
    });
  }

  // 필요한 값들(서비스, 캐릭터리스틱 등)을 셋팅해줌
  Future<void> discoverServices(BluetoothDevice device) async {
    if (device == null) return;

    print("******************DISCOVER SERVICES**************************");

    // 서비스 리스트 중 내 기기에 맞는걸? 찾아야함.
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          print(characteristic.uuid);
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID_RX) {
            print("RX 감지덕지");
            targetCharacteristicRx = characteristic;
          }
          else if (characteristic.uuid.toString() == CHARACTERISTIC_UUID_TX) {
            print("TX 감지");
            targetCharacteristicTx = characteristic;

            characteristic.setNotifyValue(true);

            /*
            characteristic.value.listen((value) async{
              cycleModel.value = CycleModel.fromString(String.fromCharCodes(value)); // discover_services
              setState(() {});
            });
             */

            characteristic.value.listen((value) {
              if (value.length >0) {
                receivedValue=value[0].toString();
                cycleModel.value = CycleModel.fromString(String.fromCharCodes(value)); // discover_services
                print("**[$receivedValue]**");
              }
              setState(() {});
            });


          }
        });
      }
    });
  }

  writeData(String data) async {
    if (targetCharacteristicRx == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristicRx.write(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Connection Test'),//Text(connectionText),
        actions: [
          IconButton(onPressed: () async {await startScan();}, icon: const Icon(Icons.search))
        ],
        leading: IconButton(onPressed: () async {await disconnectFromDevice();}, icon: const Icon(Icons.cancel)),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Current Status:', style: TextStyle(color: Colors.black,fontSize: 20.0)),
              Text('[$connectionText]', style: const TextStyle(color: Colors.red,fontSize: 20.0, fontWeight: FontWeight.bold))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Device Info:', style: TextStyle(color: Colors.black,fontSize: 20.0)),
              (isDevice) ?
              Text('Device Name :[${targetDevice.name}]\nDevice total :[${cycleModel.value.total}]\nDevice speed :[${cycleModel.value.speed}]', style: const TextStyle(color: Colors.purple,fontSize: 20.0, fontWeight: FontWeight.bold))
                  : const Text('[No Device Info]', style: TextStyle(color: Colors.purple,fontSize: 20.0, fontWeight: FontWeight.bold))
            ],
          ),
          Expanded(child: Text("${receivedValue}", style: const TextStyle(color: Colors.red,fontSize: 20.0, fontWeight: FontWeight.bold))),
          sendMessageArea()
        ],
      ),
    );
  }


  // 메시지 전송을 위한 위젯
  Widget sendMessageArea() {
    return Card(
      child: ListTile(
        title: TextField(
          controller: msgController,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          color: Colors.blue,
          disabledColor: Colors.grey,
          onPressed: (isConnected) ? sendMessage : null,
        ),
      ),
    );
  }

  // 메시지 전송 처리
  void sendMessage() {
    writeData(msgController.text);
    msgController.clear();
  }
}

/// 유산소 모델 (보드에서 주는 정보)
class CycleModel {
  // total:69.30/speed:6.20
  double total; // 총 운동 거리(km)
  double speed; // 현재 속도(m/s)

  CycleModel({
    required this.total,
    required this.speed,
  });

  factory CycleModel.fromString(String msg) {
    List<String> splitMsg = msg.split("/");
    return CycleModel(
      total: double.parse(splitMsg[0].split(":")[1]),
      speed: double.parse(splitMsg[1].split(":")[1]),
    );
  }

  @override
  String toString() {
    return
      '''[total]:$total [speed]:$speed
''';
  }
}

