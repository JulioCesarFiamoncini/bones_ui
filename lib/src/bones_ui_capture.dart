
import 'dart:html';
import 'dart:convert' as data_convert ;
import 'dart:typed_data';

import 'bones_ui_base.dart';
import 'bones_ui_component.dart';

import 'package:swiss_knife/swiss_knife.dart';

enum CaptureType {
  PHOTO,
  PHOTO_SELFIE,
  VIDEO,
  VIDEO_SELFIE,
  AUDIO
}

enum CaptureDataFormat {
  STRING,
  ARRAY_BUFFER,
  BASE64,
  DATA_URL_BASE64,
}

abstract class UICapture extends UIButton implements UIField {

  final CaptureType captureType ;

  String _fieldName ;

  UICapture(Element container, this.captureType, {String fieldName, String navigate, Map<String,String> navigateParameters, ParametersProvider navigateParametersProvider, dynamic classes}) :
      _fieldName = fieldName ,
      super(
          container, classes: classes,
          navigate: navigate, navigateParameters: navigateParameters, navigateParametersProvider: navigateParametersProvider
      )
  ;

  String get fieldName => _fieldName ?? 'capture' ;

  @override
  String renderHidden() {

    String capture ;
    String accept ;

    if ( captureType == CaptureType.PHOTO ) {
      accept = 'image/*' ;
      capture = 'environment';
    }
    else if ( captureType == CaptureType.PHOTO_SELFIE ) {
      accept = 'image/*' ;
      capture = 'user';
    }
    else if ( captureType == CaptureType.VIDEO ) {
      accept = 'video/*' ;
      capture = 'environment';
    }
    else if ( captureType == CaptureType.VIDEO_SELFIE ) {
      accept = 'video/*' ;
      capture = 'user';
    }
    else if ( captureType == CaptureType.AUDIO ) {
      accept = 'audio/*' ;
    }

    var input = '<input field="$fieldName" type="file"' ;

    input += accept != null ? " accept='$accept'" : '' ;
    input += capture != null ? " capture='$capture'" : ' capture' ;

    input += ' hidden>' ;

    UIConsole.log(input);

    return input ;
  }

  @override
  void posRender() {
    super.posRender();

    FileUploadInputElement fieldCapture = getInputCapture();
    fieldCapture.onChange.listen( (e) => _call_onCapture(fieldCapture, e) ) ;
  }

  void _call_onCapture(FileUploadInputElement input, Event event) async {
    await _readFile(input) ;
    onCapture(input, event) ;
  }

  void onCapture(FileUploadInputElement input, Event event) {
    var file = getInputFile() ;

    if ( file != null ) {
      UIConsole.log('onCapture> $input > $event > ${ event.type } > $file') ;
      UIConsole.log('file> ${ file.name } ; ${ file.type } ; ${ file.lastModified } ; ${ file.relativePath }') ;
    }
  }

  @override
  String getFieldValue() {
    return selectedFileDataAsDataURLBase64 ;
  }

  final EventStream<UICapture> onCaptureData = EventStream() ;

  File _selectedFile ;
  File get selectedFile => _selectedFile;

  Object _selectedFileData ;
  Object get selectedFileData => _selectedFileData;

  Uint8List get selectedFileDataAsArrayBuffer {
    if ( selectedFileData == null ) return null ;

    if ( _captureDataFormat == CaptureDataFormat.ARRAY_BUFFER ) {
      var data = _selectedFileData as Uint8List ;
      return data ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.STRING ) {
      var s = _selectedFileData as String ;
      var data = data_convert.latin1.encode(s) ;
      return data ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.BASE64 ) {
      var s = _selectedFileData as String ;
      return data_convert.base64.decode(s) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.DATA_URL_BASE64 ) {
      var s = _selectedFileData as String ;
      var idx = s.indexOf(',') ;
      var base64 = s.substring(idx+1) ;
      return data_convert.base64.decode(base64) ;
    }

    return null ;
  }

  String get selectedFileDataAsString {
    if ( selectedFileData == null ) return null ;

    if ( _captureDataFormat == CaptureDataFormat.ARRAY_BUFFER ) {
      var data = _selectedFileData as Uint8List ;
      return data_convert.latin1.decode(data) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.STRING ) {
      var s = _selectedFileData as String ;
      return s ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.BASE64 ) {
      var s = _selectedFileData as String ;
      var data = data_convert.base64.decode(s) ;
      return data_convert.latin1.decode(data) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.DATA_URL_BASE64 ) {
      var s = _selectedFileData as String ;
      var idx = s.indexOf(',') ;
      var base64 = s.substring(idx+1) ;
      var data = data_convert.base64.decode(base64) ;
      return data_convert.latin1.decode(data) ;
    }

    return null ;
  }


  String get selectedFileDataAsBase64 {
    if ( selectedFileData == null ) return null ;

    if ( _captureDataFormat == CaptureDataFormat.ARRAY_BUFFER ) {
      var data = _selectedFileData as Uint8List ;
      return data_convert.base64.encode(data) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.STRING ) {
      var s = _selectedFileData as String ;
      var data = data_convert.latin1.encode(s) ;
      return data_convert.base64.encode(data) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.BASE64 ) {
      return _selectedFileData as String ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.DATA_URL_BASE64 ) {
      var s = _selectedFileData as String ;
      var idx = s.indexOf(',') ;
      return s.substring(idx+1) ;
    }

    return null ;
  }

  String get selectedFileDataAsDataURLBase64 {
    if ( selectedFileData == null ) return null ;

    if ( _captureDataFormat == CaptureDataFormat.DATA_URL_BASE64 ) {
      var s = _selectedFileData as String ;
      return s ;
    }

    String base64 ;

    if ( _captureDataFormat == CaptureDataFormat.ARRAY_BUFFER ) {
      var data = _selectedFileData as Uint8List ;
      base64 = data_convert.base64.encode(data) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.STRING ) {
      var s = _selectedFileData as String ;
      var data = data_convert.latin1.encode(s) ;
      base64 = data_convert.base64.encode(data) ;
    }
    else if ( _captureDataFormat == CaptureDataFormat.BASE64 ) {
      base64 = _selectedFileData as String ;
    }
    else {
      return null ;
    }

    var mediaType = fileMimeType(_selectedFile) ;

    return toDataURLBase64(mediaType, base64) ;

  }

  String fileMimeType(File file) {
    var fileExtension = getPathExtension(file.name) ?? '' ;
    fileExtension = fileExtension.toLowerCase().trim() ;

    if (fileExtension == 'jpg') fileExtension = 'jpeg' ;

    var mediaType = '' ;

    if ( captureType == CaptureType.PHOTO || captureType == CaptureType.PHOTO_SELFIE ) {
      mediaType = 'image/$fileExtension' ;
    }
    else if ( captureType == CaptureType.VIDEO || captureType == CaptureType.VIDEO ) {
      mediaType = 'video/$fileExtension' ;
    }
    else if ( captureType == CaptureType.AUDIO ) {
      mediaType = 'audio/$fileExtension' ;
    }

    return mediaType ;
  }

  String toDataURLBase64(String mediaType, String base64) {
    return 'data:$mediaType;base64,$base64' ;
  }

  CaptureDataFormat _captureDataFormat = CaptureDataFormat.ARRAY_BUFFER ;

  CaptureDataFormat get captureDataFormat => _captureDataFormat ;

  set captureDataFormat(CaptureDataFormat dataFormat) {
    _captureDataFormat = dataFormat ?? CaptureDataFormat.ARRAY_BUFFER ;
  }

  void _readFile(FileUploadInputElement input) async{
    if ( input != null && input.files.isNotEmpty ) {
      var file = input.files.first;

      _selectedFile = file ;

      if ( _captureDataFormat == CaptureDataFormat.ARRAY_BUFFER ) {
        _selectedFileData = await readFileDataAsArrayBuffer(file) ;
      }
      else if ( _captureDataFormat == CaptureDataFormat.STRING ) {
        _selectedFileData = await readFileDataAsText(file) ;
      }
      else if ( _captureDataFormat == CaptureDataFormat.BASE64 ) {
        _selectedFileData = await readFileDataAsBase64(file) ;
      }
      else if ( _captureDataFormat == CaptureDataFormat.DATA_URL_BASE64 ) {
        _selectedFileData = await readFileDataAsDataURLBase64(file) ;
      }
      else {
        throw StateError("Can't capture data as format: $_captureDataFormat") ;
      }

      onCaptureData.add(this) ;
    }
  }

  Future<String> readFileDataAsDataURLBase64(File file) async {
    var base64 = await readFileDataAsBase64(file) ;
    var mediaType = fileMimeType(file) ;
    return toDataURLBase64(mediaType, base64) ;
  }

  Future<String> readFileDataAsBase64(File file) async {
    var data = await readFileDataAsArrayBuffer(file) ;
    return data_convert.base64.encode(data) ;
  }

  Future<Uint8List> readFileDataAsArrayBuffer(File file) async {
    final reader = FileReader() ;
    reader.readAsArrayBuffer( file ) ;
    await reader.onLoad.first ;
    var fileData = reader.result ;
    return fileData ;
  }

  Future<String> readFileDataAsText(File file) async {
    final reader = FileReader() ;
    reader.readAsText(file) ;
    await reader.onLoad.first ;
    var fileData = reader.result ;
    return fileData ;
  }

  @override
  void onClickEvent(event, List params) {
    FileUploadInputElement input = getInputCapture();
    input.value = null;
    input.click();
  }

  Element getInputCapture() => getFieldElement(fieldName);

  File getInputFile() {
    FileUploadInputElement input = getInputCapture();
    return input != null && input.files.isNotEmpty ? input.files[0] : null ;
  }

  bool isFileImage() {
    var file = getInputFile();
    return file != null && file.type.contains('image') ;
  }

  bool isFileVideo() {
    var file = getInputFile();
    return file != null && file.type.contains('video') ;
  }

  bool isFileAudio() {
    var file = getInputFile();
    return file != null && file.type.contains('audio') ;
  }

  ImageFileReader getImageFileReader() {
    var file = getInputFile();
    if ( file == null || !isFileImage() ) return null ;
    return ImageFileReader(file) ;
  }

  VideoFileReader getVideoFileReader() {
    var file = getInputFile();
    if ( file == null || !isFileVideo() ) return null ;
    return VideoFileReader(file) ;
  }

  AudioFileReader getAudioFileReader() {
    var file = getInputFile();
    if ( file == null || !isFileAudio() ) return null ;
    return AudioFileReader(file) ;
  }

}

class URLFileReader {
  final File _file ;

  URLFileReader(this._file) {
    var fileReader = FileReader();

    fileReader.onLoad.listen((e) {
      var dataURL = fileReader.result ;

      try {
        onLoad(dataURL, _file.type);
      } catch (e) {
        UIConsole.error('Error calling onLoad', e) ;
      }

      try {
        onLoadData.add(dataURL);
      } catch (e) {
        UIConsole.error('Error calling onLoadData controler', e) ;
      }
    });

    fileReader.readAsDataUrl(_file);
  }

  final EventStream<String> onLoadData = EventStream() ;

  void onLoad(String dataURL, String type) {

  }

}

class ImageFileReader extends URLFileReader {

  ImageFileReader(File file) : super(file) ;

  @override
  void onLoad(String dataURL, String type) {
    var img = ImageElement(src: dataURL) ;
    onLoadImage.add(img) ;
  }

  final EventStream<ImageElement> onLoadImage = EventStream() ;

}

class VideoFileReader extends URLFileReader {

  VideoFileReader(File file) : super(file) ;

  @override
  void onLoad(String dataURL, String type) {
    var video = VideoElement() ;
    video.controls = true ;

    var sourceElement = SourceElement();
    sourceElement.src = dataURL ;
    sourceElement.type = type ;

    video.children.add(sourceElement);

    onLoadVideo.add(video) ;
  }

  final EventStream<VideoElement> onLoadVideo = EventStream() ;

}

class AudioFileReader extends URLFileReader {

  AudioFileReader(File file) : super(file) ;

  @override
  void onLoad(String dataURL, String type) {
    var audio = AudioElement() ;
    audio.controls = true ;

    var sourceElement = SourceElement();
    sourceElement.src = dataURL ;
    sourceElement.type = type ;

    audio.children.add(sourceElement);

    onLoadAudio.add(audio) ;
  }

  final EventStream<AudioElement> onLoadAudio = EventStream() ;

}


class UIButtonCapturePhoto extends UICapture {
  final String text ;
  final String fontSize ;

  UIButtonCapturePhoto(Element parent, this.text, {String fieldName, String navigate, Map<String,String> navigateParameters, ParametersProvider navigateParametersProvider, dynamic classes, bool small = false, this.fontSize}) : super(
      parent, CaptureType.PHOTO, fieldName: fieldName, navigate: navigate, navigateParameters: navigateParameters, navigateParametersProvider: navigateParametersProvider, classes: classes
  )
  {
    configureClasses( classes , [ small ? 'ui-button-small' : 'ui-button' ] ) ;
  }

  @override
  void configure() {
    content.style.verticalAlign = 'middle' ;
  }

  @override
  String renderButton() {
    if (disabled) {
      content.style.opacity = '0.7' ;
    }
    else {
      content.style.opacity = null ;
    }

    if (fontSize != null) {
      return "<span style='font-size: $fontSize'>$text</span>" ;
    }
    else {
      return text ;
    }
  }

  int selectedImageMaxWidth = 100 ;
  int selectedImageMaxHeight = 100 ;

  bool _showSelectedImageInButton = true ;

  bool get showSelectedImageInButton => _showSelectedImageInButton;

  set showSelectedImageInButton(bool value) {
    _showSelectedImageInButton = value ?? false ;
  }

  @override
  void onCapture(FileUploadInputElement input, Event event) {
    if (_showSelectedImageInButton) {
      showSelectedImage() ;
    }
  }

  void showSelectedImage() {
    var dataURL = selectedFileDataAsDataURLBase64 ;
    if (dataURL == null) return ;

    content.children.removeWhere( (e) => (e is ImageElement || e is BRElement) ) ;

    var img = ImageElement(src: dataURL)
      ..style.padding = '2px 4px'
      ..style.maxHeight = '100%'
    ;

    if ( selectedImageMaxWidth != null ) {
      img.style.maxWidth = '${selectedImageMaxWidth}px' ;
    }

    if ( selectedImageMaxHeight != null ) {
      img.style.maxHeight = '${selectedImageMaxHeight}px' ;
    }

    content.children.add( BRElement() ) ;
    content.children.add(img) ;
  }

  void setWideButton() {
    content.style.width = '80%';
  }

  void setNormalButton() {
    content.style.width = null ;
  }

}

