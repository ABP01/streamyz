import 'package:flutter/material.dart';

class TextPost extends StatelessWidget {
  final String text;
  const TextPost({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}