import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  late TextEditingController _forwardController;
  late TextEditingController _backwardController;
  late TextEditingController _leftController;
  late TextEditingController _rightController;
  late TextEditingController _stopController;
  late TextEditingController _lightsOnController;
  late TextEditingController _lightsOffController;
  late TextEditingController _hornOnController;
  late TextEditingController _hornOffController;
  late TextEditingController _speedController;
  late TextEditingController _gripperOpenController;
  late TextEditingController _gripperCloseController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = _settingsService.settings;
    _forwardController = TextEditingController(text: settings.joystickForward);
    _backwardController = TextEditingController(text: settings.joystickBackward);
    _leftController = TextEditingController(text: settings.joystickLeft);
    _rightController = TextEditingController(text: settings.joystickRight);
    _stopController = TextEditingController(text: settings.joystickStop);
    _lightsOnController = TextEditingController(text: settings.lightsOnCommand);
    _lightsOffController = TextEditingController(text: settings.lightsOffCommand);
    _hornOnController = TextEditingController(text: settings.hornOnCommand);
    _hornOffController = TextEditingController(text: settings.hornOffCommand);
    _speedController = TextEditingController(text: settings.speedCommand);
    _gripperOpenController = TextEditingController(text: settings.gripperOpenCommand);
    _gripperCloseController = TextEditingController(text: settings.gripperCloseCommand);
  }

  @override
  void dispose() {
    _forwardController.dispose();
    _backwardController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    _stopController.dispose();
    _lightsOnController.dispose();
    _lightsOffController.dispose();
    _hornOnController.dispose();
    _hornOffController.dispose();
    _speedController.dispose();
    _gripperOpenController.dispose();
    _gripperCloseController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveSettings() async {
    final newSettings = CommandSettings(
      joystickForward: _forwardController.text,
      joystickBackward: _backwardController.text,
      joystickLeft: _leftController.text,
      joystickRight: _rightController.text,
      joystickStop: _stopController.text,
      lightsOnCommand: _lightsOnController.text,
      lightsOffCommand: _lightsOffController.text,
      hornOnCommand: _hornOnController.text,
      hornOffCommand: _hornOffController.text,
      speedCommand: _speedController.text,
      gripperOpenCommand: _gripperOpenController.text,
      gripperCloseCommand: _gripperCloseController.text,
    );
    await _settingsService.updateSettings(newSettings);
    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SETTINGS SAVED', style: GoogleFonts.manrope()), backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: Text('RESET TO DEFAULTS?', style: GoogleFonts.spaceGrotesk(color: Theme.of(context).colorScheme.primary)),
        content: Text('ALL COMMAND SETTINGS WILL BE RESET.', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('RESET', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (confirmed == true) {
      await _settingsService.resetToDefaults();
      _forwardController.dispose(); _backwardController.dispose(); _leftController.dispose(); _rightController.dispose(); _stopController.dispose();
      _lightsOnController.dispose(); _lightsOffController.dispose(); _hornOnController.dispose(); _hornOffController.dispose(); _speedController.dispose();
      _gripperOpenController.dispose(); _gripperCloseController.dispose();
      _initControllers();
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('RESET COMPLETE', style: GoogleFonts.manrope()), backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.primary), onPressed: () => Navigator.pop(context)),
        title: Text('COMMAND SETTINGS', style: GoogleFonts.spaceGrotesk(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          if (_hasChanges) IconButton(icon: Icon(Icons.save, color: colors.secondary), onPressed: _saveSettings, tooltip: 'SAVE'),
          IconButton(icon: Icon(Icons.restore, color: Colors.orange), onPressed: _resetToDefaults, tooltip: 'RESET'),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.surfaceContainer, colors.surface])),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(colors),
            const SizedBox(height: 20),
            _buildSectionHeader('DIRECTIONS', Icons.gamepad, colors),
            _buildSettingField(controller: _forwardController, label: 'FORWARD', hint: 'FORWARD COMMAND', icon: Icons.arrow_upward, colors: colors),
            _buildSettingField(controller: _backwardController, label: 'BACKWARD', hint: 'BACKWARD COMMAND', icon: Icons.arrow_downward, colors: colors),
            _buildSettingField(controller: _leftController, label: 'LEFT', hint: 'LEFT COMMAND', icon: Icons.arrow_back, colors: colors),
            _buildSettingField(controller: _rightController, label: 'RIGHT', hint: 'RIGHT COMMAND', icon: Icons.arrow_forward, colors: colors),
            _buildSettingField(controller: _stopController, label: 'STOP', hint: 'STOP COMMAND', icon: Icons.stop_circle_outlined, colors: colors),
            const SizedBox(height: 24),
            _buildSectionHeader('LIGHTS', Icons.lightbulb_outline, colors),
            _buildSettingField(controller: _lightsOnController, label: 'LIGHTS ON', hint: 'LIGHTS ON COMMAND', icon: Icons.lightbulb, colors: colors),
            _buildSettingField(controller: _lightsOffController, label: 'LIGHTS OFF', hint: 'LIGHTS OFF COMMAND', icon: Icons.lightbulb_outline, colors: colors),
            const SizedBox(height: 24),
            _buildSectionHeader('HORN', Icons.volume_up, colors),
            _buildSettingField(controller: _hornOnController, label: 'HORN ON', hint: 'HORN ON COMMAND', icon: Icons.volume_up, colors: colors),
            _buildSettingField(controller: _hornOffController, label: 'HORN OFF', hint: 'HORN OFF COMMAND', icon: Icons.volume_off, colors: colors),
            const SizedBox(height: 24),
            _buildSectionHeader('SPEED', Icons.speed, colors),
            _buildSettingField(controller: _speedController, label: 'SPEED', hint: 'USE {LEVEL} AS PLACEHOLDER', icon: Icons.speed, colors: colors),
            const SizedBox(height: 24),
            _buildSectionHeader('GRIPPER', Icons.pan_tool, colors),
            _buildSettingField(controller: _gripperOpenController, label: 'GRIPPER OPEN', hint: 'OPEN COMMAND', icon: Icons.pan_tool, colors: colors),
            _buildSettingField(controller: _gripperCloseController, label: 'GRIPPER CLOSE', hint: 'CLOSE COMMAND', icon: Icons.front_hand, colors: colors),
            const SizedBox(height: 40),
            _buildSaveButton(colors),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text('CUSTOMIZE DATA SENT TO ROBOT. EACH DIRECTION HAS ITS OWN COMMAND.', style: GoogleFonts.manrope(color: colors.onSurfaceVariant, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: colors.secondary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.spaceGrotesk(color: colors.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildSettingField({required TextEditingController controller, required String label, required String hint, required IconData icon, required ColorScheme colors}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outline.withOpacity(0.2))),
      child: TextField(
        controller: controller,
        onChanged: (_) => _markChanged(),
        style: GoogleFonts.sourceCodePro(color: colors.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.manrope(color: colors.onSurfaceVariant, fontSize: 11),
          hintText: hint,
          hintStyle: GoogleFonts.manrope(color: colors.outline, fontSize: 11),
          prefixIcon: Icon(icon, color: colors.onSurfaceVariant, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme colors) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: _hasChanges ? [colors.secondary, const Color(0xFF00aa00)] : [colors.surfaceContainerHighest, colors.surfaceContainer]),
        boxShadow: _hasChanges ? [BoxShadow(color: colors.secondary.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)] : null,
      ),
      child: ElevatedButton(
        onPressed: _hasChanges ? _saveSettings : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: _hasChanges ? colors.surface : colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Text('SAVE SETTINGS', style: GoogleFonts.spaceGrotesk(color: _hasChanges ? colors.surface : colors.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}