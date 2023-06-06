import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/file_utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FileDetailsDialog extends StatelessWidget {
  const FileDetailsDialog({
    Key? key,
    required this.name,
    required this.size,
    required this.path,
    required this.modified,
    required this.thumb,
  }) : super(key: key);
  final String name;
  final String? size;
  final String path;
  final String modified;
  final String? thumb;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 30, 15, 10),
          child: _buildInfoColumn(),
        ));
  }

  Column _buildInfoColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoRow("${Intl.fileDetailsDialog_name.tr}:", name),
        _buildInfoRow("${Intl.fileDetailsDialog_size.tr}:", size ?? ""),
        _buildInfoRow("${Intl.fileDetailsDialog_where.tr}:", path),
        _buildInfoRow("${Intl.fileDetailsDialog_modified.tr}:", modified),
        if (thumb != null && thumb!.isNotEmpty)
          _buildThumb(thumb!, FileUtils.getFileIcon(false, name))
      ],
    );
  }

  Row _buildInfoRow(String text1, String text2) {
    return Row(
      children: [
        Container(
          alignment: Alignment.bottomRight,
          width: 80,
          child: Text(
            text1,
            style: Get.textTheme.bodyMedium
                ?.copyWith(color: Get.theme.colorScheme.outline),
          ),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(text2),
        )),
      ],
    );
  }

  Widget _buildThumb(String thumb, String icon) {
    String thumbnail = FileUtils.getCompleteThumbnail(thumb)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ExtendedImage.network(
        thumbnail,
        width: 100,
        height: 100,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return Image.asset(icon);
          }
          return null;
        },
        beforePaintImage: (canvas, rect, image, paint) {
          if (!rect.isEmpty) {
            canvas.save();
            canvas.clipRRect(
                RRect.fromRectAndRadius(rect, const Radius.circular(4)));
          }
          return false;
        },
      ),
    );
  }
}
