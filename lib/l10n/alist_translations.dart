import 'package:alist/l10n/intl_zh_cn.dart';
import 'package:get/get.dart';

import 'intl_en_us.dart';

class AlistTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': translationsZhCN,
        'en_US': translationsEnUS,
      };
}
