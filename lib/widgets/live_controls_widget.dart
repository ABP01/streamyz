import 'package:flutter/material.dart';

class LiveControlsWidget extends StatefulWidget {
  final bool isHost;
  final VoidCallback? onEndLive;
  final VoidCallback? onInvite;

  const LiveControlsWidget({
    super.key,
    required this.isHost,
    this.onEndLive,
    this.onInvite,
  });

  @override
  State<LiveControlsWidget> createState() => _LiveControlsWidgetState();
}

class _LiveControlsWidgetState extends State<LiveControlsWidget> {
  @override
  Widget build(BuildContext context) {
    // Widget vide - tous les boutons ont été supprimés
    return Container();
  }
}
