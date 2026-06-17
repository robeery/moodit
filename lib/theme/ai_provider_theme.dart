import 'package:flutter/material.dart';
import '../model/ai_profile_settings.dart';

// Per provider gradient stops; start is also used for
// borders, icon strokes and text where a gradient does not render well.
List<Color> aiProviderGradientColors(String? providerId) {
  switch (providerId) {
    case AiProfileSettings.openAiProviderId:
      return const [Color(0xFF34D6C1), Color(0xFF2A9BD6)];
    case AiProfileSettings.claudeProviderId:
      return const [Color(0xFFE9A24C), Color(0xFFE9624C)];
    case AiProfileSettings.geminiProviderId:
    default:
      return const [Color(0xFF4C8DF6), Color(0xFF9B5CF6)];
  }
}

LinearGradient aiProviderGradient(String? providerId) {
  return LinearGradient(
    colors: aiProviderGradientColors(providerId),
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

Color aiProviderStartColor(String? providerId) =>
    aiProviderGradientColors(providerId).first;

String aiProviderTag(String? providerId) {
  switch (providerId) {
    case AiProfileSettings.openAiProviderId:
      return 'OPENAI';
    case AiProfileSettings.claudeProviderId:
      return 'ANTHROPIC';
    case AiProfileSettings.geminiProviderId:
    default:
      return 'GOOGLE';
  }
}
