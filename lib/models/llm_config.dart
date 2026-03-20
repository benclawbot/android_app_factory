enum LLMProvider {
  minimax,
  anthropic,
}

class LLMConfig {
  final LLMProvider provider;
  final String apiKey;
  final String? customEndpoint;

  const LLMConfig({
    required this.provider,
    required this.apiKey,
    this.customEndpoint,
  });

  String get modelName {
    switch (provider) {
      case LLMProvider.minimax:
        return 'MiniMax-M2.7';
      case LLMProvider.anthropic:
        return 'claude-opus-4-20250514';
    }
  }

  String get baseUrl {
    if (customEndpoint != null && customEndpoint!.isNotEmpty) {
      return customEndpoint!;
    }
    switch (provider) {
      case LLMProvider.minimax:
        return 'https://api.minimax.io';
      case LLMProvider.anthropic:
        return 'https://api.anthropic.com';
    }
  }

  String get displayName {
    switch (provider) {
      case LLMProvider.minimax:
        return 'MiniMax M2.7';
      case LLMProvider.anthropic:
        return 'Claude Opus 4';
    }
  }

  LLMConfig copyWith({
    LLMProvider? provider,
    String? apiKey,
    String? customEndpoint,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      customEndpoint: customEndpoint ?? this.customEndpoint,
    );
  }
}
