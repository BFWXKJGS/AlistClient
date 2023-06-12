import 'package:alist/generated/images.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/overflow_position_middle_text.dart';
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
  }) : super(key: key);
  final GestureTapCallback onTap;
  final GestureTapCallback? onMoreIconButtonTap;
  final String icon;
  final String? thumbnail;
  final String fileName;
  final String? time;
  final String? sizeDesc;

  @override
  Widget build(BuildContext context) {
    String? thumbnail = FileUtils.getCompleteThumbnail(this.thumbnail);
    bool isDarkMode = WidgetUtils.isDarkMode(context);
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
      title: OverflowPositionMiddleText(
        fileName,
        maxLines: 1,
      ),
      subtitle: time != null
          ? Row(
              children: [
                Text(time!),
                if (sizeDesc != null) Text(" - ${sizeDesc!}"),
              ],
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
  int? size;
  String? sizeDesc;
  bool isDir;
  String modified;
  int modifiedMilliseconds;
  String sign;
  String thumb;
  int typeInt;
  FileType type;
  String icon;

  FileItemVO({
    required this.name,
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
  });
}
