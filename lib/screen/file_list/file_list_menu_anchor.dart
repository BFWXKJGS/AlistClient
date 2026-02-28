import 'dart:io';

import 'package:alist/l10n/intl_keys.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef OnMenuClickCallback = Function(MenuItemEntity menuItem);

final menuGroupOperations = MenuGroupEntity(
  menuGroupId: MenuGroupId.operations,
  children: [
    MenuItemEntity(
      menuGroupId: MenuGroupId.operations,
      menuId: MenuId.forceRefresh,
      name: Intl.fileList_menu_forceRefresh.tr,
      iconData: Icons.refresh,
    ),
    MenuItemEntity(
      menuGroupId: MenuGroupId.operations,
      menuId: MenuId.newFolder,
      name: Intl.fileList_menu_newFolder.tr,
      iconData: Icons.create_new_folder,
    ),
    MenuItemEntity(
      menuGroupId: MenuGroupId.operations,
      menuId: MenuId.downloadAll,
      name: Intl.fileList_menu_downloadAll.tr,
      iconData: Icons.download_rounded,
    ),
    if (Platform.isIOS)
      MenuItemEntity(
        menuGroupId: MenuGroupId.operations,
        menuId: MenuId.uploadPhotos,
        name: Intl.fileList_menu_uploadPhotos.tr,
        iconData: Icons.upload_rounded,
      ),
    MenuItemEntity(
      menuGroupId: MenuGroupId.operations,
      menuId: MenuId.uploadFiles,
      name: Intl.fileList_menu_uploadFiles.tr,
      iconData: Icons.upload_rounded,
    ),
    MenuItemEntity(
      menuGroupId: MenuGroupId.operations,
      menuId: MenuId.configFileNameLines,
      name: Intl.fileList_menu_fileNameLines.tr,
      iconData: Icons.line_weight_rounded,
    ),
    MenuItemEntity(
      menuGroupId: MenuGroupId.operations,
      menuId: MenuId.projector,
      name: Intl.fileList_menu_projector.tr,
      iconData: Icons.slideshow_rounded,
    ),
  ],
);

class FileListMenuAnchorController {
  var hasWritePermission = false.obs;
  final menuController = MenuController();
  var isMenuOpen = false.obs;
  var sortBy = MenuId.fileName.obs;
  var sortByUp = true.obs;
  final FocusNode firstMenuItemFocusNode = FocusNode();

  updateSortBy(MenuId? sortBy, bool? sortByUp) {
    if (sortBy != null) {
      this.sortBy.value = sortBy;
    }
    if (sortByUp != null) {
      this.sortByUp.value = sortByUp;
    }
  }

  void dispose() {
    firstMenuItemFocusNode.dispose();
  }
}

class FileListMenuAnchor extends StatelessWidget {
  final FileListMenuAnchorController controller;
  final Widget child;
  final OnMenuClickCallback? onMenuClickCallback;

  const FileListMenuAnchor({
    super.key,
    required this.controller,
    required this.child,
    this.onMenuClickCallback,
  });

  @override
  Widget build(BuildContext context) {
    const menuWidth = 180.0;
    return MenuAnchor(
      style: const MenuStyle(
        fixedSize: MaterialStatePropertyAll(Size.fromWidth(menuWidth)),
      ),
      controller: controller.menuController,
      anchorTapClosesMenu: true,
      onOpen: () {
        controller.isMenuOpen.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.isMenuOpen.value &&
              controller.firstMenuItemFocusNode.canRequestFocus) {
            controller.firstMenuItemFocusNode.requestFocus();
          }
        });
      },
      onClose: () {
        controller.isMenuOpen.value = false;
      },
      menuChildren: [
        Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildMenus(
              menuWidth,
              controller.hasWritePermission.value,
              controller.sortBy.value,
              controller.sortByUp.value,
              onMenuClickCallback,
            ),
          ),
        ),
      ],
      child: Obx(
        () => AbsorbPointer(
          absorbing: controller.isMenuOpen.value,
          child: child,
        ),
      ),
    );
  }

  List<Widget> _buildMenus(
    double menuWidth,
    bool canWrite,
    MenuId sortBy,
    bool sortByUp,
    OnMenuClickCallback? onMenuClickCallback,
  ) {
    final menus = <Widget>[
      SizedBox(
        width: menuWidth,
      ),
    ];
    var shouldBindFirstFocusNode = true;
    if (canWrite) {
      shouldBindFirstFocusNode = _addMenus(
        menuWidgets: menus,
        menuGroup: menuGroupOperations,
        onMenuClickCallback: onMenuClickCallback,
        bindFirstFocusNode: shouldBindFirstFocusNode,
      );
    } else {
      final readonlyGroup = MenuGroupEntity(
        menuGroupId: MenuGroupId.operations,
        children: [
          MenuItemEntity(
            menuGroupId: MenuGroupId.operations,
            menuId: MenuId.downloadAll,
            name: Intl.fileList_menu_downloadAll.tr,
            iconData: Icons.download_rounded,
          ),
          MenuItemEntity(
            menuGroupId: MenuGroupId.operations,
            menuId: MenuId.configFileNameLines,
            name: Intl.fileList_menu_fileNameLines.tr,
            iconData: Icons.line_weight_rounded,
          ),
          MenuItemEntity(
            menuGroupId: MenuGroupId.operations,
            menuId: MenuId.projector,
            name: Intl.fileList_menu_projector.tr,
            iconData: Icons.slideshow_rounded,
          ),
        ],
      );
      shouldBindFirstFocusNode = _addMenus(
        menuWidgets: menus,
        menuGroup: readonlyGroup,
        onMenuClickCallback: onMenuClickCallback,
        bindFirstFocusNode: shouldBindFirstFocusNode,
      );
    }
    menus.add(
      Container(
        color: Get.theme.colorScheme.surfaceVariant,
        height: 3,
      ),
    );

    _addMenus(
      menuWidgets: menus,
      menuGroup: _buildMenuGroupSort(sortBy, sortByUp),
      onMenuClickCallback: onMenuClickCallback,
      bindFirstFocusNode: shouldBindFirstFocusNode,
    );
    return menus;
  }

  MenuGroupEntity _buildMenuGroupSort(MenuId sortBy, bool sortByUp) {
    return MenuGroupEntity(
      menuGroupId: MenuGroupId.sort,
      children: [
        MenuItemEntity(
          menuGroupId: MenuGroupId.sort,
          menuId: MenuId.fileName,
          name: Intl.fileList_menu_fileName.tr,
          iconData: sortBy == MenuId.fileName
              ? (sortByUp
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded)
              : null,
          isUp: sortBy == MenuId.fileName ? sortByUp : null,
        ),
        MenuItemEntity(
          menuGroupId: MenuGroupId.sort,
          menuId: MenuId.fileType,
          name: Intl.fileList_menu_fileType.tr,
          iconData: sortBy == MenuId.fileType
              ? (sortByUp
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded)
              : null,
          isUp: sortBy == MenuId.fileType ? sortByUp : null,
        ),
        MenuItemEntity(
          menuGroupId: MenuGroupId.sort,
          menuId: MenuId.modifyTime,
          name: Intl.fileList_menu_modifyTime.tr,
          iconData: sortBy == MenuId.modifyTime
              ? (sortByUp
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded)
              : null,
          isUp: sortBy == MenuId.modifyTime ? sortByUp : null,
        ),
      ],
    );
  }

  bool _addMenus({
    required List<Widget> menuWidgets,
    required MenuGroupEntity menuGroup,
    required OnMenuClickCallback? onMenuClickCallback,
    required bool bindFirstFocusNode,
  }) {
    final menuEntities = menuGroup.children;
    var shouldBindFocusNode = bindFirstFocusNode;
    for (int i = 0; i < menuEntities.length; i++) {
      final menuEntity = menuEntities[i];
      final isFirstFocusableItem = shouldBindFocusNode;
      final focusNode =
          isFirstFocusableItem ? controller.firstMenuItemFocusNode : null;
      if (isFirstFocusableItem) {
        shouldBindFocusNode = false;
      }
      final menu = Obx(() => MenuItemButton(
            focusNode: focusNode,
            onPressed: () {
              if (onMenuClickCallback != null) {
                if (menuEntity.menuGroupId == MenuGroupId.sort) {
                  LogUtil.d("isUp = ${menuEntity.isUp}");
                  if (menuEntity.isUp != null) {
                    menuEntity.isUp = !menuEntity.isUp!;
                    menuEntity.iconData.value = menuEntity.isUp!
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded;
                  } else {
                    for (final value in menuEntities) {
                      if (value == menuEntity) {
                        value.isUp = true;
                        value.iconData.value = Icons.arrow_upward_rounded;
                      } else if (value.isUp != null) {
                        value.isUp = null;
                        value.iconData.value = null;
                      }
                    }
                  }
                }

                onMenuClickCallback(menuEntity);
              }
            },
            trailingIcon: menuEntity.iconData.value != null
                ? Icon(menuEntity.iconData.value)
                : null,
            child: Text(menuEntity.name),
          ));
      menuWidgets.add(menu);
      if (i != menuEntities.length - 1) {
        menuWidgets.add(const Divider());
      }
    }
    return shouldBindFocusNode;
  }
}

enum MenuGroupId {
  operations,
  sort,
}

enum MenuId {
  forceRefresh,
  newFolder,
  fileName,
  fileType,
  modifyTime,
  downloadAll,
  uploadPhotos,
  uploadFiles,
  configFileNameLines,
  projector,
}

class MenuGroupEntity {
  final MenuGroupId menuGroupId;
  final List<MenuItemEntity> children;

  MenuGroupEntity({required this.menuGroupId, required this.children});
}

class MenuItemEntity {
  final MenuGroupId menuGroupId;
  final MenuId menuId;
  final String name;
  Rx<IconData?> iconData = Rx(null);
  bool? isUp;

  MenuItemEntity({
    required this.menuGroupId,
    required this.menuId,
    required this.name,
    IconData? iconData,
    this.isUp,
  }) {
    this.iconData.value = iconData;
  }
}
