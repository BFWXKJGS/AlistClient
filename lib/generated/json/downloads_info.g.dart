import 'package:alist/entity/downloads_info.dart';
import 'package:alist/generated/json/base/json_convert_content.dart';

DownloadsInfo $DownloadsInfoFromJson(Map<String, dynamic> json) {
  final DownloadsInfo downloadsInfo = DownloadsInfo();
  final bool? isSupportRange =
      jsonConvert.convert<bool>(json['isSupportRange']);
  if (isSupportRange != null) {
    downloadsInfo.isSupportRange = isSupportRange;
  }
  final bool? decompress = jsonConvert.convert<bool>(json['decompress']);
  if (decompress != null) {
    downloadsInfo.decompress = decompress;
  }
  final String? lastModified =
      jsonConvert.convert<String>(json['lastModified']);
  if (lastModified != null) {
    downloadsInfo.lastModified = lastModified;
  }
  final String? etag = jsonConvert.convert<String>(json['etag']);
  if (etag != null) {
    downloadsInfo.etag = etag;
  }
  final int? contentLength = jsonConvert.convert<int>(json['contentLength']);
  if (contentLength != null) {
    downloadsInfo.contentLength = contentLength;
  }
  return downloadsInfo;
}

Map<String, dynamic> $DownloadsInfoToJson(DownloadsInfo entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['isSupportRange'] = entity.isSupportRange;
  data['decompress'] = entity.decompress;
  data['lastModified'] = entity.lastModified;
  data['etag'] = entity.etag;
  data['contentLength'] = entity.contentLength;
  return data;
}
