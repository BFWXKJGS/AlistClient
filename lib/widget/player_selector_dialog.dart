import 'dart:io';

import 'package:alist/entity/player_resolve_info_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

typedef OnExternalPlayerClick = Function(ExternalPlayerEntity);

class PlayerSelectorDialog extends StatelessWidget {
  const PlayerSelectorDialog(
      {super.key,
      required this.players,
      required this.onPlayerClick});

  final List<ExternalPlayerEntity> players;
  final OnExternalPlayerClick onPlayerClick;

  @override
  Widget build(BuildContext context) {
    var itemCount = players.length;

    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
      child: AlignedGridView.count(
          crossAxisCount: 4,
          shrinkWrap: itemCount < 8,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            var info = players[index];
            return GestureDetector(
              onTap: () {
                onPlayerClick(info);
              },
              child: _buildPlayerWidget(info.icon, info.label, iconIsFile: info.activity.isNotEmpty),
            );
          }),
    );
  }

  Widget _buildPlayerWidget(String icon, String label,
      {bool iconIsFile = true}) {
    dynamic image = iconIsFile ? FileImage(File(icon)) : AssetImage(icon);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: image,
              width: 45,
              height: 45,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          )
        ],
      ),
    );
  }
}
