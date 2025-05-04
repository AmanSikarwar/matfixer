class InstallationStep {
  final String title;
  final String content;
  final String? code;
  final String? language;

  InstallationStep({
    required this.title,
    required this.content,
    this.language,
    this.code,
  });
}
