/// Default MIME content type for Firebase Storage uploads.
///
/// Used as a fallback when the content type cannot be determined from the
/// file extension, e.g. when
/// [firebaseStorageContentTypeFromFilename] returns `null`.
const firebaseStorageDefaultContentType = 'application/octet-stream';

/// Guesses the MIME content type for a file from its extension in
/// [filename].
///
/// [filename] is matched case-insensitively against its extension (the
/// text after the last `.`); the full path is not otherwise inspected, so
/// a bare name without extension works the same as a path.
///
/// Returns the corresponding MIME type (e.g. `'image/png'` for `.png`), or
/// `null` when the extension is unknown or [filename] has no extension. See
/// [firebaseStorageDefaultContentType] for a suitable fallback value.
String? firebaseStorageContentTypeFromFilename(String filename) {
  var extension = filename.split('.').last.toLowerCase();
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'bmp':
      return 'image/bmp';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'avi':
      return 'video/x-msvideo';
    case 'mkv':
      return 'video/x-matroska';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'flac':
      return 'audio/flac';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'txt':
      return 'text/plain';
    case 'html':
    case 'htm':
      return 'text/html';
    case 'csv':
      return 'text/csv';
    default:
      return null;
  }
}
