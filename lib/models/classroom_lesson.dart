import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

String classroomId() {
  final random = Random.secure();
  return List.generate(
      16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

class LessonAnnotation {
  final int start;
  final int end;
  final bool underline;
  final bool highlight;
  final bool bold;
  final bool italic;
  final bool? pinyinVisible;
  final bool? translationVisible;
  final String note;

  const LessonAnnotation({
    required this.start,
    required this.end,
    this.underline = false,
    this.highlight = false,
    this.bold = false,
    this.italic = false,
    this.pinyinVisible,
    this.translationVisible,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'underline': underline,
        'highlight': highlight,
        if (bold) 'bold': true,
        if (italic) 'italic': true,
        'pinyinVisible': pinyinVisible,
        if (translationVisible != null)
          'translationVisible': translationVisible,
        'note': note,
      };

  factory LessonAnnotation.fromJson(dynamic value, int textLength) {
    final map = _object(value, {
      'start',
      'end',
      'underline',
      'highlight',
      'pinyinVisible',
      'translationVisible',
      'bold',
      'italic',
      'note',
    });
    final start = _integer(map['start'], 0, textLength);
    final end = _integer(map['end'], start + 1, textLength);
    final visible = map['pinyinVisible'];
    if (visible != null && visible is! bool) _invalid();
    final translated = map['translationVisible'];
    if (translated != null && translated is! bool) _invalid();
    return LessonAnnotation(
      start: start,
      end: end,
      underline: _boolean(map['underline']),
      highlight: _boolean(map['highlight']),
      bold: _boolean(map['bold'] ?? false),
      italic: _boolean(map['italic'] ?? false),
      pinyinVisible: visible as bool?,
      translationVisible: translated as bool?,
      note: _string(map['note'], 2000),
    );
  }
}

enum LessonBlockKind { text, question, sentence, image }

class LessonBlock {
  final String id;
  final LessonBlockKind kind;
  final String text;
  final List<LessonAnnotation> annotations;
  final Uint8List? imageBytes;
  final String? imageMime;
  final double imageWidth;
  final double x;
  final double y;
  final double width;
  final double height;

  LessonBlock({
    String? id,
    this.kind = LessonBlockKind.text,
    this.text = '',
    List<LessonAnnotation> annotations = const [],
    Uint8List? imageBytes,
    this.imageMime,
    this.imageWidth = 640,
    this.x = 0.07,
    this.y = 0.12,
    this.width = 0.86,
    this.height = 0.18,
  })  : id = id ?? classroomId(),
        annotations = List.unmodifiable(annotations),
        imageBytes = imageBytes == null
            ? null
            : Uint8List.fromList(imageBytes).asUnmodifiableView();

  LessonBlock withText(String value) => LessonBlock(
        id: id,
        kind: kind,
        text: value,
        annotations: _annotationsAfterEdit(value),
        x: x,
        y: y,
        width: width,
        height: height,
        imageBytes: imageBytes,
        imageMime: imageMime,
        imageWidth: imageWidth,
      );

  List<LessonAnnotation> _annotationsAfterEdit(String value) {
    if (value == text || annotations.isEmpty) return annotations;
    var prefix = 0;
    while (prefix < text.length &&
        prefix < value.length &&
        text.codeUnitAt(prefix) == value.codeUnitAt(prefix)) {
      prefix++;
    }
    var oldEnd = text.length;
    var newEnd = value.length;
    while (oldEnd > prefix &&
        newEnd > prefix &&
        text.codeUnitAt(oldEnd - 1) == value.codeUnitAt(newEnd - 1)) {
      oldEnd--;
      newEnd--;
    }
    final inserted = newEnd - prefix;
    final delta = newEnd - oldEnd;
    final result = <LessonAnnotation>[];
    for (final annotation in annotations) {
      var start = annotation.start;
      var end = annotation.end;
      if (oldEnd == prefix) {
        // Insertion strictly inside inherits formatting. At a boundary it is
        // outside the existing range, avoiding unexpected style propagation.
        if (start >= prefix) start += inserted;
        if (end > prefix) end += inserted;
      } else if (start >= oldEnd) {
        start += delta;
        end += delta;
      } else if (end > prefix) {
        start = start < prefix ? start : prefix;
        end = end >= oldEnd ? end + delta : newEnd;
      }
      if (start >= end) continue;
      result.add(LessonAnnotation(
        start: start,
        end: end,
        underline: annotation.underline,
        highlight: annotation.highlight,
        bold: annotation.bold,
        italic: annotation.italic,
        pinyinVisible: annotation.pinyinVisible,
        translationVisible: annotation.translationVisible,
        note: annotation.note,
      ));
    }
    return result;
  }

  LessonBlock withAnnotations(List<LessonAnnotation> value) => LessonBlock(
        x: x,
        y: y,
        width: width,
        height: height,
        id: id,
        kind: kind,
        text: text,
        annotations: value,
        imageBytes: imageBytes,
        imageMime: imageMime,
        imageWidth: imageWidth,
      );

  LessonBlock withWidth(double value) => LessonBlock(
        x: x,
        y: y,
        width: width,
        height: height,
        id: id,
        kind: kind,
        text: text,
        annotations: annotations,
        imageBytes: imageBytes,
        imageMime: imageMime,
        imageWidth: value,
      );

  LessonBlock placed(
          {required double x,
          required double y,
          required double width,
          required double height}) =>
      LessonBlock(
        id: id,
        kind: kind,
        text: text,
        annotations: annotations,
        imageBytes: imageBytes,
        imageMime: imageMime,
        imageWidth: imageWidth,
        x: x,
        y: y,
        width: width,
        height: height,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'text': text,
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'imageBytes': imageBytes == null ? null : base64Encode(imageBytes!),
        'imageMime': imageMime,
        'imageWidth': imageWidth,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory LessonBlock.fromJson(dynamic value) {
    final map = _object(value, {
      'id',
      'kind',
      'text',
      'annotations',
      'imageBytes',
      'imageMime',
      'imageWidth',
      'x',
      'y',
      'width',
      'height',
    });
    final kindName = _string(map['kind'], 30);
    final kinds = LessonBlockKind.values.where((kind) => kind.name == kindName);
    if (kinds.isEmpty) _invalid();
    final kind = kinds.first;
    final text = _string(map['text'], 20000);
    final rawAnnotations = _list(map['annotations'], 500);
    final annotations = rawAnnotations
        .map((a) => LessonAnnotation.fromJson(a, text.length))
        .toList();
    Uint8List? bytes;
    String? mime;
    if (kind == LessonBlockKind.image) {
      final encoded = _string(
          map['imageBytes'], ((ClassroomPackage.maxImageBytes + 2) ~/ 3) * 4);
      try {
        bytes = base64Decode(encoded);
      } on FormatException {
        _invalid();
      }
      mime = _string(map['imageMime'], 30);
      ClassroomPackage.validateImage(bytes, mime);
      if (annotations.isNotEmpty) _invalid();
    } else if (map['imageBytes'] != null || map['imageMime'] != null) {
      _invalid();
    }
    final width = map['imageWidth'];
    if (width is! num || !width.isFinite || width < 160 || width > 1200) {
      _invalid();
    }
    if (_coordinate(map['x'], 0.07) +
                _coordinate(map['width'], 0.86, minimum: 0.08) >
            1.000001 ||
        _coordinate(map['y'], 0.12) +
                _coordinate(map['height'], 0.18, minimum: 0.04) >
            1.000001) {
      _invalid();
    }
    return LessonBlock(
      id: _id(map['id']),
      kind: kind,
      text: text,
      annotations: annotations,
      imageBytes: bytes,
      imageMime: mime,
      imageWidth: (width).toDouble(),
      x: _coordinate(map['x'], 0.07),
      y: _coordinate(map['y'], 0.12),
      width: _coordinate(map['width'], 0.86, minimum: 0.08),
      height: _coordinate(map['height'], 0.18, minimum: 0.04),
    );
  }
}

class ClassroomLesson {
  final String id;
  final int revision;
  final String title;
  final List<LessonBlock> blocks;
  final String paperStyle;

  ClassroomLesson(
      {String? id,
      this.revision = 1,
      required this.title,
      List<LessonBlock> blocks = const [],
      this.paperStyle = 'blank'})
      : id = id ?? classroomId(),
        blocks = List.unmodifiable(blocks);

  ClassroomLesson edit(
          {String? title, List<LessonBlock>? blocks, String? paperStyle}) =>
      ClassroomLesson(
        id: id,
        revision: revision + 1,
        title: title ?? this.title,
        blocks: blocks ?? this.blocks,
        paperStyle: paperStyle ?? this.paperStyle,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'revision': revision,
        'title': title,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'paperStyle': paperStyle,
      };

  factory ClassroomLesson.fromJson(dynamic value) {
    final map =
        _object(value, {'id', 'revision', 'title', 'blocks', 'paperStyle'});
    final rawBlocks = _list(map['blocks'], 200);
    final blocks = <LessonBlock>[];
    for (var i = 0; i < rawBlocks.length; i++) {
      final raw = rawBlocks[i];
      final block = LessonBlock.fromJson(raw);
      blocks.add(raw is Map && !raw.containsKey('x')
          ? block.placed(
              x: 0.07,
              y: (0.12 + i * 0.2).clamp(0.0, 0.8),
              width: 0.86,
              height: 0.18)
          : block);
    }
    if (blocks.map((b) => b.id).toSet().length != blocks.length) _invalid();
    final paperStyle = map['paperStyle'] ?? 'blank';
    if (!{'blank', 'lined', 'grid'}.contains(paperStyle)) _invalid();
    return ClassroomLesson(
      id: _id(map['id']),
      revision: _integer(map['revision'], 1, 9007199254740991),
      title: _string(map['title'], 200),
      blocks: blocks,
      paperStyle: paperStyle as String,
    );
  }
}

/// Only shared teaching content belongs in a package. Local notes and pupil
/// progress intentionally have no representation in this schema.
class ClassroomPackage {
  static const version = 1;
  static const maxFileBytes = 20 * 1024 * 1024;
  static const maxImageBytes = 4 * 1024 * 1024;
  final List<ClassroomLesson> lessons;

  ClassroomPackage(List<ClassroomLesson> lessons)
      : lessons = List.unmodifiable(lessons);

  Uint8List encode() {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'format': 'cika',
      'version': version,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    })));
    // Validate outbound content too, so every exported file can be reimported.
    ClassroomPackage.decode(bytes);
    return bytes;
  }

  factory ClassroomPackage.decode(List<int> bytes) {
    if (bytes.length > maxFileBytes) {
      throw const FormatException('package-size');
    }
    dynamic value;
    try {
      value = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException('invalid-package');
    }
    final map = _object(value, {'format', 'version', 'lessons'});
    if (map['format'] != 'cika' ||
        map['version'] != version ||
        map['version'] is! int) {
      throw const FormatException('unsupported-schema');
    }
    final lessons =
        _list(map['lessons'], 100).map(ClassroomLesson.fromJson).toList();
    if (lessons.isEmpty ||
        lessons.map((l) => l.id).toSet().length != lessons.length) {
      _invalid();
    }
    return ClassroomPackage(lessons);
  }

  static void validateImage(Uint8List bytes, String mime) {
    if (bytes.length > maxImageBytes || bytes.length < 24) {
      throw const FormatException('image-size');
    }
    final data = ByteData.sublistView(bytes);
    int width = 0;
    int height = 0;
    if (mime == 'image/png' &&
        bytes.take(8).join(',') == '137,80,78,71,13,10,26,10' &&
        ascii.decode(bytes.sublist(12, 16), allowInvalid: true) == 'IHDR') {
      width = data.getUint32(16);
      height = data.getUint32(20);
      var offset = 8;
      var hasPixels = false;
      var complete = false;
      while (offset + 12 <= bytes.length) {
        final length = data.getUint32(offset);
        if (offset + 12 + length > bytes.length) break;
        final type = ascii.decode(bytes.sublist(offset + 4, offset + 8),
            allowInvalid: true);
        if (offset == 8 && length != 13) break;
        if (type == 'IDAT' && length > 0) hasPixels = true;
        offset += length + 12;
        if (type == 'IEND') {
          complete = length == 0 && offset == bytes.length;
          break;
        }
      }
      if (!hasPixels || !complete) throw const FormatException('invalid-image');
    } else if (mime == 'image/jpeg' &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[bytes.length - 2] == 0xff &&
        bytes.last == 0xd9) {
      var offset = 2;
      while (offset + 4 <= bytes.length) {
        if (bytes[offset] != 0xff) break;
        final marker = bytes[offset + 1];
        if (marker == 0xda || marker == 0xd9) break;
        if (marker == 0xff) {
          offset++;
          continue;
        }
        if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd8)) {
          offset += 2;
          continue;
        }
        final length = data.getUint16(offset + 2);
        if (length < 2 || offset + 2 + length > bytes.length) break;
        if ({0xc0, 0xc1, 0xc2}.contains(marker) && length >= 8) {
          height = data.getUint16(offset + 5);
          width = data.getUint16(offset + 7);
          break;
        }
        offset += length + 2;
      }
    }
    if (width <= 0 ||
        height <= 0 ||
        width > 8192 ||
        height > 8192 ||
        width * height > 16000000) {
      throw const FormatException('invalid-image');
    }
  }
}

Never _invalid() => throw const FormatException('invalid-package');
double _coordinate(dynamic value, double fallback, {double minimum = 0}) {
  if (value == null) return fallback;
  if (value is! num || !value.isFinite || value < minimum || value > 1) {
    _invalid();
  }
  return value.toDouble();
}

Map<String, dynamic> _object(dynamic value, Set<String> allowed) {
  if (value is! Map<String, dynamic> ||
      value.keys.any((key) => !allowed.contains(key))) {
    _invalid();
  }
  return value;
}

String _string(dynamic value, int max) {
  if (value is! String || value.length > max) _invalid();
  return value;
}

String _id(dynamic value) {
  final id = _string(value, 128);
  if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) _invalid();
  return id;
}

int _integer(dynamic value, int min, int max) {
  if (value is! int || value < min || value > max) _invalid();
  return value;
}

bool _boolean(dynamic value) {
  if (value is! bool) _invalid();
  return value;
}

List<dynamic> _list(dynamic value, int max) {
  if (value is! List || value.length > max) _invalid();
  return value;
}
