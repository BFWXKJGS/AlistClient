import 'package:alist/generated/images.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/overflow_text.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FileListItemView extends StatelessWidget {
  const FileListItemView({
    Key? key,
    required this.icon,
    required this.fileName,
    required this.time,
    required this.sizeDesc,
    this.thumbnail,
    required this.onTap,
    this.onMoreIconButtonTap,
    this.fileNameMaxLines,
  }) : super(key: key);
  final GestureTapCallback onTap;
  final GestureTapCallback? onMoreIconButtonTap;
  final String icon;
  final String? thumbnail;
  final String fileName;
  final String? time;
  final String? sizeDesc;
  final int? fileNameMaxLines;

  @override
  Widget build(BuildContext context) {
    String? thumbnail = FileUtils.getCompleteThumbnail(this.thumbnail);
    bool isDarkMode = WidgetUtils.isDarkMode(context);
    String subtitle = time ?? "";
    if (sizeDesc != null) {
      subtitle = "$subtitle - $sizeDesc";
    }

    return ListTile(
      horizontalTitleGap: 6,
      minVerticalPadding: 12,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            _buildThumbnailView(icon, thumbnail)
          else
            Image.asset(icon)
        ],
      ),
      trailing: _moreIconButton(isDarkMode),
      title: Obx(() {
        int globalFileNameMaxLines = Global.fileNameMaxLines.value;
        int fileNameMaxLines =
            this.fileNameMaxLines ?? globalFileNameMaxLines;
        return fileNameMaxLines == 1
            ? OverflowText(text: fileName)
            : Text(
          fileName,
          maxLines: fileNameMaxLines > 2 ? 1000 : 2,
          overflow: TextOverflow.ellipsis,
        );
      }),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _moreIconButton(bool isDarkMode) {
    if (onMoreIconButtonTap == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Images.iconArrowRight,
            color: isDarkMode ? Colors.white : null,
          )
        ],
      );
    } else {
      return IconButton(
        onPressed: onMoreIconButtonTap,
        icon: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Get.theme.colorScheme.primaryContainer,
              ),
              width: 24,
              height: 12,
            ),
            const Icon(Icons.more_horiz_rounded),
          ],
        ),
      );
    }
  }

  ClipRRect _buildThumbnailView(String icon, String thumbnail) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: ExtendedImage.network(
        thumbnail,
        fit: BoxFit.cover,
        width: 35,
        height: 35,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return Image.asset(icon);
          }
          return null;
        },
      ),
    );
  }
}

class FileItemVO {
  String name;
  String path;
  final int? size;
  final String? sizeDesc;
  final bool isDir;
  final String modified;
  final int modifiedMilliseconds;
  final String sign;
  final String thumb;
  final int typeInt;
  final FileType type;
  final String icon;
  final String? provider;

  FileItemVO(
      {required this.name,
      required this.path,
      required this.size,
      required this.sizeDesc,
      required this.isDir,
      required this.modified,
      required this.modifiedMilliseconds,
      required this.sign,
      required this.thumb,
      required this.typeInt,
      required this.type,
      required this.icon,
      required this.provider});
}
