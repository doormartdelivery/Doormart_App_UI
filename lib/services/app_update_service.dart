import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.androidUrl,
    required this.iosUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final String androidUrl;
  final String iosUrl;

  String get storeUrl => Platform.isIOS ? iosUrl : androidUrl;
  bool get hasStoreUrl => storeUrl.trim().isNotEmpty;
}

class AppUpdateService {
  AppUpdateService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await _apiService
          .get('/app/version')
          .timeout(const Duration(seconds: 5));
      if (response is! Map) return null;

      final latestVersion = '${response['latestVersion'] ?? ''}'.trim();
      final minimumVersion = '${response['minimumVersion'] ?? '0.0.0'}'.trim();
      if (latestVersion.isEmpty) return null;

      final belowMinimum =
          _compareVersions(packageInfo.version, minimumVersion) < 0;
      final newerAvailable =
          _compareVersions(packageInfo.version, latestVersion) < 0;
      if (!belowMinimum && !newerAvailable) return null;

      return AppUpdateInfo(
        currentVersion: packageInfo.version,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        forceUpdate: belowMinimum || response['forceUpdate'] == true,
        androidUrl: '${response['androidUrl'] ?? ''}',
        iosUrl: '${response['iosUrl'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> openStore(AppUpdateInfo update) async {
    if (!update.hasStoreUrl) return false;
    return launchUrl(
      Uri.parse(update.storeUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  int _compareVersions(String first, String second) {
    final left = _versionParts(first);
    final right = _versionParts(second);
    for (var index = 0; index < 3; index++) {
      if (left[index] != right[index]) {
        return left[index].compareTo(right[index]);
      }
    }
    return 0;
  }

  List<int> _versionParts(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .take(3)
        .map(
          (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        )
        .followedBy(const [0, 0, 0])
        .take(3)
        .toList();
  }
}
