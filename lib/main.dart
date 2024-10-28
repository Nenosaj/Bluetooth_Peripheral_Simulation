import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';  // Import the permission handler
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Peripheral Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BLEPeripheralSimulator(),
    );
  }
}

class BLEPeripheralSimulator extends StatefulWidget {
  @override
  _BLEPeripheralSimulatorState createState() => _BLEPeripheralSimulatorState();
}

class _BLEPeripheralSimulatorState extends State<BLEPeripheralSimulator> {
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  String status = "Stopped";
  Timer? _timer;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    print("App started. Checking permissions...");
    _checkPermissions();  // Check and request permissions on app start
  }

  // Function to check and request Bluetooth permissions
  Future<void> _checkPermissions() async {
    if (await Permission.bluetooth.isGranted && 
        await Permission.bluetoothAdvertise.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      print("All permissions granted. Starting advertising...");
      _startAdvertising();
    } else {
      print("Requesting permissions...");
      await [
        Permission.bluetoothAdvertise,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      print("Permissions granted. Starting advertising...");
      _startAdvertising();  // Start advertising once permissions are granted
    }
  }

  // Function to start BLE advertising
 void _startAdvertising() {
  print("Starting BLE advertising...");
  
  // Initial advertising
  int heartRate = _generateHeartRate();
  int stressLevel = _generateStressLevel();
  
  Uint8List manufacturerData = Uint8List.fromList([heartRate & 0xFF, stressLevel & 0xFF]);

  // Initial advertisement data
  final AdvertiseData advertiseData = AdvertiseData(
    includeDeviceName: false,  // Exclude device name to reduce payload
    manufacturerId: 1234,      // Example manufacturer ID
    manufacturerData: manufacturerData,  // Compact 2-byte data (heart rate, stress level)
    serviceUuid: '1234',       // Use a 16-bit UUID to further reduce size
  );

  blePeripheral.start(advertiseData: advertiseData).then((_) {
    setState(() {
      status = "Advertising";
    });
    print("Advertising started with heartRate: $heartRate, stressLevel: $stressLevel");

    // Update advertisement every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      heartRate = _generateHeartRate();
      stressLevel = _generateStressLevel();
      
      // Update manufacturerData with the new values
      manufacturerData = Uint8List.fromList([heartRate & 0xFF, stressLevel & 0xFF]);

      // Updated advertisement data with the same size limits
      final updatedAdvertiseData = AdvertiseData(
        includeDeviceName: false,  // Keep device name off for size efficiency
        manufacturerId: 1234,
        manufacturerData: manufacturerData,
        serviceUuid: '1234',       // Stick with the compact 16-bit UUID
      );

      // Restart advertising with updated data
      blePeripheral.start(advertiseData: updatedAdvertiseData);
      print('Updated advertising with heartRate: $heartRate, stressLevel: $stressLevel');
    });
  }).catchError((error) {
    setState(() {
      status = "Error: $error";
    });
    print("Error starting advertising: $error");
  });
}

  int _generateHeartRate() {
    int heartRate = 70 + random.nextInt(51);  // Generates a value between 70 and 120
    print("Generated heartRate: $heartRate");
    return heartRate;
  }

  int _generateStressLevel() {
    int stressLevel = 2 + random.nextInt(69);   // Generates a value between 2 and 70
    print("Generated stressLevel: $stressLevel");
    return stressLevel;
  }

  @override
  void dispose() {
    _timer?.cancel();  // Stop the timer if active
    blePeripheral.stop();  // Stop BLE advertising when the app is closed
    print("App is closing. Stopped advertising.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Peripheral Simulator'),
      ),
      body: Center(
        child: Text('BLE Status: $status'),
      ),
    );
  }
}
