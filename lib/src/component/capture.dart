import 'dart:convert' as data_convert;
import 'dart:html';
import 'dart:typed_data';

import 'package:dom_tools/dom_tools.dart';
import 'package:swiss_knife/swiss_knife.dart';

import '../bones_ui_base.dart';
import '../bones_ui_log.dart';
import 'button.dart';

enum CaptureType {
  photo,
  photoSelfie,
  photoFile,
  video,
  videoSelfie,
  videoFile,
  audioRecord,
  audioFile,
  json,
  file
}

enum CaptureDataFormat {
  string,
  arrayBuffer,
  base64,
  dataUrlBase64,
}

abstract class UICapture extends UIButtonBase implements UIField<String> {
  final CaptureType captureType;

  @override
  final String fieldName;

  UICapture(Element? container, this.captureType,
      {String? fieldName,
      String? navigate,
      Map<String, String>? navigateParameters,
      ParametersProvider? navigateParametersProvider,
      dynamic classes,
      dynamic classes2,
      dynamic style,
      dynamic componentClass})
      : fieldName = fieldName ?? 'capture',
        super(container,
            classes: classes,
            classes2: classes2,
            style: style,
            componentClass: ['ui-capture', componentClass],
            navigate: navigate,
            navigateParameters: navigateParameters,
            navigateParametersProvider: navigateParametersProvider);

  Set<String>? _acceptFilesExtensions;

  Set<String>? get acceptFilesExtensions =>
      isEmptyObject(_acceptFilesExtensions)
          ? null
          : Set.from(_acceptFilesExtensions!);

  void addAcceptFileExtension(String extension) {
    extension = _normalizeExtension(extension);
    if (extension.isEmpty) return;
    _acceptFilesExtensions ??= {};
    _acceptFilesExtensions!.add(extension);
  }

  bool removeAcceptFileExtension(String extension) {
    if (isEmptyObject(_acceptFilesExtensions)) return false;
    extension = _normalizeExtension(extension);
    if (extension.isEmpty) return false;
    return _acceptFilesExtensions!.remove(extension);
  }

  bool containsAcceptFileExtension(String extension) {
    if (isEmptyObject(_acceptFilesExtensions)) return false;
    extension = _normalizeExtension(extension);
    return _acceptFilesExtensions!.contains(extension);
  }

  void clearAcceptFilesExtensions() {
    if (isEmptyObject(_acceptFilesExtensions)) return;
    _acceptFilesExtensions!.clear();
  }

  String _normalizeExtension(String? extension) {
    if (extension == null) return '';
    extension = extension.trim();
    if (extension.isEmpty) return '';
    return extension.toLowerCase().replaceAll(RegExp(r'\W'), '');
  }

  @override
  String renderHidden() {
    String? capture;
    String? accept;

    switch (captureType) {
      case CaptureType.photo:
        {
          accept = 'image/*';
          capture = 'environment';
          break;
        }
      case CaptureType.photoSelfie:
        {
          accept = 'image/*';
          capture = 'user';
          break;
        }
      case CaptureType.photoFile:
        {
          accept = 'image/*';
          break;
        }
      case CaptureType.video:
        {
          accept = 'video/*';
          capture = 'environment';
          break;
        }
      case CaptureType.videoSelfie:
        {
          accept = 'video/*';
          capture = 'user';
          break;
        }
      case CaptureType.videoFile:
        {
          accept = 'video/*';
          break;
        }
      case CaptureType.audioRecord:
        {
          accept = 'audio/*';
          capture = 'environment';
          break;
        }
      case CaptureType.audioFile:
        {
          accept = 'audio/*';
          break;
        }
      case CaptureType.json:
        {
          accept = 'application/json';
          break;
        }
      default:
        break;
    }

    if (isNotEmptyObject(_acceptFilesExtensions)) {
      accept = accept == null ? '' : '$accept,';
      accept += _acceptFilesExtensions!.map((e) => '.$e').join(',');
    }

    var input = '<input field="$fieldName" type="file"';

    input += accept != null ? " accept='$accept'" : '';
    input += capture != null ? " capture='$capture'" : '';

    input += ' hidden>';

    UIConsole.log(input);

    return input;
  }

  @override
  void posRender() {
    super.posRender();

    var fieldCapture = getInputCapture() as FileUploadInputElement;
    fieldCapture.onChange.listen((e) => _callOnCapture(fieldCapture, e));
  }

  final EventStream<UICapture> onCapture = EventStream();

  void _callOnCapture(FileUploadInputElement input, Event event) async {
    await _readFile(input);
    onCaptureFile(input, event);
    onCapture.add(this);
  }

  void onCaptureFile(FileUploadInputElement input, Event event) {
    var file = getInputFile();

    if (file != null) {
      UIConsole.log('onCapture> $input > $event > ${event.type} > $file');
      UIConsole.log(
          'file> ${file.name} ; ${file.type} ; ${file.lastModified} ; ${file.relativePath}');
    }
  }

  @override
  String? getFieldValue() {
    return selectedFileDataAsDataURLBase64;
  }

  final EventStream<UICapture> onCaptureData = EventStream();

  File? _selectedFile;

  File? get selectedFile => _selectedFile;

  bool get hasSelectedFile => _selectedFile != null;

  Object? _selectedFileData;

  Object? get selectedFileData => _selectedFileData;

  Uint8List? get selectedFileDataAsArrayBuffer {
    if (selectedFileData == null) return null;

    if (captureDataFormat == CaptureDataFormat.arrayBuffer) {
      var data = _selectedFileData as Uint8List?;
      return data;
    } else if (captureDataFormat == CaptureDataFormat.string) {
      var s = _selectedFileData as String;
      var data = _dataEncoding!.encode(s);
      return data as Uint8List?;
    } else if (captureDataFormat == CaptureDataFormat.base64) {
      var s = _selectedFileData as String;
      return data_convert.base64.decode(s);
    } else if (captureDataFormat == CaptureDataFormat.dataUrlBase64) {
      return DataURLBase64.parsePayloadAsArrayBuffer(
          _selectedFileData as String);
    }

    return null;
  }

  data_convert.Encoding? _dataEncoding;

  data_convert.Encoding? get dataEncoding => _dataEncoding;

  set dataEncoding(data_convert.Encoding? value) {
    _dataEncoding = value ?? data_convert.latin1;
  }

  void setDataEncodingToLatin1() {
    _dataEncoding = data_convert.latin1;
  }

  void setDataEncodingToUTF8() {
    _dataEncoding = data_convert.utf8;
  }

  String? get selectedFileDataAsString {
    if (selectedFileData == null) return null;

    if (captureDataFormat == CaptureDataFormat.arrayBuffer) {
      var data = _selectedFileData as Uint8List;
      return _dataEncoding!.decode(data);
    } else if (captureDataFormat == CaptureDataFormat.string) {
      var s = _selectedFileData as String?;
      return s;
    } else if (captureDataFormat == CaptureDataFormat.base64) {
      var s = _selectedFileData as String;
      var data = data_convert.base64.decode(s);
      return _dataEncoding!.decode(data);
    } else if (captureDataFormat == CaptureDataFormat.dataUrlBase64) {
      return DataURLBase64.parsePayloadAsString(_selectedFileData as String);
    }

    return null;
  }

  String? get selectedFileDataAsBase64 {
    if (selectedFileData == null) return null;

    if (captureDataFormat == CaptureDataFormat.arrayBuffer) {
      var data = _selectedFileData as Uint8List;
      return data_convert.base64.encode(data);
    } else if (captureDataFormat == CaptureDataFormat.string) {
      var s = _selectedFileData as String;
      var data = _dataEncoding!.encode(s);
      return data_convert.base64.encode(data);
    } else if (captureDataFormat == CaptureDataFormat.base64) {
      return _selectedFileData as String?;
    } else if (captureDataFormat == CaptureDataFormat.dataUrlBase64) {
      var s = _selectedFileData as String?;
      return DataURLBase64.parsePayloadAsBase64(s);
    }

    return null;
  }

  String? get selectedFileDataAsDataURLBase64 {
    if (selectedFileData == null) return null;

    if (captureDataFormat == CaptureDataFormat.dataUrlBase64) {
      var s = _selectedFileData as String?;
      return s;
    }

    String? base64;

    if (captureDataFormat == CaptureDataFormat.arrayBuffer) {
      var data = _selectedFileData as Uint8List;
      base64 = data_convert.base64.encode(data);
    } else if (captureDataFormat == CaptureDataFormat.string) {
      var s = _selectedFileData as String;
      var data = _dataEncoding!.encode(s);
      base64 = data_convert.base64.encode(data);
    } else if (captureDataFormat == CaptureDataFormat.base64) {
      base64 = _selectedFileData as String?;
    } else {
      return null;
    }

    var mediaType = getFileMimeType(_selectedFile!);

    return toDataURLBase64(MimeType.asString(mediaType, ''), base64!);
  }

  CaptureDataFormat captureDataFormat = CaptureDataFormat.arrayBuffer;

  // Default true since not all popular browsers can't handle Exif yet:
  bool removeExifFromImage = true;

  Future<void> _readFile(FileUploadInputElement input) async {
    if (input.files!.isNotEmpty) {
      var file = input.files!.first;

      _selectedFile = file;
      _selectedFileData = null;

      if (captureDataFormat == CaptureDataFormat.arrayBuffer) {
        _selectedFileData =
            await readFileInputElementAsArrayBuffer(input, removeExifFromImage);
      } else if (captureDataFormat == CaptureDataFormat.string) {
        _selectedFileData =
            await readFileInputElementAsString(input, removeExifFromImage);
      } else if (captureDataFormat == CaptureDataFormat.base64) {
        _selectedFileData =
            await readFileInputElementAsBase64(input, removeExifFromImage);
      } else if (captureDataFormat == CaptureDataFormat.dataUrlBase64) {
        _selectedFileData = await readFileInputElementAsDataURLBase64(
            input, removeExifFromImage);
      } else {
        throw StateError("Can't capture data as format: $captureDataFormat");
      }

      onCaptureData.add(this);
      onChange.add(this);
    }
  }

  @override
  void onClickEvent(event, List? params) {
    var input = getInputCapture() as FileUploadInputElement;
    input.value = null;
    input.click();
  }

  Element? getInputCapture() => getFieldElement(fieldName);

  File? getInputFile() {
    var input = getInputCapture() as FileUploadInputElement?;
    return input != null && input.files!.isNotEmpty ? input.files![0] : null;
  }

  bool isFileImage() {
    var file = getInputFile();
    return file != null && file.type.contains('image');
  }

  bool isFileVideo() {
    var file = getInputFile();
    return file != null && file.type.contains('video');
  }

  bool isFileAudio() {
    var file = getInputFile();
    return file != null && file.type.contains('audio');
  }

  ImageFileReader? getImageFileReader() {
    var file = getInputFile();
    if (file == null || !isFileImage()) return null;
    return ImageFileReader(file);
  }

  VideoFileReader? getVideoFileReader() {
    var file = getInputFile();
    if (file == null || !isFileVideo()) return null;
    return VideoFileReader(file);
  }

  AudioFileReader? getAudioFileReader() {
    var file = getInputFile();
    if (file == null || !isFileAudio()) return null;
    return AudioFileReader(file);
  }
}

class URLFileReader {
  final File _file;

  URLFileReader(this._file) {
    var fileReader = FileReader();

    fileReader.onError.listen((event) {
      _notifyOnLoad(null);
    });

    fileReader.onLoad.listen((e) {
      var dataURL = fileReader.result as String;
      _notifyOnLoad(dataURL);
    });

    fileReader.readAsDataUrl(_file);
  }

  void _notifyOnLoad(String? dataURL) {
    try {
      onLoad(dataURL, _file.type);
    } catch (e) {
      UIConsole.error('Error calling onLoad', e);
    }

    try {
      onLoadData.add(dataURL);
    } catch (e) {
      UIConsole.error('Error calling onLoadData controler', e);
    }
  }

  final EventStream<String?> onLoadData = EventStream();

  void onLoad(String? dataURL, String type) {}
}

class ImageFileReader extends URLFileReader {
  ImageFileReader(File file) : super(file);

  @override
  void onLoad(String? dataURL, String type) {
    var img = ImageElement(src: dataURL);
    onLoadImage.add(img);
  }

  final EventStream<ImageElement> onLoadImage = EventStream();
}

class VideoFileReader extends URLFileReader {
  VideoFileReader(File file) : super(file);

  @override
  void onLoad(String? dataURL, String type) {
    var video = VideoElement();
    video.controls = true;

    var sourceElement = SourceElement();
    sourceElement.src = dataURL!;
    sourceElement.type = type;

    video.children.add(sourceElement);

    onLoadVideo.add(video);
  }

  final EventStream<VideoElement> onLoadVideo = EventStream();
}

class AudioFileReader extends URLFileReader {
  AudioFileReader(File file) : super(file);

  @override
  void onLoad(String? dataURL, String type) {
    var audio = AudioElement();
    audio.controls = true;

    var sourceElement = SourceElement();
    sourceElement.src = dataURL!;
    sourceElement.type = type;

    audio.children.add(sourceElement);

    onLoadAudio.add(audio);
  }

  final EventStream<AudioElement> onLoadAudio = EventStream();
}

class UIButtonCapturePhoto extends UICapture {
  final String? text;
  final dynamic buttonContent;

  final String? fontSize;

  UIButtonCapturePhoto(Element? parent,
      {this.text,
      CaptureType? captureType,
      this.buttonContent,
      String? fieldName,
      String? navigate,
      Map<String, String>? navigateParameters,
      ParametersProvider? navigateParametersProvider,
      dynamic classes,
      dynamic classes2,
      dynamic componentClass,
      dynamic style,
      bool small = false,
      this.fontSize})
      : super(parent, captureType ?? CaptureType.photo,
            fieldName: fieldName,
            navigate: navigate,
            navigateParameters: navigateParameters,
            navigateParametersProvider: navigateParametersProvider,
            style: style,
            classes: classes,
            classes2: classes2,
            componentClass: [
              small ? 'ui-button-small' : 'ui-button',
              componentClass
            ]) {
    configureClasses(classes, null, [small ? 'ui-button-small' : 'ui-button']);
  }

  @override
  void configure() {
    content!.style.verticalAlign = 'middle';
  }

  @override
  dynamic renderButton() {
    if (disabled) {
      content!.style.opacity = '0.7';
    } else {
      content!.style.opacity = '';
    }

    if (isNotEmptyString(text)) {
      if (fontSize != null) {
        return "<span style='font-size: $fontSize'>$text</span>";
      } else {
        return text;
      }
    } else if (buttonContent != null) {
      return buttonContent;
    } else {
      return 'Photo';
    }
  }

  int selectedImageMaxWidth = 100;

  int selectedImageMaxHeight = 100;

  bool onlyShowSelectedImageInButton = false;

  bool showSelectedImageInButton = true;

  List<String>? selectedImageClasses;
  String? selectedImageStyle;

  @override
  void onCaptureFile(FileUploadInputElement input, Event event) {
    if (showSelectedImageInButton) {
      showSelectedImage();
    }
  }

  final List<Element> _selectedImageElements = [];

  void showSelectedImage() {
    var dataURL = selectedFileDataAsDataURLBase64;
    if (dataURL == null) return;

    for (var e in _selectedImageElements) {
      content!.children.remove(e);
    }

    if (onlyShowSelectedImageInButton) {
      content!.children.removeWhere((e) => !e.hidden);
    }

    var img = ImageElement(src: dataURL)
      ..style.padding = '2px 4px'
      ..style.maxHeight = '100%';

    if (selectedImageMaxWidth > 0) {
      img.style.maxWidth = '${selectedImageMaxWidth}px';
    }

    if (selectedImageMaxHeight > 0) {
      img.style.maxHeight = '${selectedImageMaxHeight}px';
    }

    if (isNotEmptyObject(selectedImageClasses)) {
      img.classes.addAll(selectedImageClasses!);
    }

    if (isNotEmptyString(selectedImageStyle, trim: true)) {
      img.style.cssText = '${img.style.cssText ?? ''}; $selectedImageStyle';
    }

    _selectedImageElements.clear();
    if (!onlyShowSelectedImageInButton) {
      _selectedImageElements.add(BRElement());
    }
    _selectedImageElements.add(img);

    img.onClick.listen((e) => fireClickEvent(e));

    content!.children.addAll(_selectedImageElements);
  }

  void setWideButton() {
    content!.style.width = '80%';
  }

  void setNormalButton() {
    content!.style.width = null;
  }
}

class UIButtonCapture extends UICapture {
  final String text;

  final String? fontSize;

  UIButtonCapture(Element parent, this.text, CaptureType captureType,
      {String? fieldName,
      String? navigate,
      Map<String, String>? navigateParameters,
      ParametersProvider? navigateParametersProvider,
      dynamic classes,
      dynamic classes2,
      dynamic componentClass,
      dynamic style,
      bool small = false,
      this.fontSize})
      : super(parent, captureType,
            fieldName: fieldName,
            navigate: navigate,
            navigateParameters: navigateParameters,
            navigateParametersProvider: navigateParametersProvider,
            classes: classes,
            classes2: classes2,
            style: style,
            componentClass: [
              small ? 'ui-button-small' : 'ui-button',
              componentClass
            ]);

  @override
  void configure() {
    content!.style.verticalAlign = 'middle';
  }

  @override
  String renderButton() {
    if (disabled) {
      content!.style.opacity = '0.7';
    } else {
      content!.style.opacity = '';
    }

    if (fontSize != null) {
      return "<span style='font-size: $fontSize'>$text</span>";
    } else {
      return text;
    }
  }

  bool showSelectedFileInButton = true;

  @override
  void onCaptureFile(FileUploadInputElement input, Event event) {
    if (showSelectedFileInButton) {
      showSelectedFile();
    }
  }

  void showSelectedFile() {
    var dataURL = selectedFileDataAsDataURLBase64;
    if (dataURL == null) return;

    content!.children.removeWhere((e) => (e is SpanElement || e is BRElement));

    var fileName = selectedFile != null ? selectedFile!.name : null;

    if (fileName != null && fileName.isNotEmpty) {
      content!.children.add(BRElement());
      content!.children.add(SpanElement()..text = fileName);
    }
  }

  void setWideButton() {
    content!.style.width = '80%';
  }

  void setNormalButton() {
    content!.style.width = null;
  }
}
