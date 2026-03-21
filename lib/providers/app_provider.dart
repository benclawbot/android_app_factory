import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/llm_config.dart';

class AppProvider extends ChangeNotifier {
  LLMConfig _llmConfig = const LLMConfig(
    provider: LLMProvider.minimax,
    apiKey: '',
  );

  String _outputDirectory = '';
  String _appName = 'MyApp';
  String _packageName = 'com.example.myapp';
  bool _autoBuild = true;
  int _maxBuildAttempts = 3;

  LLMConfig get llmConfig => _llmConfig;
  String get outputDirectory => _outputDirectory;
  String get appName => _appName;
  String get packageName => _packageName;
  bool get autoBuild => _autoBuild;
  int get maxBuildAttempts => _maxBuildAttempts;

  bool get isConfigured => _llmConfig.apiKey.isNotEmpty;

  AppProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final providerIndex = prefs.getInt('llm_provider') ?? 0;
    final apiKey = prefs.getString('api_key') ?? '';
    final customEndpoint = prefs.getString('custom_endpoint');
    _outputDirectory = prefs.getString('output_directory') ?? '';
    _autoBuild = prefs.getBool('auto_build') ?? true;
    _maxBuildAttempts = prefs.getInt('max_build_attempts') ?? 3;

    _llmConfig = LLMConfig(
      provider: LLMProvider.values[providerIndex],
      apiKey: apiKey,
      customEndpoint: customEndpoint,
    );
    notifyListeners();
  }

  Future<void> setLLMProvider(LLMProvider provider) async {
    _llmConfig = _llmConfig.copyWith(provider: provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('llm_provider', provider.index);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _llmConfig = _llmConfig.copyWith(apiKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    notifyListeners();
  }

  Future<void> setCustomEndpoint(String? endpoint) async {
    _llmConfig = _llmConfig.copyWith(customEndpoint: endpoint);
    final prefs = await SharedPreferences.getInstance();
    if (endpoint != null) {
      await prefs.setString('custom_endpoint', endpoint);
    } else {
      await prefs.remove('custom_endpoint');
    }
    notifyListeners();
  }

  Future<void> setOutputDirectory(String dir) async {
    _outputDirectory = dir;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('output_directory', dir);
    notifyListeners();
  }

  void setAppName(String name) {
    _appName = name;
    notifyListeners();
  }

  void setPackageName(String name) {
    _packageName = name;
    notifyListeners();
  }

  Future<void> setAutoBuild(bool value) async {
    _autoBuild = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_build', value);
    notifyListeners();
  }

  Future<void> setMaxBuildAttempts(int value) async {
    _maxBuildAttempts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_build_attempts', value);
    notifyListeners();
  }
}
