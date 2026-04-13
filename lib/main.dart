import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ble_service.dart';
import 'settings_service.dart';
import 'settings_screen.dart';

class BleConfig {
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().loadSettings();
  runApp(const RobotControllerApp());
}

class RobotControllerApp extends StatelessWidget {
  const RobotControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ControlRobot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0e14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF81ecff),
          secondary: Color(0xFFafefdd),
          surface: Color(0xFF0a0e14),
          surfaceContainerLow: Color(0xFF0f141c),
          surfaceContainer: Color(0xFF151a21),
          surfaceContainerHighest: Color(0xFF20262f),
          onSurface: Color(0xFFf1f3fc),
          onSurfaceVariant: Color(0xFF8892a0),
          outline: Color(0xFF44484f),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0a0e14),
          elevation: 0,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF81ecff),
            fontWeight: FontWeight.bold,
          ),
          displayMedium: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFf1f3fc),
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFf1f3fc),
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFf1f3fc),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.manrope(color: const Color(0xFFf1f3fc)),
          bodyMedium: GoogleFonts.manrope(color: const Color(0xFF8892a0)),
          labelSmall: GoogleFonts.manrope(
            color: const Color(0xFF8892a0),
            letterSpacing: 0.1,
            fontSize: 11,
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ConnectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, const Color(0xFF00e3fd)],
                      ),
                    ),
                    child: const Icon(Icons.smart_toy_outlined, size: 50, color: Color(0xFF003840)),
                  ),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    'CONTROL ROBOT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    'V1.0.0',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      minHeight: 3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final BleService _bleService = BleService();
  List<BleDeviceInfo> _scanResults = [];
  bool _isScanning = false;
  BleDeviceInfo? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _bleService.initialize();
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  void _startScan() async {
    if (_isScanning) return;
    setState(() {
      _scanResults = [];
      _isScanning = true;
    });
    try {
      await for (final results in _bleService.scan()) {
        if (mounted) setState(() => _scanResults = results);
      }
    } catch (e) {
      _showSnackBar('ERROR: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _stopScan() {
    _bleService.stopScan();
    setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(BleDeviceInfo device) async {
    _showSnackBar('CONNECTING TO ${device.name}...');
    try {
      final connected = await _bleService.connect(device);
      if (connected) {
        setState(() => _connectedDevice = device);
        _showSnackBar('CONNECTED TO ${device.name}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CockpitScreen(bleService: _bleService, deviceName: device.name),
            ),
          ).then((_) {
            _bleService.disconnect();
            setState(() => _connectedDevice = null);
          });
        }
      } else {
        _showSnackBar('CONNECTION FAILED');
      }
    } catch (e) {
      _showSnackBar('ERROR: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.manrope()),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ROBOT LINK',
          style: GoogleFonts.spaceGrotesk(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 3),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colors.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceContainer, colors.surface],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildStatusIndicator(colors),
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildScanButton(colors)),
            const SizedBox(height: 20),
            Expanded(child: _buildDeviceList(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isScanning ? colors.primary : (_connectedDevice != null ? colors.secondary : colors.outline.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isScanning ? colors.primary : (_connectedDevice != null ? colors.secondary : colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isScanning ? 'SCANNING...' : (_connectedDevice != null ? 'CONNECTED' : 'DISCONNECTED'),
            style: GoogleFonts.spaceGrotesk(
              color: _isScanning ? colors.primary : (_connectedDevice != null ? colors.secondary : colors.onSurfaceVariant),
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(ColorScheme colors) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isScanning 
              ? [colors.surfaceContainerHighest, colors.surfaceContainer]
              : [colors.primary, const Color(0xFF00e3fd)],
        ),
        boxShadow: _isScanning ? null : [
          BoxShadow(color: colors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 1),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isScanning ? _stopScan : _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else
              Icon(Icons.bluetooth_searching, color: const Color(0xFF003840), size: 22),
            const SizedBox(width: 12),
            Text(
              _isScanning ? 'STOP SCAN' : 'SCAN DEVICES',
              style: GoogleFonts.spaceGrotesk(color: _isScanning ? colors.onSurface : const Color(0xFF003840), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  bool _isMyEsp(BleDeviceInfo device) {
    if (device.serviceUuids.any((uuid) => uuid.toLowerCase() == BleConfig.serviceUuid.toLowerCase())) return true;
    final name = device.name.toLowerCase();
    return name.contains('esp32') || name.contains('robot') || name.contains('omar');
  }

  Widget _buildDeviceList(ColorScheme colors) {
    if (_scanResults.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 60, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('NO DEVICES FOUND', style: GoogleFonts.spaceGrotesk(color: colors.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 8),
            Text('TAP SCAN TO SEARCH', style: GoogleFonts.manrope(color: colors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
    }
    final myDevices = _scanResults.where((d) => _isMyEsp(d)).toList();
    final otherDevices = _scanResults.where((d) => !_isMyEsp(d)).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (myDevices.isNotEmpty) ...[
          _buildSectionHeader('MY ROBOT', colors),
          ...myDevices.map((d) => _buildDeviceCard(d, colors)),
        ],
        if (otherDevices.isNotEmpty) ...[
          _buildSectionHeader('OTHER DEVICES', colors),
          ...otherDevices.map((d) => _buildDeviceCard(d, colors)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: GoogleFonts.spaceGrotesk(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
    );
  }

  Widget _buildDeviceCard(BleDeviceInfo device, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.bluetooth, color: colors.primary),
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'UNKNOWN',
          style: GoogleFonts.spaceGrotesk(color: colors.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text('${device.rssi} DBM', style: GoogleFonts.manrope(color: colors.onSurfaceVariant, fontSize: 11)),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(device),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondary.withOpacity(0.2),
            foregroundColor: colors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colors.secondary)),
          ),
          child: Text('LINK', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
    );
  }
}

class CustomButtonData {
  String label;
  String command;
  CustomButtonData({required this.label, required this.command});
}

class CockpitScreen extends StatefulWidget {
  final BleService bleService;
  final String deviceName;
  const CockpitScreen({super.key, required this.bleService, required this.deviceName});

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  bool _isConnected = true;
  final SettingsService _settingsService = SettingsService();
  String _direction = 'STOP';
  int _speedMode = 1;
  bool _lightsOn = false;
  bool _gripperOpen = true;
  bool _showTerminal = false;
  final List<String> _terminalLogs = [];
  final ScrollController _terminalScrollController = ScrollController();
  List<CustomButtonData> _customButtons = [
    CustomButtonData(label: 'BTN1', command: 'CMD1'),
    CustomButtonData(label: 'BTN2', command: 'CMD2'),
    CustomButtonData(label: 'BTN3', command: 'CMD3'),
  ];

  Future<void> writeData(String data) async {
    if (!_isConnected) {
      _logToTerminal('ERROR: NOT CONNECTED');
      return;
    }
    try {
      await widget.bleService.sendData(data);
      _logToTerminal('TX: ${data.trim()}');
    } catch (e) {
      _logToTerminal('ERROR: $e');
      setState(() => _isConnected = false);
    }
  }

  void _logToTerminal(String message) {
    if (!mounted) return;
    setState(() {
      _terminalLogs.add(message);
      if (_terminalLogs.length > 50) _terminalLogs.removeAt(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(_terminalScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    });
  }

  void _sendDirection(String dir) {
    HapticFeedback.lightImpact();
    setState(() => _direction = dir);
    final settings = _settingsService.settings;
    String cmd;
    switch (dir) {
      case 'FORWARD': cmd = settings.joystickForward; break;
      case 'BACKWARD': cmd = settings.joystickBackward; break;
      case 'LEFT': cmd = settings.joystickLeft; break;
      case 'RIGHT': cmd = settings.joystickRight; break;
      default: cmd = settings.joystickStop; break;
    }
    writeData(cmd);
  }

  void _onDirectionRelease() {
    if (_direction != 'STOP') {
      setState(() => _direction = 'STOP');
      writeData(_settingsService.settings.joystickStop);
    }
  }

  void _cycleSpeedMode() {
    HapticFeedback.mediumImpact();
    setState(() => _speedMode = (_speedMode % 3) + 1);
    writeData(_settingsService.settings.formatSpeed(_speedMode));
  }

  void _toggleLights() {
    HapticFeedback.lightImpact();
    setState(() => _lightsOn = !_lightsOn);
    final settings = _settingsService.settings;
    writeData(_lightsOn ? settings.lightsOnCommand : settings.lightsOffCommand);
  }

  void _toggleGripper() {
    HapticFeedback.lightImpact();
    setState(() => _gripperOpen = !_gripperOpen);
    final settings = _settingsService.settings;
    writeData(_gripperOpen ? settings.gripperOpenCommand : settings.gripperCloseCommand);
  }

  void _onCustomButtonPressed(int index) {
    HapticFeedback.mediumImpact();
    final btn = _customButtons[index];
    writeData('${btn.command}\n');
  }

  void _showEditButtonDialog(int index) {
    final btn = _customButtons[index];
    final labelController = TextEditingController(text: btn.label);
    final cmdController = TextEditingController(text: btn.command);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: Text('EDIT BUTTON ${index + 1}', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: InputDecoration(labelText: 'LABEL', labelStyle: TextStyle(color: Colors.grey[500])), style: const TextStyle(color: Colors.white)),
            TextField(controller: cmdController, decoration: InputDecoration(labelText: 'COMMAND', labelStyle: TextStyle(color: Colors.grey[500])), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              setState(() => _customButtons[index] = CustomButtonData(label: labelController.text, command: cmdController.text));
              Navigator.pop(context);
            },
            child: Text('SAVE', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.primary), onPressed: () => Navigator.pop(context)),
        title: Text('CONTROL ROBOT', style: GoogleFonts.spaceGrotesk(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 3)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(_showTerminal ? Icons.terminal : Icons.terminal_outlined, color: _showTerminal ? colors.secondary : colors.onSurfaceVariant), onPressed: () => setState(() => _showTerminal = !_showTerminal)),
          _buildConnectionIndicator(colors),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.surfaceContainer, colors.surface])),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildActionButton(icon: _lightsOn ? Icons.lightbulb : Icons.lightbulb_outline, label: 'LIGHTS', isActive: _lightsOn, color: Colors.amber, onTap: _toggleLights),
                    const SizedBox(width: 12),
                    _buildActionButton(icon: Icons.speed, label: 'SPD $_speedMode', isActive: _speedMode > 1, color: colors.secondary, onTap: _cycleSpeedMode),
                    const SizedBox(width: 12),
                    _buildActionButton(icon: _gripperOpen ? Icons.pan_tool : Icons.front_hand, label: 'GRIP', isActive: !_gripperOpen, color: Colors.purple, onTap: _toggleGripper),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: colors.surfaceContainerHighest.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                child: Text('DIRECTION: $_direction', style: GoogleFonts.spaceGrotesk(color: colors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Center(child: _buildDirectionPad(colors))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _buildCustomButton(i, colors)),
                    ],
                  ],
                ),
              ),
              if (_showTerminal)
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.9),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.secondary, width: 1))),
                  child: ListView.builder(
                    controller: _terminalScrollController,
                    itemCount: _terminalLogs.length,
                    itemBuilder: (context, index) => Text(_terminalLogs[index], style: GoogleFonts.sourceCodePro(color: colors.secondary, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (_isConnected ? colors.secondary : Colors.red).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isConnected ? colors.secondary : Colors.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _isConnected ? colors.secondary : Colors.red)),
          const SizedBox(width: 6),
          Text(_isConnected ? 'LINKED' : 'LOST', style: GoogleFonts.spaceGrotesk(color: _isConnected ? colors.secondary : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required bool isActive, required Color color, required VoidCallback onTap}) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? color : colors.outline.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: isActive ? color : colors.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.spaceGrotesk(color: isActive ? color : colors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionPad(ColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTapDown: (_) => _sendDirection('FORWARD'),
          onTapUp: (_) => _onDirectionRelease(),
          onTapCancel: _onDirectionRelease,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _direction == 'FORWARD' ? colors.primary.withOpacity(0.3) : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _direction == 'FORWARD' ? colors.primary : colors.outline.withOpacity(0.3)),
            ),
            child: Icon(Icons.keyboard_arrow_up, size: 40, color: _direction == 'FORWARD' ? colors.primary : colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => _sendDirection('LEFT'),
              onTapUp: (_) => _onDirectionRelease(),
              onTapCancel: _onDirectionRelease,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _direction == 'LEFT' ? colors.primary.withOpacity(0.3) : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _direction == 'LEFT' ? colors.primary : colors.outline.withOpacity(0.3)),
                ),
                child: Icon(Icons.keyboard_arrow_left, size: 40, color: _direction == 'LEFT' ? colors.primary : colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTapDown: (_) => _sendDirection('RIGHT'),
              onTapUp: (_) => _onDirectionRelease(),
              onTapCancel: _onDirectionRelease,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _direction == 'RIGHT' ? colors.primary.withOpacity(0.3) : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _direction == 'RIGHT' ? colors.primary : colors.outline.withOpacity(0.3)),
                ),
                child: Icon(Icons.keyboard_arrow_right, size: 40, color: _direction == 'RIGHT' ? colors.primary : colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTapDown: (_) => _sendDirection('BACKWARD'),
          onTapUp: (_) => _onDirectionRelease(),
          onTapCancel: _onDirectionRelease,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _direction == 'BACKWARD' ? colors.primary.withOpacity(0.3) : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _direction == 'BACKWARD' ? colors.primary : colors.outline.withOpacity(0.3)),
            ),
            child: Icon(Icons.keyboard_arrow_down, size: 40, color: _direction == 'BACKWARD' ? colors.primary : colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomButton(int index, ColorScheme colors) {
    final btn = _customButtons[index];
    return GestureDetector(
      onLongPress: () => _showEditButtonDialog(index),
      child: ElevatedButton(
        onPressed: () => _onCustomButtonPressed(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary.withOpacity(0.2),
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(btn.label, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}