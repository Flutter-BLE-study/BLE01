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
  // 타겟 디바이스 해당 보드의 값 -> 해당 CYCLE_TEST만을 연결하기 위해 필요
  final String SERVICE_UUID =           "82e5f314-f248-4c9d-b802-385aa7fcaf24";
  final String TARGET_DEVICE_NAME =     "CYCLE_TEST";

  // var cycleModel = CycleModel(total: 0, speed: 0).obs; // for safety
  //
  // // ESPController의 역할
  // void espInit() {
  //   cycleModel.value = CycleModel(total: 0, speed: 0);
  // }

  // Obtain an instance for FlutterBlue
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  bool isDevice = false;
  bool isConnected = false;

  late List<ScanResult> scanResult; // Bluetooth Device Scan List
  late BluetoothDevice targetDevice;

  String connectionText = "No connection";
  String receivedValue ="";

  double speed = 0.0;
  double total = 0.0;


  // Scan을 시작함 List에 넣기만 하는 함수.
  Future<void> startScan() async {
    print("Start Scan!");
    setState(() {
      connectionText = "Start Scanning";
    });

    // 3초간 스캔 진행함
    flutterBlue.startScan(timeout: const Duration(seconds:3), allowDuplicates: false);

    // Scan이 시작되는 동안에 받는 listener 관련 액션을 수행함.
    flutterBlue.scanResults.listen((results) {
    },onError: (e) =>print(e)
    ).onData((data) {
      print(data.length);
      scanResult = data;});
    // Stop scanning
    flutterBlue.stopScan();
    Future.delayed(const Duration(seconds: 5) , (){scanDevice();});

  }

  // 검색된 Device 중 지정해둔 Device 검색
  Future<void> scanDevice() async {
    for (ScanResult r in scanResult) {
      // 이 Device가 앞서 지정해둔 "CYCLE_TEST"와 같은지
      if (r.device.name == TARGET_DEVICE_NAME) {
        // 연결되었다면
        if (!isConnected) {
          // 해당 Device 정보를 변수 targetDevice에 저장
          targetDevice = r.device;
          // Device Connect를 여기서 함.
          await connectToDevice(targetDevice);
        }
      }
    }
  }

  // 디바이스 연결
  Future<void> connectToDevice(BluetoothDevice device) async {
    print('*****.....CONNECTING.....*****');
    setState(() {
      connectionText = "Connect To Device";
    });
    if (device == null) return;

    if (!isConnected) {
      await device.connect();
      isConnected = true;
      isDevice = true;
      print('*****DEVICE CONNECTED*****');
      await discoverServices(device);
    }
  }

  // 연결을 끊는 부분
  disconnectFromDevice() {
    if (targetDevice == null) {
      print("No Device");
      return;
    }
    targetDevice.disconnect();
    flutterBlue = FlutterBluePlus.instance;

    setState(() {
      isDevice = false;
      isConnected = false;
      connectionText = "Device Disconnected";
    });
  }

  // 필요한 값들(서비스, 캐릭터리스틱 등)을 세팅
  Future<void> discoverServices(BluetoothDevice device) async {
    if (device == null) return;

    print("*****DISCOVER SERVICES*****");

    // 서비스 리스트 중 내 기기에 맞는 것을 찾아야함.
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          print(characteristic.uuid);

          characteristic.setNotifyValue(true);

          characteristic.value.listen((value) {
            if (value.length >0) {
              receivedValue=value[0].toString(); // 캐리터리스틱을 통해 얻어온 값들을 가져오고
              // 1. value값을 String.fromCharCodes을 통해 정수형 배열을 문자열로 파싱
              // 2. CycleModel.fromString으로 total:0.0/speed:0.0을 변수 total과 speed에 각각 저장
              List<String> temp = String.fromCharCodes(value).split("/");
              total = double.parse(temp[0].split(":")[1]);
              speed = double.parse(temp[1].split(":")[1]);
              print("**[$receivedValue]**");
            }
            setState(() {}); // UI State에서 변경 사항이 있음을 Flutter Framework에 알려주는 역할을 함.UI에 변경된 값이 반영되도록 build 메소드가 다시 실행 UI 에 변경된 값이 반영될 수 있도록 build 메소드가 다시 실행
          });
        });
      }
    });
  }

  // 화면 구성 내용
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter BLE study'),
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
              Text('Device Name :[${targetDevice.name}]\nDevice total :[$total]\nDevice speed :[$speed]', style: const TextStyle(color: Colors.purple,fontSize: 20.0, fontWeight: FontWeight.bold))
                  : const Text('[No Device Info]', style: TextStyle(color: Colors.purple,fontSize: 20.0, fontWeight: FontWeight.bold))
            ],
          ),
        ],
      ),
    );
  }
}