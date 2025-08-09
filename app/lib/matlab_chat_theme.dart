import 'package:flutter/widgets.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
// ignore: implementation_imports
import 'package:flutter_ai_toolkit/src/styles/tookit_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

/// A collection of MATLAB-inspired colors for the light chat UI.
abstract final class MatlabColors {
  /// MATLAB's primary blue color
  static const Color primaryBlue = Color(0xFF0076A8);

  /// MATLAB's darker blue for headers and important elements
  static const Color secondaryBlue = Color(0xFF0C5394);

  /// MATLAB's orange accent color
  static const Color accentOrange = Color(0xFFF28500);

  /// MATLAB's light background color
  static const Color lightBackground = Color(0xFFF5F5F5);

  /// Very light blue for message backgrounds
  static const Color lightBlueBackground = Color(0xFFE9F1F7);

  /// White color for main backgrounds
  static const Color white = Color(0xFFFFFFFF);

  /// Main text color
  static const Color textColor = Color(0xFF333333);

  /// Light gray for borders and separators
  static const Color borderGray = Color(0xFFCCCCCC);

  /// Transparent color
  static const Color transparent = Color(0x00000000);
}

/// A collection of MATLAB-inspired dark theme colors for the chat UI.
abstract final class MatlabDarkColors {
  /// MATLAB's primary blue color (slightly brighter for dark theme)
  static const Color primaryBlue = Color(0xFF0091D1);

  /// MATLAB's secondary blue for dark theme
  static const Color secondaryBlue = Color(0xFF60A5FA);

  /// MATLAB's orange accent color (slightly brighter for dark theme)
  static const Color accentOrange = Color(0xFFFF9A3C);

  /// MATLAB's dark background color
  static const Color darkBackground = Color(0xFF1E1E1E);

  /// Dark blue background for messages
  static const Color darkBlueBackground = Color(0xFF2D3748);

  /// Darker blue background for user messages
  static const Color darkerBlueBackground = Color(0xFF1F2937);

  /// Near-black color for main backgrounds
  static const Color nearBlack = Color(0xFF121212);

  /// Text color for dark theme
  static const Color textColor = Color(0xFFE5E5E5);

  /// Darker gray for borders and separators
  static const Color borderGray = Color(0xFF4B5563);

  /// Transparent color
  static const Color transparent = Color(0x00000000);
}

/// Text styles customized for the MATLAB theme
abstract final class MatlabTextStyles {
  /// Creates MATLAB-themed text styles
  static TextStyle get body1 => GoogleFonts.roboto(
    color: MatlabColors.textColor,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Code style for the MATLAB theme
  static TextStyle get code => GoogleFonts.robotoMono(
    color: MatlabColors.secondaryBlue,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Heading style for the MATLAB theme
  static TextStyle get heading1 => GoogleFonts.roboto(
    color: MatlabColors.secondaryBlue,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  /// Creates MATLAB dark theme text styles
  static TextStyle get darkBody1 => GoogleFonts.roboto(
    color: MatlabDarkColors.textColor,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Code style for the MATLAB dark theme
  static TextStyle get darkCode => GoogleFonts.robotoMono(
    color: MatlabDarkColors.secondaryBlue,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Heading style for the MATLAB dark theme
  static TextStyle get darkHeading1 => GoogleFonts.roboto(
    color: MatlabDarkColors.secondaryBlue,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );
}

/// A utility class that provides a MATLAB-themed style for the LLM chat view.
class MatlabChatTheme {
  /// Creates a MATLAB light-themed style for the LLM chat view.
  static LlmChatViewStyle matlabStyle() {
    return LlmChatViewStyle(
      backgroundColor: MatlabColors.white,
      menuColor: MatlabColors.lightBackground,
      progressIndicatorColor: MatlabColors.primaryBlue,

      // User message style with MATLAB colors
      userMessageStyle: UserMessageStyle(
        textStyle: MatlabTextStyles.body1,
        decoration: const BoxDecoration(
          color: MatlabColors.lightBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.zero,
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),

      // LLM message style with MATLAB colors
      llmMessageStyle: LlmMessageStyle(
        icon: ToolkitIcons.spark_icon,
        iconColor: MatlabColors.white,
        iconDecoration: const BoxDecoration(
          color: MatlabColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        decoration: BoxDecoration(
          color: MatlabColors.lightBlueBackground,
          border: Border.all(color: MatlabColors.borderGray),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.zero,
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        markdownStyle: MarkdownStyleSheet(
          a: MatlabTextStyles.body1.copyWith(
            color: MatlabColors.primaryBlue,
            decoration: TextDecoration.underline,
          ),
          blockquote: MatlabTextStyles.body1.copyWith(
            fontStyle: FontStyle.italic,
          ),
          code: MatlabTextStyles.code,
          del: MatlabTextStyles.body1.copyWith(
            decoration: TextDecoration.lineThrough,
          ),
          em: MatlabTextStyles.body1.copyWith(fontStyle: FontStyle.italic),
          h1: MatlabTextStyles.heading1,
          h2: MatlabTextStyles.heading1.copyWith(fontSize: 20),
          h3: MatlabTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
          h4: MatlabTextStyles.body1.copyWith(fontWeight: FontWeight.w500),
          h5: MatlabTextStyles.body1,
          h6: MatlabTextStyles.body1,
          listBullet: MatlabTextStyles.body1,
          img: MatlabTextStyles.body1,
          strong: MatlabTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
          p: MatlabTextStyles.body1,
          tableBody: MatlabTextStyles.body1,
          tableHead: MatlabTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Chat input style with MATLAB colors
      chatInputStyle: ChatInputStyle(
        textStyle: MatlabTextStyles.body1,
        hintStyle: MatlabTextStyles.body1.copyWith(
          color: MatlabColors.borderGray,
        ),
        hintText: 'Ask MATLAB...',
        backgroundColor: MatlabColors.white,
        decoration: BoxDecoration(
          color: MatlabColors.white,
          border: Border.all(width: 1, color: MatlabColors.primaryBlue),
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Submit button style with MATLAB's orange color
      submitButtonStyle: ActionButtonStyle(
        icon: ToolkitIcons.submit_icon,
        iconColor: MatlabColors.white,
        iconDecoration: const BoxDecoration(
          color: MatlabColors.accentOrange,
          shape: BoxShape.circle,
        ),
        text: 'Run',
        textStyle: MatlabTextStyles.body1.copyWith(color: MatlabColors.white),
      ),

      // Suggestion style with MATLAB colors
      suggestionStyle: SuggestionStyle(
        textStyle: MatlabTextStyles.body1,
        decoration: const BoxDecoration(
          color: MatlabColors.lightBlueBackground,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Action button bar with MATLAB colors
      actionButtonBarDecoration: BoxDecoration(
        color: MatlabColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),

      // File attachment style with MATLAB colors
      fileAttachmentStyle: FileAttachmentStyle(
        decoration: ShapeDecoration(
          color: MatlabColors.lightBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: ToolkitIcons.attach_file,
        iconColor: MatlabColors.secondaryBlue,
        iconDecoration: ShapeDecoration(
          color: MatlabColors.lightBlueBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        filenameStyle: MatlabTextStyles.body1,
        filetypeStyle: MatlabTextStyles.body1.copyWith(
          color: MatlabColors.borderGray,
        ),
      ),
    );
  }

  /// Creates a MATLAB dark-themed style for the LLM chat view.
  static LlmChatViewStyle matlabDarkStyle() {
    return LlmChatViewStyle(
      backgroundColor: MatlabDarkColors.nearBlack,
      menuColor: MatlabDarkColors.darkBackground,
      progressIndicatorColor: MatlabDarkColors.primaryBlue,

      // User message style with MATLAB dark colors
      userMessageStyle: UserMessageStyle(
        textStyle: MatlabTextStyles.darkBody1,
        decoration: const BoxDecoration(
          color: MatlabDarkColors.darkerBlueBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.zero,
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),

      // LLM message style with MATLAB dark colors
      llmMessageStyle: LlmMessageStyle(
        icon: ToolkitIcons.spark_icon,
        iconColor: MatlabDarkColors.textColor,
        iconDecoration: const BoxDecoration(
          color: MatlabDarkColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        decoration: BoxDecoration(
          color: MatlabDarkColors.darkBlueBackground,
          border: Border.all(color: MatlabDarkColors.borderGray),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.zero,
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        markdownStyle: MarkdownStyleSheet(
          a: MatlabTextStyles.darkBody1.copyWith(
            color: MatlabDarkColors.primaryBlue,
            decoration: TextDecoration.underline,
          ),
          blockquote: MatlabTextStyles.darkBody1.copyWith(
            fontStyle: FontStyle.italic,
          ),
          code: MatlabTextStyles.darkCode,
          del: MatlabTextStyles.darkBody1.copyWith(
            decoration: TextDecoration.lineThrough,
          ),
          em: MatlabTextStyles.darkBody1.copyWith(fontStyle: FontStyle.italic),
          h1: MatlabTextStyles.darkHeading1,
          h2: MatlabTextStyles.darkHeading1.copyWith(fontSize: 20),
          h3: MatlabTextStyles.darkBody1.copyWith(fontWeight: FontWeight.bold),
          h4: MatlabTextStyles.darkBody1.copyWith(fontWeight: FontWeight.w500),
          h5: MatlabTextStyles.darkBody1,
          h6: MatlabTextStyles.darkBody1,
          listBullet: MatlabTextStyles.darkBody1,
          img: MatlabTextStyles.darkBody1,
          strong: MatlabTextStyles.darkBody1.copyWith(
            fontWeight: FontWeight.bold,
          ),
          p: MatlabTextStyles.darkBody1,
          tableBody: MatlabTextStyles.darkBody1,
          tableHead: MatlabTextStyles.darkBody1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Chat input style with MATLAB dark colors
      chatInputStyle: ChatInputStyle(
        textStyle: MatlabTextStyles.darkBody1,
        hintStyle: MatlabTextStyles.darkBody1.copyWith(
          color: MatlabDarkColors.borderGray,
        ),
        hintText: 'Ask MATLAB...',
        backgroundColor: MatlabDarkColors.darkBackground,
        decoration: BoxDecoration(
          color: MatlabDarkColors.darkBackground,
          border: Border.all(width: 1, color: MatlabDarkColors.primaryBlue),
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Submit button style with MATLAB's orange color for dark theme
      submitButtonStyle: ActionButtonStyle(
        icon: ToolkitIcons.submit_icon,
        iconColor: MatlabDarkColors.darkBackground,
        iconDecoration: const BoxDecoration(
          color: MatlabDarkColors.accentOrange,
          shape: BoxShape.circle,
        ),
        text: 'Run',
        textStyle: MatlabTextStyles.darkBody1.copyWith(
          color: MatlabDarkColors.textColor,
        ),
      ),

      // Suggestion style with MATLAB dark colors
      suggestionStyle: SuggestionStyle(
        textStyle: MatlabTextStyles.darkBody1,
        decoration: const BoxDecoration(
          color: MatlabDarkColors.darkBlueBackground,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Action button bar with MATLAB dark colors
      actionButtonBarDecoration: BoxDecoration(
        color: MatlabDarkColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),

      // File attachment style with MATLAB dark colors
      fileAttachmentStyle: FileAttachmentStyle(
        decoration: ShapeDecoration(
          color: MatlabDarkColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: ToolkitIcons.attach_file,
        iconColor: MatlabDarkColors.secondaryBlue,
        iconDecoration: ShapeDecoration(
          color: MatlabDarkColors.darkBlueBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        filenameStyle: MatlabTextStyles.darkBody1,
        filetypeStyle: MatlabTextStyles.darkBody1.copyWith(
          color: MatlabDarkColors.borderGray,
        ),
      ),
    );
  }
}
