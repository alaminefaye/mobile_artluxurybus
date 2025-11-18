import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../services/device_info_service.dart';
import '../services/translation_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  Map<String, dynamic>? _deviceInfo;
  bool _isLoading = true;
  String _appVersion = '1.0.2';
  String _buildNumber = '7';

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  // Fonction helper pour obtenir la couleur primaire selon le thème
  // Orange en mode dark, bleu en mode light
  Color _getPrimaryColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;
  }

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      // Charger les informations de version
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }

      // Charger les informations de l'appareil
      final info = await _deviceInfoService.getDeviceInfo();
      if (mounted) {
        setState(() {
          _deviceInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(t('about.copied_to_clipboard').replaceAll('{{label}}', label)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t('about.title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo et nom de l'app
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t('about.app_name'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t('about.version').replaceAll('{{version}}',
                                '$_appVersion (Build $_buildNumber)'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Informations de l'appareil
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.smartphone,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t('about.device_info'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_deviceInfo != null) ...[
                          // Device ID (le plus important)
                          _buildInfoRow(
                            icon: Icons.fingerprint,
                            label: t('about.unique_id'),
                            value: _deviceInfo!['device_id'] ?? 'N/A',
                            isHighlighted: true,
                            primaryColor: primaryColor,
                            onCopy: () => _copyToClipboard(
                              _deviceInfo!['device_id'] ?? '',
                              t('about.unique_id'),
                            ),
                          ),
                          const Divider(height: 24),

                          // UUID unique de l'installation
                          _buildInfoRow(
                            icon: Icons.vpn_key,
                            label: 'UUID Installation',
                            value: _deviceInfo!['uuid'] ?? 'N/A',
                            isHighlighted: true,
                            primaryColor: primaryColor,
                            onCopy: () => _copyToClipboard(
                              _deviceInfo!['uuid'] ?? '',
                              'UUID Installation',
                            ),
                          ),
                          const Divider(height: 24),

                          // Nom de l'appareil
                          _buildInfoRow(
                            icon: Icons.phone_android,
                            label: t('about.device_name'),
                            value: _deviceInfo!['device_name'] ?? 'N/A',
                            primaryColor: primaryColor,
                          ),
                          const Divider(height: 24),

                          // Type
                          _buildInfoRow(
                            icon: Icons.category,
                            label: t('about.type'),
                            value: (_deviceInfo!['device_type'] ?? 'N/A')
                                .toString()
                                .toUpperCase(),
                            primaryColor: primaryColor,
                          ),
                          const Divider(height: 24),

                          // Modèle
                          _buildInfoRow(
                            icon: Icons.devices,
                            label: t('about.model'),
                            value: _deviceInfo!['model'] ?? 'N/A',
                            primaryColor: primaryColor,
                          ),

                          // Informations supplémentaires selon la plateforme
                          if (_deviceInfo!['brand'] != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              icon: Icons.business,
                              label: t('about.brand'),
                              value: _deviceInfo!['brand'],
                              primaryColor: primaryColor,
                            ),
                          ],

                          if (_deviceInfo!['manufacturer'] != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              icon: Icons.factory,
                              label: t('about.manufacturer'),
                              value: _deviceInfo!['manufacturer'],
                              primaryColor: primaryColor,
                            ),
                          ],

                          if (_deviceInfo!['android_version'] != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              icon: Icons.android,
                              label: t('about.android_version'),
                              value: _deviceInfo!['android_version'],
                              primaryColor: primaryColor,
                            ),
                          ],

                          if (_deviceInfo!['system_version'] != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              icon: Icons.apple,
                              label: t('about.ios_version'),
                              value: _deviceInfo!['system_version'],
                              primaryColor: primaryColor,
                            ),
                          ],
                        ] else
                          Center(
                            child: Text(t('about.loading_error')),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description de l'app
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withValues(alpha: 0.1),
                          primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t('about.app_about'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t('about.app_description'),
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Copyright
                  Center(
                    child: Text(
                      t('about.copyright'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    bool isHighlighted = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isHighlighted
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isHighlighted
                ? primaryColor
                : Theme.of(context).iconTheme.color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isHighlighted ? FontWeight.bold : FontWeight.w600,
                        color: isHighlighted
                            ? primaryColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  if (onCopy != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: onCopy,
                      color: primaryColor,
                      tooltip: t('about.copy'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
