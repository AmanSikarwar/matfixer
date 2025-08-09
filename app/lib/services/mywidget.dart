import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

class MyWidget extends StatefulWidget {
  final String code;
  final String language;

  const MyWidget({
    Key? key,
    required this.code,
    required this.language,
  }) : super(key: key);

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _copied = false;

  void _copyCodeToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: githubTheme['root']?.backgroundColor ?? Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: HighlightView(
            widget.code,
            language: widget.language,
            theme: githubTheme,
            textStyle: const TextStyle(
              fontFamily: 'SourceCodePro',
              fontSize: 16,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: Icon(
              _copied ? Icons.check : Icons.copy,
              color: _copied ? Colors.green : Colors.grey[700],
              size: 20,
            ),
            tooltip: _copied ? 'Copied!' : 'Copy to clipboard',
            onPressed: _copyCodeToClipboard,
          ),
        ),
      ],
    );
  }
}
