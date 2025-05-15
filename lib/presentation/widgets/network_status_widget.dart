import 'package:flutter/material.dart';
import '../../core/network/connectivity_service.dart';
import '../../di/injection_container.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  final ConnectivityService _connectivityService = sl<ConnectivityService>();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _listenForConnectivityChanges();
  }

  Future<void> _checkInitialConnection() async {
    final isConnected = await _connectivityService.isConnected;
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  void _listenForConnectivityChanges() {
    _connectivityService.connectionStatusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink(); // 在线时不显示任何内容
    }

    return Container(
      width: double.infinity,
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(
            '离线模式 - 数据将在恢复连接后同步',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
