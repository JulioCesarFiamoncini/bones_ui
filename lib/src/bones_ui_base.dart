import 'dart:async';
import 'dart:html';

import 'package:bones_ui/bones_ui.dart';
import 'package:intl/intl.dart';
import 'package:intl_messages/intl_messages.dart' ;
import 'package:swiss_knife/swiss_knife_browser.dart';
import 'package:dom_tools/dom_tools.dart';

import 'bones_ui_layout.dart';

typedef UIEventListener = void Function(dynamic event, List params) ;

abstract class UIEventHandler extends EventHandlerPrivate {

  void registerEventListener(String type, UIEventListener listener) {
    _registerEventListener(type, listener);
  }

  void fireEvent(String type, dynamic event, [List params]) {
    _fireEvent(type, event, params);
  }

}

abstract class EventHandlerPrivate {

  final Map<String, List<UIEventListener>> _eventListeners = {} ;

  void _registerEventListener(String type, UIEventListener listener) {
    var events = _eventListeners[type] ;
    if (events == null) _eventListeners[type] = events = [] ;
    events.add(listener) ;
  }

  void _fireEvent(String type, dynamic event, [List params]) {
    var eventListeners = _eventListeners[type] ;

    if (eventListeners != null) {
      try {
        for (var listener in eventListeners) {
          listener(event, params) ;
        }
      }
      catch (exception, stackTrace) {
        UIConsole.error('Error firing event: type: $type ; event: $event ; params: $params', exception, stackTrace);
      }
    }
  }

}

class UIConsole {

  static UIConsole _instance ;

  static UIConsole get() {
    _instance ??= UIConsole._internal();
    return _instance ;
  }

  /////////////////

  bool _enabled = false ;
  final List<String> _logs = [] ;

  int _limit = 10000 ;

  UIConsole._internal() {

    mapJSUIConsole();
  }

  static bool _mapJSUIConsole = false ;
  static void mapJSUIConsole() {
    if (_mapJSUIConsole) return ;
    _mapJSUIConsole = true ;

    try {
      mapJSFunction('UIConsole', (o) {
            UIConsole.log('JS> $o') ;
          });
    }
    catch (e) {
      UIConsole.error("Can't mapJSFunction: UIConsole", e) ;
    }
  }

  bool get enabled => _enabled ;

  int get limit => _limit ;

  set limit(int l) {
    if (l < 10) l = 10 ;
    _limit = l ;
  }

  static void enable() {
    get()._enable() ;
  }

  static final String SESSION_KEY_UIConsole_enabled = '__UIConsole__enabled' ;

  void _enable() {
    _enabled = true ;

    window.sessionStorage[SESSION_KEY_UIConsole_enabled] = '1' ;
  }

  static void checkAutoEnable() {
    if ( window.sessionStorage[SESSION_KEY_UIConsole_enabled] == '1' ) {
      displayButton() ;
    }
  }

  static void disable() {
    get()._disable() ;
  }

  void _disable() {
    _enabled = false ;

    window.sessionStorage[SESSION_KEY_UIConsole_enabled] = '0' ;
  }

  static List<String> logs() {
    return get()._getLogs() ;
  }

  List<String> _getLogs() {
    return List.from(_logs).cast() ;
  }

  static List<String> tail([int tailSize = 100]) {
    return get()._tail(tailSize) ;
  }

  List<String> _tail([int tailSize = 100]) {
    // ignore: omit_local_variable_types
    List<String> list = [] ;

    for (var i = _logs.length-tailSize; i < _logs.length; ++i) {
      list.add( _logs[i] );
    }

    return list ;
  }

  static List<String> head([int headSize = 100]) {
    return get()._head(headSize) ;
  }

  List<String> _head([int headSize = 100]) {
    // ignore: omit_local_variable_types
    List<String> list = [] ;

    if (headSize > _logs.length) headSize = _logs.length ;

    for (var i = 0; i < headSize; ++i) {
      list.add( _logs[i] );
    }

    return list ;
  }

  static void error(dynamic msg, [dynamic exception, StackTrace trace]) {
    return get()._error(msg, exception, trace) ;
  }

  void _error(dynamic msg, [dynamic exception, StackTrace trace]) {
    if (!_enabled) {
      if (exception != null) {
        msg += ' >> $exception' ;
      }

      window.console.error(msg) ;

      if (trace != null) {
        window.console.error(trace.toString()) ;
      }

      return ;
    }

    var now = DateTime.now();
    var log = 'ERROR> $now>  $msg' ;

    if (exception != null) {
      log += ' >> $exception' ;
    }

    _logs.add(log) ;

    if (trace != null) {
      _logs.add(trace.toString()) ;
    }

    while (_logs.length > _limit) {
      _logs.remove(0);
    }

    if (msg is String) {
      window.console.error(log);
    }
    else {
      window.console.error(msg);
    }

    if (trace != null) {
      window.console.error(trace.toString()) ;
    }
  }

  static void log(dynamic msg) {
    return get()._log(msg) ;
  }

  void _log(dynamic msg) {
    if (!_enabled) {
      print(msg) ;
      return ;
    }

    var now = DateTime.now();
    var log = '$now>  $msg' ;

    _logs.add(log) ;

    while (_logs.length > _limit) {
      _logs.remove(0);
    }

    if (msg is String) {
      print(log);
    }
    else {
      print(msg);
    }
  }

  static String allLogs() {
    return get()._allLogs() ;
  }

  String _allLogs() {
    var allLogs = _logs.join('\n');

    allLogs = allLogs.replaceAll('<', '&lt;') ;
    allLogs = allLogs.replaceAll('>', '&gt;') ;

    return allLogs ;
  }

  static void clear() {
    return get()._clear() ;
  }

  void _clear() {
    _logs.clear();
  }

  static bool isShowing() {
    return get()._isShowing() ;
  }

  bool _isShowing() {
    return querySelector('#UIConsole') != null ;
  }

  static void hide() {
    return get()._hide() ;
  }

  void _hide() {
    var prevConsoleDiv = querySelector('#UIConsole');

    if (prevConsoleDiv != null) {
      prevConsoleDiv.remove();
    }
  }

  static void show() {
    return get()._show() ;
  }

  DivElement _contentClipboard ;

  void _show() {
    _enable();

    _hide();

    var consoleDiv = DivElement();
    consoleDiv.id = 'UIConsole';

    consoleDiv.style
      ..position = 'absolute'
      ..width = '100%'
      ..height = '100%'
      ..left = '0px'
      ..top = '0px'
      ..padding = '6px 6px 7px 6px'
      ..color = '#ffffff'
      ..backgroundColor = 'rgba(0,0,0, 0.90)'
      ..zIndex = '100'
    ;

    var contentClipboard = createDivInline() ;

    contentClipboard.style
      ..width = '0px'
      ..height = '0px'
      ..lineHeight = '0px'
    ;

    consoleDiv.children.add(contentClipboard) ;

    var allLogs = _allLogs() ;

    var consoleButtons = DivElement();

    var buttonClose = Element.span()..text = '[X]' ;
    buttonClose.style.cursor = 'pointer';
    buttonClose.onClick.listen((m) => hide());

    var buttonCopy = Element.span()..text = '[Copy All]' ;
    buttonCopy.style.cursor = 'pointer';
    buttonCopy.onClick.listen((m) => copy());

    var buttonZoomIn = Element.span()..text = '[ + ]' ;
    buttonZoomIn.style.cursor = 'zoom-in';

    var buttonZoomOut = Element.span()..text = '[ - ]' ;
    buttonZoomOut.style.cursor = 'zoom-out';

    var buttonClear = Element.span()..text = '[Clear]' ;
    buttonClear.style.cursor = 'pointer';

    consoleButtons.children.add(buttonClose) ;
    consoleButtons.children.add(Element.span()..innerHtml = '&nbsp;&nbsp;') ;
    consoleButtons.children.add(buttonCopy) ;
    consoleButtons.children.add(Element.span()..innerHtml = '&nbsp;&nbsp;') ;
    consoleButtons.children.add(buttonZoomIn) ;
    consoleButtons.children.add(Element.span()..innerHtml = '&nbsp;&nbsp;') ;
    consoleButtons.children.add(buttonZoomOut) ;
    consoleButtons.children.add(Element.span()..innerHtml = '&nbsp;&nbsp;') ;
    consoleButtons.children.add(buttonClear) ;

    var consoleText = DivElement();
    consoleText.style.fontSize = '$_fontSize%';
    consoleText.style.overflow = 'scroll';

    var html =
        '<pre>\n'
        '${ allLogs }'
        '</pre>' ;

    setElementInnerHTML(consoleText, html);

    buttonClear.onClick.listen((m) {
      if (window.confirm('Clear UIConsole?')) {
        clear();
        consoleText.text = '';
      }
    });

    buttonZoomIn.onClick.listen((m) {
      _changeFontSize(consoleText, 1.05);
    });

    buttonZoomOut.onClick.listen((m) {
      _changeFontSize(consoleText, 0.95);
    });

    consoleDiv.children.add(consoleButtons);
    consoleDiv.children.add(consoleText);

    _contentClipboard = contentClipboard ;

    document.documentElement.children.add(consoleDiv);
  }

  double _fontSize = 100.0 ;

  void _changeFontSize(DivElement consoleText, double change) {
    var fontSizeProp = consoleText.style.fontSize ;

    var fontSize = fontSizeProp == null || fontSizeProp.isEmpty ? 100 : double.parse(fontSizeProp.replaceFirst('%', '')) ;
    var size = fontSize*change ;

    size = size.toInt().toDouble() ;

    if (size >= 96 && size <= 104) size = 100.0 ;

    if ( fontSize == size ) {
      if (change > 1) {
        size++ ;
      }
      else {
        size-- ;
      }
    }

    if (size < 50) {
      size = 30.0 ;
    }
    else if (size > 300) {
      size = 300.0 ;
    }

    consoleText.style.fontSize = '$size%' ;

    _fontSize = size ;
  }

  static void copy() {
    get()._copy() ;
  }

  void _copy() {
    var allLogs = _allLogs();

    if (_contentClipboard != null) {
      _contentClipboard.innerHtml = '<pre>${allLogs}</pre>';
      _copyElementToClipboard(_contentClipboard);
      _contentClipboard.text = '';
    }
  }

  void _copyElementToClipboard(Element elem) {
    var selection = window.getSelection();
    var range = document.createRange();

    range.selectNodeContents(elem);
    selection.removeAllRanges();
    selection.addRange(range);

    var selectedText = selection.toString();

    document.execCommand('copy');

    if (selectedText != null) {
      window.getSelection().removeAllRanges();
    }
  }

  static DivElement button([double opacity = 0.20]) {
    enable();

    var elem = createDivInline('[>_]') ;

    elem.id = 'UIConsole_button' ;

    elem.style
      ..backgroundColor = 'rgba(0,0,0, 0.5)'
      ..color = 'rgba(0,255,0, 0.5)'
      ..fontSize = '14px'
      ..opacity = '$opacity'
    ;

    elem.onClick.listen((m) => isShowing() ? hide() : show());

    return elem ;
  }

  static void displayButton() {
    var prevElem = querySelector('#UIConsole_button');
    if (prevElem != null) return ;

    var elem = button(1.0);

    print('Button: ${ elem.clientHeight }');

    elem.style
      ..position = 'fixed'
      ..left = '0px'
      ..top = '100%'
      ..transform = 'translateY(-15px)'
      ..zIndex = '999999'
    ;

    document.body.children.add(elem);
  }

}

class UIDeviceOrientation extends EventHandlerPrivate {

  static final EVENT_CHANGE_ORIENTATION = 'CHANGE_ORIENTATION' ;

  static UIDeviceOrientation _instance ;

  static UIDeviceOrientation get() {
    _instance ??= UIDeviceOrientation._internal();
    return _instance ;
  }

  UIDeviceOrientation._internal() {
    window.onDeviceOrientation.listen(_onChangeOrientation);
  }

  static void listen(UIEventListener listener) {
    get()._listen(listener);
  }

  void _listen(UIEventListener listener) {
    _registerEventListener(EVENT_CHANGE_ORIENTATION, listener);
  }

  var _lastOrientation ;

  void _onChangeOrientation(DeviceOrientationEvent event) {
    var orientation = window.orientation ;

    if ( _lastOrientation != orientation ) {
      _fireEvent(EVENT_CHANGE_ORIENTATION, event, [orientation]) ;
    }

    _lastOrientation = orientation ;
  }

  static bool isLandscape() {
    var orientation = window.orientation ;
    if (orientation == null) return false ;
    return orientation == -90 || orientation == 90 ;
  }

}

bool isComponentInDOM(dynamic element) {
  if (element == null) return false ;

  if (element is Node) {
    return document.body.contains(element);
  }
  else if (element is UIComponent) {
    return isComponentInDOM(element.renderedElements) ;
  }
  else if (element is UIAsyncContent) {
    return isComponentInDOM(element.content) ;
  }
  else if (element is List) {
    for (var elem in element) {
      var inDom = isComponentInDOM(elem);
      if (inDom) return true ;
    }
    return false ;
  }

  return false ;
}

bool canBeInDOM(dynamic element) {
  if (element == null) return false ;

  if (element is Node) {
    return true ;
  }
  else if (element is UIComponent) {
    return true ;
  }
  else if (element is UIAsyncContent) {
    return true ;
  }
  else if (element is List) {
    return true ;
  }

  return false ;
}

typedef FilterRendered = bool Function( dynamic elem ) ;
typedef FilterElement = bool Function( Element elem ) ;
typedef ForEachElement = void Function( Element elem ) ;
typedef ParametersProvider = Map<String,String> Function() ;

abstract class UIComponent extends UIEventHandler {

  dynamic id ;

  UIComponent _parentUIComponent ;
  Element _parent ;
  Element _content ;

  bool _constructing ;
  bool get constructing => _constructing ;

  UIComponent(this._parent, {dynamic classes, dynamic classes2, bool inline = true, bool renderOnConstruction}) {
    _constructing = true ;
    try {
      _parentUIComponent = _getUIComponentRenderingByContent(_parent) ;
      _content = createContentElement(inline);

      configureClasses(classes, classes2);

      configure();

      _parent.children.add(_content);

      renderOnConstruction ??= this.renderOnConstruction();

      if (renderOnConstruction != null && renderOnConstruction) {
        callRender();
      }
    }
    finally {
      _constructing = false ;
    }
  }

  Element setParent(Element parent) {
    if (_parent != null && _content != null ) {
      _parent.children.remove(_content);
    }

    _parent = parent ;

    if (_content != null ) {
      _parent.children.add(_content);
    }

    return parent ;
  }

  UIComponent get parentUIComponent {
    if ( _parentUIComponent != null ) return _parentUIComponent ;

    var myParentElem = parent;

    var foundParent = _getUIComponentRenderingByContent( myParentElem ) ;

    if (foundParent != null) {
      _parentUIComponent = foundParent ;
      return _parentUIComponent ;
    }

    var uiRoot = UIRoot.getInstance() ;
    if (uiRoot == null) return null ;

    foundParent = uiRoot.getRenderedElement( (e) => e is UIComponent && identical(e._content, myParentElem) , true );

    if (foundParent != null && foundParent is UIComponent) {
      _parentUIComponent = foundParent ;
    }

    return _parentUIComponent ;
  }

  bool _showing = true ;
  String _displayOnHidden ;

  void hide() {
    _content.hidden = true ;

    if (_showing) {
      _displayOnHidden = _content.style.display ;
    }
    _content.style.display = 'none';

    _showing = false ;
  }

  void show() {
    _content.hidden = false ;

    if (!_showing) {
      _content.style.display = _displayOnHidden;
      _displayOnHidden = null;
    }

    _showing = true ;
  }

  bool get isInDOM {
    return isNodeInDOM( _content ) ;
  }

  List<String> _normalizeClasses(classes) {
    if (classes == null) return [] ;

    List<String> classesNames ;

    if (classes is List) {
      classesNames = classes.map((d) => d != null ? d.toString() : '').where((s) => s.isNotEmpty).toList() ;
    }
    else {
      var className = classes.toString() ;
      classesNames = [className] ;
    }

    classesNames.removeWhere( (s) => s == null || s.isEmpty ) ;

    return classesNames ;
  }

  void configureClasses(classes1, classes2) {
    var classesNames1 = _normalizeClasses(classes1) ;
    var classesNames2 = _normalizeClasses(classes2) ;

    classesNames1.addAll(classesNames2) ;

    // ignore: omit_local_variable_types
    List<String> classesNamesRemove = List.from(classesNames1) ;
    classesNamesRemove.retainWhere((s) => s.startsWith('!')) ;

    classesNames1.removeWhere((s) => s.startsWith('!')) ;
    if ( classesNames1.isNotEmpty ) content.classes.addAll(classesNames1);

    if ( classesNamesRemove.isNotEmpty ) {
      classesNamesRemove = classesNamesRemove.map((s) => s.replaceFirst('!', '')).toList() ;
      content.classes.removeAll(classesNamesRemove) ;
    }

  }

  bool renderOnConstruction() => true ;

  void configure() {

  }

  Element createContentElement(bool inline) {
    return createDiv(inline);
  }

  Element get parent => _parent;
  Element get content => _content;

  List _renderedElements ;

  List get renderedElements => _renderedElements ;

  dynamic getRenderedElement( FilterRendered filter , [bool deep]) {
    if (_renderedElements == null) return null ;

    for (var elem in _renderedElements) {
      if ( filter(elem) ) return elem ;
    }

    deep ??= false ;

    if (deep) {
      for (var elem in _renderedElements) {
        if ( elem is UIComponent ) {
          var found = elem.getRenderedElement( filter , deep ) ;
          if (found != null) {
            return found ;
          }
        }
      }
    }

    return null ;
  }

  dynamic getRenderedElementById(dynamic id) {
    if (_renderedElements == null) return null ;

    for (var elem in _renderedElements) {
      if ( elem is UIComponent ) {
        if ( elem.id == id ) {
          return elem;
        }
      }
      else if ( elem is Element ) {
        if ( elem.id == id ) {
          return elem;
        }
      }
    }

    return null ;
  }

  UIComponent getRenderedUIComponentById(dynamic id) {
    if (_renderedElements == null) return null ;

    for (var elem in _renderedElements) {
      if ( elem is UIComponent ) {
        if ( elem.id == id ) {
          return elem;
        }
      }
    }

    return null ;
  }

  List<UIComponent> getRenderedUIComponentsByIds(List ids) {
    // ignore: omit_local_variable_types
    List<UIComponent> elems = [] ;

    for (var id in ids) {
      var comp = getRenderedUIComponentById(id) ;
      if (comp != null) elems.add(comp) ;
    }

    return elems ;
  }

  UIComponent getRenderedUIComponentByType(Type type) {
    if (_renderedElements == null) return null ;

    for (var elem in _renderedElements) {
      if ( elem is UIComponent ) {
        if ( elem.runtimeType == type ) {
          return elem;
        }
      }
    }

    return null ;
  }

  List<UIComponent> getRenderedUIComponents() {
    if (_renderedElements == null) return []  ;

    // ignore: omit_local_variable_types
    List<UIComponent> list = [] ;

    for (var elem in _renderedElements) {
      if ( elem is UIComponent ) {
        list.add(elem) ;
      }
    }

    return list ;
  }

  bool _rendered = false ;

  bool isRendered() {
    return _rendered ;
  }

  void clear() {
    if ( !isRendered() ) return ;

    if (_renderedElements != null) {
      for (var e in _renderedElements) {
        if (e is UIComponent) {
          e.delete();
        }
        else if (e is Element) {
          e.remove();
        }
      }
    }

    var elems = List.from( _content.children ) ;
    elems.forEach((e) => e.remove());

    _content.children.clear();

    _rendered = false ;
  }

  bool __refreshFromExternalCall = false ;

  bool get isRefreshFromExternalCall => __refreshFromExternalCall ;

  void _refreshInternal() {
    _refreshImpl();
  }

  void refreshInternal() {
    _refreshImpl();
  }

  void refresh() {
    try {
      __refreshFromExternalCall = true ;

      _refreshImpl();
    }
    finally {
      __refreshFromExternalCall = false ;
    }
  }

  void _refreshImpl() {
    if ( !isRendered() ) return ;
    clear();
    callRender();
  }

  void refreshIfLocaleChanged() {
    try {
      __refreshFromExternalCall = true ;

      _refreshIfLocaleChangedImpl();
    }
    finally {
      __refreshFromExternalCall = false ;
    }
  }

  void _refreshIfLocaleChangedImpl() {
    if ( !isRendered() ) return ;
    if ( localeChangeFromLastRender ) {
      UIConsole.log('Locale changed: $_renderLocale -> ${ UIRoot.getCurrentLocale() } ; Refreshing...') ;
      clear();
      callRender();
    }
  }

  void delete() {
    clear();
    content.remove();
  }

  void ensureRendered() {
    if ( !isRendered() ) callRender() ;
  }

  bool isAccessible() {
    return true ;
  }

  String deniedAccessRoute() {
    return null ;
  }

  void callRenderAsync() {
    Future.microtask(callRender) ;
  }

  bool get localeChangeFromLastRender {
    var currentLocale = UIRoot.getCurrentLocale();
    return _renderLocale != currentLocale ;
  }

  static final Map<Element,UIComponent> _componentsRendering = {} ;

  static void _setUIComponentRendering( UIComponent component ) {
    if (component == null) return ;
    _componentsRendering[ component.content ] = component ;
  }

  static void _clearUIComponentRendering( UIComponent component ) {
    if (component == null) return ;
    _componentsRendering.remove( component.content ) ;
  }

  static UIComponent _getUIComponentRenderingByContent( Element content ) {
    if (content == null) return null ;
    return _componentsRendering[content] ;
  }

  bool _rendering = false ;

  bool get isRendering => _rendering;

  void callRender() {
    _setUIComponentRendering(this) ;

    _rendering = true ;
    try {
      _callRenderImpl() ;
    }
    finally {
      _rendering = false ;

      try {
        _notifyRenderToParent() ;
      }
      catch (e,s) {
        UIConsole.error('$this _notifyRefreshToParent error', e, s);
      }

      _clearUIComponentRendering(this) ;
    }
  }

  String _renderLocale ;

  void _callRenderImpl() {
    var currentLocale = UIRoot.getCurrentLocale();

    _renderLocale = currentLocale ;

    try {
      if ( !isAccessible() ) {
        UIConsole.log('Not accessible: $this');

        _rendered = true ;

        var redirectToRoute = deniedAccessRoute();

        if (redirectToRoute != null) {
          if ( !isInDOM ) {
            UIConsole.log('[NOT IN DOM] Denied access to route: $redirectToRoute');
          }
          else {
            UIConsole.log('Denied access to route: $redirectToRoute');
            UINavigator.navigateTo(redirectToRoute) ;
          }
        }

        return ;
      }
    }
    catch (e,s) {
      UIConsole.error('$this isAccessible error', e, s) ;
      return ;
    }

    try {
      _rendered = true ;

      _clearFields() ;

      var rendered = render() ;

      var renderedElements = toContentElements(content, rendered) ;

      _renderedElements = renderedElements ;

      for (var e in renderedElements) {
        if (e is UIComponent) {
          e.ensureRendered();
        }
      }
    }
    catch (e,s) {
      UIConsole.error('$this render error', e, s);
    }

    try {
      _parseAttributesPosRender(content.children);
    }
    catch (e,s) {
      UIConsole.error('$this _parseAttributesPosRender(...) error', e, s);
    }

    try {
      _parseAttributesPosRender(content.children);
      posRender();
    }
    catch (e,s) {
      UIConsole.error('$this posRender error', e, s);
    }

    _markRenderTime() ;
  }

  void _notifyRenderToParent() {
    var parentUIComponent = this.parentUIComponent ;

    if (parentUIComponent == null) {
      return ;
    }

    try {
      parentUIComponent.onChildRendered( this ) ;
    }
    catch (e,s) {
      print(e) ;
      print(s) ;
    }
  }

  void onChildRendered( dynamic child ) {

  }

  static int _lastRenderTime ;
  static bool _renderFinished = true ;

  static void _markRenderTime() {
    _lastRenderTime = DateTime.now().millisecondsSinceEpoch ;
    _renderFinished = false ;
    _scheduleCheckFinishedRendered() ;
  }

  static void _scheduleCheckFinishedRendered() {
    Future.delayed( Duration(milliseconds: 300) , _checkFinishedRendered) ;
  }

  static void _checkFinishedRendered() {
    if (_renderFinished) return ;

    var now = DateTime.now().millisecondsSinceEpoch ;
    var delay = now - _lastRenderTime ;

    if (delay > 100) {
      _notifyFinishRendered() ;
    }
    else {
      _scheduleCheckFinishedRendered() ;
    }
  }

  static void _notifyFinishRendered() {
    if ( _renderFinished ) return ;
    _renderFinished = true ;

    if ( UILayout.someInstanceNeedsRefresh() ) {
      UILayout.refreshAll();
    }
    else {
      UILayout.checkInstances();
    }

    var uiRoot = UIRoot.getInstance();

    uiRoot.onFinishRender.add(uiRoot) ;
  }

  dynamic render() ;

  void posRender() {}

  List toContentElements(Element content, dynamic rendered, [bool append = false]) {
    try {
      var list = _toContentElementsImpl(content, rendered, append) ;

      _parseAttributes(content.children);

      return list ;
    }
    catch (e,s) {
      print(e);
      print(s);
      return [] ;
    }
  }

  List _toContentElementsImpl(Element content, dynamic rendered, bool append) {
    List renderedList ;

    if (rendered != null) {
      if (rendered is List) {
        renderedList = rendered ;
      }
      else {
        renderedList = [ rendered ] ;
      }
    }

    if (renderedList != null) {
      if ( isListOfStrings(renderedList) ) {
        var html = renderedList.join('\n');

        if (append) {
          appendElementInnerHTML(content, html) ;
        }
        else {
          setElementInnerHTML(content, html);
        }

        var list = List.from(content.childNodes);
        return list ;
      }
      else {
        for (var value in renderedList) {
          _removeContent(value) ;
        }

        var renderedList2 = [] ;

        var prevElemIndex = -1 ;

        for (var value in renderedList) {
          prevElemIndex = _buildRenderList(value, renderedList2, prevElemIndex) ;
        }

        return renderedList2 ;
      }
    }
    else {
      return List.from(content.childNodes);
    }
  }

  int _buildRenderList(dynamic value, List renderedList, int prevElemIndex) {
    if ( value is Element ) {
      var idx = content.childNodes.indexOf(value);

      if ( idx < 0 ) {
        content.children.add(value);
        idx = content.childNodes.indexOf(value);
      }

      prevElemIndex = idx ;
      renderedList.add(value);
    }
    else if ( value is UIComponent ) {
      var idx = content.childNodes.indexOf(value.content);

      if ( idx < 0 ) {
        content.children.add(value.content);
        idx = content.childNodes.indexOf(value.content);
      }
      else if ( idx < prevElemIndex ) {
        value.content.remove();
        content.children.add(value.content);
        idx = content.childNodes.indexOf(value.content);
      }

      prevElemIndex = idx ;
      renderedList.add(value);
    }
    else if ( value is UIAsyncContent ) {
      if ( !value.isLoaded || value.hasAutoRefresh ) {
        value.onLoadContent.listen( (c) {
          print('Loaded content: $c') ;
          refresh() ;
        } , singletonIdentifier: this ) ;
      }

      if ( value.isExpired ) {
        value.refreshAsync() ;
      }
      else if ( value.isWithError ) {
        if ( value.hasAutoRefresh ) {
          value.reset();
        }
      }

      var content = value.content ;
      prevElemIndex = _buildRenderList(content, renderedList, prevElemIndex) ;
    }
    else if ( value is List ) {
      for (var elem in value) {
        prevElemIndex = _buildRenderList(elem, renderedList, prevElemIndex) ;
      }
    }
    else if ( value is String ) {
      if ( prevElemIndex < 0 ) {
        setElementInnerHTML(content, value);
        prevElemIndex = content.childNodes.length-1 ;

        renderedList.addAll( content.childNodes ) ;
      }
      else {
        var preAppendSize = content.childNodes.length;

        appendElementInnerHTML(content, value) ;

        var appendedElements = content.childNodes.sublist(preAppendSize, content.childNodes.length) ;

        if (prevElemIndex == preAppendSize-1) {
          prevElemIndex = content.childNodes.length-1 ;
        }
        else {
          if ( appendedElements.isNotEmpty ) {
            for (var elem in appendedElements) {
              elem.remove();
            }

            var restDyn = copyList( content.childNodes.length >= prevElemIndex ? content.childNodes.sublist(prevElemIndex+1) : null ) ;

            // ignore: omit_local_variable_types
            List<Node> rest = restDyn.cast() ;

            for (var elem in rest) {
              elem.remove();
            }

            appendedElements.forEach( (n) => content.append(n) ) ;
            rest.forEach( (n) => content.append(n) ) ;

            prevElemIndex = content.childNodes.indexOf(appendedElements[0]) ;
          }
        }

        renderedList.addAll( appendedElements ) ;
      }
    }

    return prevElemIndex ;
  }

  void _removeContent(dynamic value) {
    if (value == null) return ;

    if (value is Element) {
      value.remove();
    }
    else if (value is UIComponent) {
      if (value.isRendered()) {
        value.content.remove();
      }
    }
    else if (value is UIAsyncContent) {
      _removeContent( value.loadingContent ) ;
      _removeContent( value.content ) ;
    }
    else if (value is List) {
      for (var val in value) {
        _removeContent( val ) ;
      }
    }
  }

  void _parseAttributes(List list) {
    for (var elem in list) {
      if (elem is Element) {
        _parseNavigate(elem);
        _parseAction(elem);
        _parseField(elem);
        _parseEvents(elem);

        try {
          _parseAttributes( elem.children ) ;
        }
        catch (e) {
          UIConsole.error('Error parsing attributes for element: $elem', e);
        }
      }
    }
  }

  void _parseAttributesPosRender(List list) {
    if (list == null || list.isEmpty) return ;

    for (var elem in list) {
      if (elem is Element) {
        try {
          _parseUiLayout(elem);
        }
        catch (e) {
          UIConsole.error('Error parsing attributes for element: $elem', e);
        }

        try {
          _parseAttributesPosRender( elem.children ) ;
        }
        catch (e) {
          UIConsole.error('Error parsing attributes for element: $elem', e);
        }
      }
    }
  }

  //////////////////////

  void _parseNavigate(Element elem) {
    var navigateRoute = getElementAttribute(elem,'navigate');

    if (navigateRoute != null && navigateRoute.isNotEmpty) {
      UINavigator.navigateOnClick(elem, navigateRoute);
    }
  }

  //////////////////////

  final Map<String,Element> _fields = {} ;

  Map<String,String> getFields( {List<String> ignore} ) {
    // ignore: omit_local_variable_types
    Map<String,String> map = {} ;

    for (var k in _fields.keys) {
      if ( ignore != null && ignore.contains(k) ) continue;

      var val = getField(k) ;
      if (val != null) {
        map[k] = val ;
      }
    }

    return map ;
  }

  String getField(String fieldName) {
    var fieldElem = _fields[fieldName] ;
    if (fieldElem == null) return null ;

    return parseFieldValue(fieldElem);
  }

  String parseFieldValue(Element fieldElem) {
    if ( fieldElem is InputElement ) {
      return fieldElem.value ;
    }
    else if ( fieldElem is TextAreaElement ) {
      return fieldElem.value ;
    }
    else {
      return fieldElem.text ;
    }
  }

  Element getFieldElement(String fieldName) {
    var fieldElem = _fields[fieldName] ;
    return fieldElem ;
  }

  void setField(String fieldName, var value) {
    var fieldElem = _fields[fieldName] ;
    if (fieldElem == null) return ;

    if ( fieldElem is InputElement ) {
      fieldElem.value = value ;
    }
    else {
      fieldElem.text = value ;
    }
  }

  void _clearFields() {
    _fields.clear() ;
  }

  void _parseField(Element elem) {
    var fieldName = getElementAttribute(elem,'field');

    if (fieldName != null && fieldName.isNotEmpty) {
      _fields[fieldName] = elem ;
    }
  }

  bool hasEmptyField() {
    for( var field in _fields.values ) {
      var val = parseFieldValue(field) ;
      if ( val == null || val.toString().isEmpty ) return true ;
    }
    return false ;
  }

  List<String> getFieldsNames() => List.from( _fields.keys ) ;

  List<Element> getFieldsElements() => List.from( _fields.values ) ;

  bool isEmptyField(String fieldName) {
    var fieldElement = getFieldElement(fieldName) ;
    var val = parseFieldValue( fieldElement ) ;
    return val == null || val.toString().isEmpty ;
  }

  List<String> getEmptyFields() {
    // ignore: omit_local_variable_types
    List<String> emptyFields = [] ;

    for( var entry in _fields.entries ) {
      var val = parseFieldValue( entry.value ) ;
      if ( val == null || val.toString().isEmpty ) {
        emptyFields.add( entry.key ) ;
      }
    }
    return emptyFields ;
  }

  int forEachFieldElement( ForEachElement f ) {
    var count = 0 ;

    for ( var elem in getFieldsElements() ) {
      f(elem) ;
      count++ ;
    }

    return count ;
  }

  int forEachEmptyFieldElement( ForEachElement f ) {
    var count = 0 ;

    var list = getEmptyFields() ;
    for ( var fieldName in list ) {
      var elem = getFieldElement(fieldName) ;
      if ( elem != null ) {
        f(elem) ;
        count++ ;
      }
    }

    return count ;
  }

  //////////////////////

  void _parseAction(Element elem) {
    var actionValue = getElementAttribute(elem,'action');

    if (actionValue != null && actionValue.isNotEmpty) {
      elem.onClick.listen( (e) => action(actionValue) ) ;
    }
  }

  void action(String action) {
    UIConsole.log('action: $action') ;
  }

  //////////////////////

  void _parseUiLayout(Element elem) {
    var uiLayout = getElementAttribute(elem,'uiLayout');

    if (uiLayout != null) {
      UILayout(this, elem , uiLayout) ;
    }
  }

  //////////////////////

  void _parseEvents(Element elem) {
    _parseOnEventKeyPress(elem);
    _parseOnEventClick(elem);
  }

  void _parseOnEventKeyPress(Element elem) {
    var keypress = getElementAttribute(elem,'onEventKeyPress');

    if (keypress != null && keypress.isNotEmpty) {
      var parts = keypress.split(':');
      var key = parts[0].trim() ;
      var actionType = parts[1] ;

      if (key == '*') {
        elem.onKeyPress.listen((e) {
          action(actionType);
        });
      }
      else {
        elem.onKeyPress.listen((e) {
          if ( e.key == key || e.keyCode.toString() == key ) {
            action(actionType);
          }
        });
      }
    }
  }

  void _parseOnEventClick(Element elem) {
    var click = getElementAttribute(elem,'onEventClick');

    if (click != null && click.isNotEmpty) {
      elem.onClick.listen((e) {
        action(click);
      });
    }
  }

  //////////////////////


// Dart 2 Mirrors is not stable yet:
/*
  InstanceMirror _instanceMirror ;

  InstanceMirror getInstanceMirror() {
    if (_instanceMirror == null) {
      _instanceMirror = reflect(this);
    }
    return _instanceMirror;
  }

  void _parseFields(Element elem) {
      var fieldName = elem.getAttribute("field");

      if (fieldName != null && fieldName.isNotEmpty) {
        var instanceMirror = getInstanceMirror();

        try {
          var symbol = MirrorSystem.getSymbol(fieldName);
          UIConsole.log("SET> $instanceMirror > $symbol > $elem");
          instanceMirror.setField(symbol, elem).reflectee ;
        }
        catch (e) {
          UIConsole.log("Error setting field: $e");
        }

      }
  }

  */



}

abstract class UINavigableContent extends UINavigableComponent {

  int topMargin ;

  UINavigableContent(Element parent, List<String> routes, {this.topMargin, dynamic classes, dynamic classes2, bool inline = true, bool renderOnConstruction = false} ) : super(parent, routes, classes: classes, classes2: classes2, inline: inline, renderOnConstruction: renderOnConstruction) ;

  @override
  dynamic render() {
    // ignore: omit_local_variable_types
    List allRendered = [] ;

    if (topMargin != null && topMargin > 0) {
      var divTopMargin = Element.div();
      divTopMargin.style.width = '100%' ;
      divTopMargin.style.height = '${topMargin}px' ;

      allRendered.add(divTopMargin) ;
    }

    var headRendered = renderRouteHead(currentRoute , _currentRouteParameters);
    var contentRendered = renderRoute(currentRoute , _currentRouteParameters) ;
    var footRendered = renderRouteFoot(currentRoute , _currentRouteParameters);

    addAllToList(allRendered, headRendered) ;
    addAllToList(allRendered, contentRendered) ;
    addAllToList(allRendered, footRendered) ;

    if (_findRoutes != null && _findRoutes) {
      _updateRoutes();
    }

    return allRendered ;
  }

  dynamic renderRouteHead(String route, Map<String,String> parameters) { return null ;}
  dynamic renderRouteFoot(String route, Map<String,String> parameters) { return null ;}

}



abstract class UIContent extends UIComponent {

  int topMargin ;

  UIContent(Element parent, {this.topMargin, dynamic classes, dynamic classes2, bool inline = true, bool renderOnConstruction} ) : super(parent, classes: classes, classes2: classes2, inline: inline, renderOnConstruction: renderOnConstruction) ;

  @override
  List render() {
    // ignore: omit_local_variable_types
    List allRendered = [] ;

    if (topMargin != null && topMargin > 0) {
      var divTopMargin = Element.div();
      divTopMargin.style.width = '100%' ;
      divTopMargin.style.height = '${topMargin}px' ;

      allRendered.add(divTopMargin) ;
    }

    var headRendered = renderHead();
    var contentRendered = renderContent() ;
    var footRendered = renderFoot();

    addAllToList(allRendered, headRendered) ;
    addAllToList(allRendered, contentRendered) ;
    addAllToList(allRendered, footRendered) ;

    return allRendered ;
  }

  dynamic renderHead() { return null ;}
  dynamic renderContent();
  dynamic renderFoot() { return null ;}

}

class _Content {
  final dynamic content ;
  int status ;
  _Content(this.content, [this.status = 0]);

  dynamic _contentForDOM ;

  dynamic get contentForDOM {
    _contentForDOM ??= _ensureElementForDOM(content);
    return _contentForDOM ;
  }

}


dynamic _ensureElementForDOM(dynamic element) {
  if ( _isElementForDOM(element) ) {
    return element ;
  }

  if ( element is String ) {
    if ( element.contains('<') && element.contains('>') ) {
      var div = createDivInline(element) ;
      if ( div.childNodes.isEmpty ) return div ;

      if ( div.childNodes.length == 1 ) {
        return div.childNodes.first ;
      }
      else {
        div ;
      }
    }
    else {
      var span = SpanElement();
      setElementInnerHTML(span, element);
      return span;
    }
  }

  return element ;
}

bool _isElementForDOM(dynamic element) {
  if ( element is Element ) {
    return true ;
  }
  else if (element is Node) {
    return true ;
  }
  else if (element is UIComponent) {
    return true ;
  }
  else if (element is UIAsyncContent) {
    return true ;
  }
  else if (element is List) {
    for (var elem in element) {
      if ( _isElementForDOM(elem) ) return true ;
    }
    return false ;
  }

  return false ;
}


typedef AsyncContentProvider = Future<dynamic> Function() ;

class UIAsyncContent {
  AsyncContentProvider _asyncContentProvider ;
  Future<dynamic> _asyncContentFuture ;

  dynamic _loadingContent ;
  dynamic _errorContent ;
  Duration _refreshInterval ;

  _Content _loadedContent ;

  Map<String,dynamic> _properties = {} ;

  static bool isNotValid(UIAsyncContent asyncContent, [ Map<String,dynamic> properties ]) {
    return !isValid(asyncContent, properties) ;
  }

  static bool isValid(UIAsyncContent asyncContent, [ Map<String,dynamic> properties ]) {
    if (asyncContent == null) return false ;

    if ( asyncContent.equalsProperties(properties) ) {
      return true ;
    }
    else {
      asyncContent.stop() ;
      return false ;
    }
  }

  bool equalsProperties( Map<String,dynamic> properties ) {
    properties ??= {} ;

    if ( _properties.length != properties.length ) return false ;

    for (var key in properties.keys) {
      var val1 = _properties[key] ;
      var val2 = properties[key] ;
      if ( val1 != val2 ) return false ;
    }

    return true ;
  }

  final EventStream<dynamic> onLoadContent = EventStream() ;

  UIAsyncContent.provider(this._asyncContentProvider, dynamic loadingContent, [dynamic errorContent, this._refreshInterval, this._properties]) {
    _loadingContent = _ensureElementForDOM(loadingContent) ;
    _errorContent = _ensureElementForDOM(errorContent) ;

    _initProperties();
    _callContentProvider(false) ;
  }

  UIAsyncContent.future(Future<dynamic> contentFuture, dynamic loadingContent, [dynamic errorContent, this._properties]) {
    _loadingContent = _ensureElementForDOM(loadingContent) ;
    _errorContent = _ensureElementForDOM(errorContent) ;

    _initProperties();
    _setAsyncContentFuture(contentFuture) ;
  }

  Map<String, dynamic> get properties => Map<String, dynamic>.from( _properties ) ;

  dynamic get loadingContent => _loadingContent;
  dynamic get errorContent => _errorContent;

  bool _stopped = false ;
  bool get stopped => _stopped;

  void stop() {
    _stopped = true ;
  }

  void _initProperties() {
    _properties ??= {} ;
  }

  Duration get refreshInterval => _refreshInterval;

  int _maxIgnoredRefreshCount = 10 ;

  int get maxIgnoredRefreshCount => _maxIgnoredRefreshCount;

  set maxIgnoredRefreshCount(int value) {
    if (value == null || value < 1) value = 1 ;
    _maxIgnoredRefreshCount = value;
  }

  int _ignoredRefreshCount = 0 ;

  void _callContentProvider(bool fromRefresh) {
    if (fromRefresh) {
      if ( !isLoaded ) {
        _ignoreRefresh();
        return;
      }

      var content = this.content;

      if ( !isComponentInDOM( content ) && canBeInDOM(content) ) {
        _ignoreRefresh(false);
        return;
      }
    }

    _ignoredRefreshCount = 0 ;

    var contentFuture = _asyncContentProvider() ;
    _setAsyncContentFuture(contentFuture) ;
  }

  void _ignoreRefresh([bool inDOM]) {
    _ignoredRefreshCount++ ;
    if (_ignoredRefreshCount < _maxIgnoredRefreshCount ) {
      if ( inDOM == null || inDOM ) {
        _scheduleRefresh();
      }
    }
  }

  void _scheduleRefresh() {
    if ( _refreshInterval != null && !_stopped ) {
      Future.delayed(_refreshInterval, refresh );
    }
  }

  void _setAsyncContentFuture(Future<dynamic> contentFuture) {
    _asyncContentFuture = contentFuture ;
    _asyncContentFuture.then(_onLoadedContent).catchError(_onLoadError) ;
  }

  void refreshAsync() {
    Future.microtask( refresh ) ;
  }

  void refresh() {
    _refreshImpl(true) ;
  }

  void _refreshImpl( bool fromRefresh ) {
    if (_asyncContentProvider == null) return ;
    _callContentProvider( fromRefresh ) ;
  }

  int _loadCount = 0 ;
  int get loadCount => _loadCount;

  DateTime _loadTime ;
  DateTime get loadTime => _loadTime;

  int get elapsedLoadTime => _loadTime != null ? DateTime.now().millisecondsSinceEpoch - _loadTime.millisecondsSinceEpoch : -1 ;

  bool get isExpired => _refreshInterval != null && elapsedLoadTime > _refreshInterval.inMilliseconds ;

  bool get hasAutoRefresh => _refreshInterval != null ;

  void _onLoadedContent(dynamic content) {
    _loadedContent = _Content(content, 200) ;
    _loadCount++ ;
    _loadTime = DateTime.now() ;
    _scheduleRefresh() ;

    onLoadContent.add( content ) ;
  }

  void _onLoadError(dynamic error, StackTrace stackTrace) {
    print(error);
    print(stackTrace);

    _loadedContent = _Content(error, 500) ;
    _loadCount++ ;
    _loadTime = DateTime.now() ;
    _scheduleRefresh() ;

    onLoadContent.add( null ) ;
  }

  bool get isLoaded => _loadedContent != null ;

  bool get isOK => _loadedContent != null && _loadedContent.status == 200 ;
  bool get isWithError => _loadedContent != null && _loadedContent.status == 500 ;

  dynamic get content {
    if ( _loadedContent == null ) {
      return loadingContent ;
    }
    else if ( _loadedContent.status == 200 ) {
      return _loadedContent.contentForDOM ;
    }
    else {
      return errorContent ?? loadingContent ;
    }
  }

  void reset( [bool refresh = true] ) {
    print('RESET ASYNC CONTENT> $this');

    _loadedContent = null ;
    _ignoredRefreshCount = 0 ;
    onLoadContent.add( null ) ;

    if ( refresh ?? true ) {
      Future.microtask( () => _refreshImpl(false) ) ;
    }
  }

  @override
  String toString() {
    return 'UIAsyncContent{isLoaded: $isLoaded, loadingContent: <<$loadingContent>>, loadedContent: <<$_loadedContent>>}';
  }

}

class Dimension {

  final int width ;
  final int height ;

  Dimension(this.width, this.height);


}

///////////////////////////////////////////////////

abstract class UIRoot extends UIComponent {

  static UIRoot _rootInstance ;

  static UIRoot getInstance() {
    return _rootInstance ;
  }

  /////////////////////////////////////////////////

  LocalesManager _localesManager ;
  Future<bool> _futureInitializeLocale ;

  UIRoot(Element container, {dynamic classes}) : super(container, classes: classes) {
    _rootInstance = this ;

    _localesManager = createLocalesManager(initializeLocale, _onDefineLocale) ;
    _futureInitializeLocale = _localesManager.initialize(getPreferredLocale) ;

    UINavigator.get().refreshNavigationAsync();

    UIConsole.checkAutoEnable() ;
  }

  LocalesManager getLocalesManager() {
    return _localesManager ;
  }

  // ignore: use_function_type_syntax_for_parameters
  SelectElement buildLanguageSelector( refreshOnChange() ) {
    return _localesManager.buildLanguageSelector(refreshOnChange) as SelectElement ;
  }

  Future<bool> initializeLocale(String locale) {
    return null ;
  }

  String getPreferredLocale() {
    return null ;
  }

  static String getCurrentLocale() {
    return Intl.defaultLocale ;
  }

  Future<bool> setPreferredLocale(String locale) {
    return _localesManager.setPreferredLocale(locale) ;
  }

  Future<bool> initializeAllLocales() {
    return _localesManager.initializeAllLocales() ;
  }

  List<String> getInitializedLocales() {
    return _localesManager.getInitializedLocales() ;
  }

  void _onDefineLocale(String locale) {
    UIConsole.log('UIRoot> Locale defined: $locale') ;
    refreshIfLocaleChanged() ;
  }

  @override
  bool renderOnConstruction() => false ;

  @override
  List render() {
    var menu = renderMenu() ;
    var content = renderContent() ;

    return [menu, content] ;
  }

  Future<bool> isReady() {
    return null ;
  }

  void initialize() {
    var ready = isReady();

    if (_futureInitializeLocale != null) {
      if (ready == null) {
        ready = _futureInitializeLocale ;
      }
      else {
        ready = ready.then( (ok) {
          return _futureInitializeLocale ;
        }) ;
      }
    }

    _initializeImpl( ready ) ;
  }

  void _initializeImpl([ Future<bool> ready ]) {
    if (ready == null) {
      _onReadyToInitialize() ;
    }
    else {
      ready.then((_) {
        _onReadyToInitialize() ;
      }
      , onError: (e) {
        _onReadyToInitialize() ;
      }
      ).timeout(Duration(seconds: 10), onTimeout: () {
        _onReadyToInitialize() ;
      });
    }
  }

  final EventStream<UIRoot> onInitialize = EventStream() ;
  final EventStream<UIRoot> onFinishRender = EventStream() ;

  void _onReadyToInitialize() {
    UIConsole.log('UIRoot> ready to initialize!') ;

    try {
      onInitialize.add(this) ;
    }
    catch (e) {
      UIConsole.error('Error calling UIRoot.onInitialize()', e);
    };

    callRender() ;
  }

  @override
  void callRender() {
    UIConsole.log('UIRoot> rendering...') ;
    super.callRender() ;
  }

  UIComponent renderMenu() {
    return null ;
  }

  UIComponent renderContent() ;


}

abstract class UINavigableComponent extends UIComponent {

  List<String> _routes ;
  bool _findRoutes ;

  String _currentRoute ;
  Map<String,String> _currentRouteParameters ;

  UINavigableComponent(Element parent, this._routes, {dynamic classes, dynamic classes2, bool inline = true, bool renderOnConstruction = false}) : super(parent, classes: classes, classes2: classes2, inline: inline, renderOnConstruction: renderOnConstruction) {
    content.classes.add('UINavigableContainer') ;
    _normalizeRoutes() ;

    if (routes.isEmpty) throw ArgumentError('Empty routes') ;

    var currentRoute = UINavigator.currentRoute;
    var currentRouteParameters = UINavigator.currentRouteParameters;

    if ( currentRoute != null && currentRoute.isNotEmpty ) {
      if ( _routes.contains(currentRoute) ) {
        _currentRoute = currentRoute ;
        _currentRouteParameters = currentRouteParameters ;
      }
    }

    _currentRoute ??= _routes[0];

    UINavigator.get().registerNavigable(this);

    renderOnConstruction ??= this.renderOnConstruction();

    if ( renderOnConstruction ) {
      callRender();
    }
  }

  void _normalizeRoutes() {
    // ignore: omit_local_variable_types
    List<String> routesOk = [] ;

    if (_routes == null || _routes.isEmpty) _routes = ['*'] ;

    var findRoutes = false ;

    for (var r in _routes) {
      if (r == null || r.isEmpty) continue ;

      if (r == '*') {
        findRoutes = true ;

        var foundRoutes = UINavigator.get().findElementNavigableRoutes(content) ;

        for (var r2 in foundRoutes) {
          if ( !routesOk.contains(r2) ) routesOk.add(r2) ;
        }
      }
      else if ( !routesOk.contains(r) ) {
        routesOk.add(r) ;
      }
    }

    _findRoutes = findRoutes ;

    UIConsole.log('_normalizeRoutes: $_routes -> $routesOk');

    _routes = routesOk ;
  }

  void _updateRoutes([List<String> foundRoutes]) {
    foundRoutes ??= UINavigator.get().findElementNavigableRoutes(content);

    UIConsole.log('foundRoutes: $foundRoutes');

    for (var r in foundRoutes) {
      if ( !_routes.contains(r) ) {
        UIConsole.log('_updateRoutes: $_routes + $r');
        _routes.add(r) ;
      }
    }
  }

  List<String> get routes => copyListString(_routes) ;
  String get currentRoute => _currentRoute ;
  Map<String,String> get currentRouteParameters => copyMapString(_currentRouteParameters) ;

  bool canNavigateTo(String route) {
    for (var r in routes) {
      if ( route == r || route.startsWith('$r/') ) {
        return true ;
      }
    }

    if (_findRoutes != null && _findRoutes) {
      return _findNewRoutes(route);
    }

    return false ;
  }

  bool _findNewRoutes(String route) {
    var canHandleNewRoute = _canHandleNewRoute(route);
    if (!canHandleNewRoute) return false ;
    _updateRoutes([route]);
    return true ;
  }

  bool _canHandleNewRoute(String route) {
    var rendered = renderRoute(route, {});

    if (rendered == null) {
      return false ;
    }
    else if (rendered is List) {
      return rendered.isNotEmpty ;
    }
    else {
      return true ;
    }
  }

  @override
  dynamic render() {
    var rendered = renderRoute( currentRoute , _currentRouteParameters ) ;

    if (_findRoutes != null && _findRoutes) {
      _updateRoutes();
    }

    return rendered ;
  }

  dynamic renderRoute(String route, Map<String,String> parameters) ;

  bool navigateTo(String route, [Map<String,String> parameters]) {
    if ( !canNavigateTo(route) ) return false ;

    _currentRoute = route ;
    _currentRouteParameters = parameters ?? {} ;

    _refreshInternal();
    return true ;
  }

}

class Navigation {
  final String route ;
  final Map<String,String> parameters ;

  Navigation(this.route, [this.parameters]) ;

  bool get isValid => route != null && route.isNotEmpty ;

  String parameter(String key, [String def]) => parameters != null ? parameters[key] ?? def : def ;
  int parameterAsInt(String key, [int def]) => parameters != null ? parseInt( parameters[key] , def ) : def ;
  num parameterAsNum(String key, [num def]) => parameters != null ? parseNum( parameters[key] , def ) : def ;
  bool parameterAsBool(String key, [bool def]) => parameters != null ? parseBool(parameters[key] , def ) : def ;

  List<String> parameterAsStringList(String key, [List<String> def]) => parameters != null ? parseStringFromInlineList( parameters[key] , RegExp(r'\s*,\s*') , def) : def ;
  List<int> parameterAsIntList(String key, [List<int> def]) => parameters != null ? parseIntsFromInlineList( parameters[key] , RegExp(r'\s*,\s*') , def) : def ;
  List<num> parameterAsNumList(String key, [List<num> def]) => parameters != null ? parseNumsFromInlineList( parameters[key] , RegExp(r'\s*,\s*') , def) : def ;
  List<bool> parameterAsBoolList(String key, [List<bool> def]) => parameters != null ? parseBoolsFromInlineList( parameters[key] , RegExp(r'\s*,\s*') , def) : def ;

  @override
  String toString() {
    return 'Navigation{route: $route, parameters: $parameters}';
  }
}

class UINavigator {

  static UINavigator _instance ;

  static UINavigator get() {
    _instance ??= UINavigator._internal();
    return _instance ;
  }

  UINavigator._internal() {
    window.onHashChange.listen( (e) => _onChangeRoute(e) );

    var href = window.location.href;
    var url = Uri.parse(href);

    var routeFragment = _parseRouteFragment(url);

    String route = routeFragment[0];
    var parameters = routeFragment[1];

    _currentRoute = route ;
    _currentRouteParameters = parameters ;

    UIConsole.log('Init UINavigator[$href]> route: $_currentRoute ; parameters:  $_currentRouteParameters ; secureContext: $isSecureContext') ;
  }

  static bool get isOnline => window.navigator.onLine ;
  static bool get isOffline => !isOnline ;

  static bool get isSecureContext {
    try {
      return window.isSecureContext ;
    }
    catch (e) {
      print(e);
      return false ;
    }
  }

  void _suspend_onChangeRoute() {
    _onChangeRouteSuspended = true ;
    print('> _suspend_onChangeRoute: suspended: $_onChangeRouteSuspended') ;
  }

  void _resume_onChangeRouteAsync() {
    print('> _resume_onChangeRouteAsync: suspended: $_onChangeRouteSuspended') ;
    if (!_onChangeRouteSuspended) return ;
    Future.delayed( Duration (seconds: 1), _resume_onChangeRoute );
  }

  void _resume_onChangeRoute() {
    _onChangeRouteSuspended = false ;
    print('> _resume_onChangeRoute: suspended: $_onChangeRouteSuspended') ;
  }

  bool _onChangeRouteSuspended = false ;

  void _onChangeRoute(HashChangeEvent event) {
    var uri = Uri.parse( event.newUrl );

    if (_onChangeRouteSuspended) {
      UIConsole.log('UINavigator._onChangeRoute: from: ${ event.oldUrl } > to: $uri [SUSPENDED]');
      return ;
    }

    UIConsole.log('UINavigator._onChangeRoute: $uri > ${ event.oldUrl }');
    _navigateToFromURL(uri);
  }

  void refreshNavigationAsync([bool force = false]) {
    Future.microtask( () => refreshNavigation(force) );
  }

  void refreshNavigation([bool force = false]) {
    _navigateTo(currentRoute, _currentRouteParameters, null, force);
  }

  String _currentRoute ;
  Map<String,String> _currentRouteParameters ;

  static Navigation get currentNavigation {
    var route = currentRoute;
    if (route == null || route.isEmpty) return null ;
    return Navigation( route, currentRouteParameters );
  }

  static String get currentRoute => get()._currentRoute ;
  static Map<String,String> get currentRouteParameters => copyMapString( get()._currentRouteParameters ) ;

  static
  bool get hasRoute => get()._hasRoute() ;

  bool _hasRoute() {
    return _currentRoute != null && _currentRoute.isNotEmpty ;
  }

  String _lastNavigateRoute ;
  Map<String,String> _lastNavigateRouteParameters ;

  List _parseRouteFragment(Uri url) {
    var fragment = url != null ? url.fragment : '';
    fragment ??= '';

    var parts = fragment.split('?');

    var route = parts[0];
    var routeQueryString = parts.length > 1 ? parts[1] : null ;

    var parameters = decodeQueryString(routeQueryString);

    return [route, parameters] ;
  }

  void _navigateToFromURL(Uri url, [bool force = false]) {

    var routeFragment = _parseRouteFragment(url);

    String route = routeFragment[0];
    var parameters = routeFragment[1];

    if ( route.toLowerCase() == 'uiconsole' ) {
      String enableStr = parameters['enable'];
      var enable = enableStr == null || enableStr.toLowerCase() == 'true' || enableStr == '1' ;

      if (enable) {
        UIConsole.displayButton() ;
      }
      else {
        UIConsole.disable();
      }
    }

    UIConsole.log('UINavigator._navigateToFromURL[$url] route: $route ; parameters: $parameters');

    _navigateTo(route, parameters, null, force) ;
  }

  static void navigate(Navigation navigation, [bool force = false]) {
    if (navigation == null || !navigation.isValid) return ;
    get()._callNavigateTo(navigation.route, navigation.parameters, null, force);
  }

  static void navigateAsync(Navigation navigation, [bool force = false]) {
    if (navigation == null || !navigation.isValid) return ;
    get()._callNavigateToAsync(navigation.route, navigation.parameters, null, force);
  }

  static void navigateTo(String route, [Map<String,String> parameters, ParametersProvider parametersProvider, bool force = false]) {
    get()._callNavigateTo(route, parameters, parametersProvider, force);
  }

  static void navigateToAsync(String route, [Map<String,String> parameters,  ParametersProvider parametersProvider, bool force = false]) {
    get()._callNavigateToAsync(route, parameters, parametersProvider, force);
  }

  void _callNavigateTo(String route, [Map<String,String> parameters, ParametersProvider parametersProvider, bool force = false]) {
    if ( _navigables.isEmpty || findNavigable(route) == null ) {
      Future.microtask( () => _navigateTo(route, parameters, parametersProvider, force) ) ;
    }
    else {
      _navigateTo(route, parameters, parametersProvider, force);
    }
  }

  void _callNavigateToAsync(String route, [Map<String,String> parameters, ParametersProvider parametersProvider, bool force = false]) {
    Future.microtask( () => _navigateTo(route, parameters, parametersProvider, force) ) ;
  }

  int _navigateCount = 0 ;
  final List<Navigation> _navigationHistory = [] ;

  static List<Navigation> get navigationHistory => List.from( get()._navigationHistory ) ;

  static String get initialRoute => get()._initialRoute ;

  String get _initialRoute {
    var nav = _initialNavigation ;
    return nav != null && nav.isValid ? nav.route : null ;

  }

  static Navigation get initialNavigation => get()._initialNavigation ;

  Navigation get _initialNavigation {
    if ( _navigationHistory.isNotEmpty ) {
      var navigation = _navigationHistory[0];

      if ( navigation.isValid ) {
        var navigable = UINavigator.get().findNavigable( navigation.route );
        if (navigable != null) {
          return navigation;
        }
      }
    }

    return null ;
  }

  final EventStream<String> _onNavigate = EventStream() ;

  static EventStream<String> get onNavigate => get()._onNavigate ;

  void _navigateTo(String route, [Map<String,String> parameters, ParametersProvider parametersProvider, bool force = false]) {
    if ( route == '<' ) {
      var navigation = _navigationHistory.last ;

      if (navigation != null) {
        route = navigation.route;
        parameters = navigation.parameters;
      }
      else {
        return ;
      }
    }

    route ??= '';
    parameters ??= {};

    if (parametersProvider != null && parameters.isEmpty) {
      parameters = parametersProvider() ;
    }

    if ( !force && _lastNavigateRoute == route && isEquivalentMap(parameters, _lastNavigateRouteParameters) ) return ;

    _navigateCount++ ;

    if (route.contains('?')) {
      var parts = route.split('?');
      route = parts[0];
      var params = decodeQueryString(parts[1]);
      var parametersOrig = parameters ;
      parameters = params ;
      parameters.addAll(parametersOrig);
    }

    UIConsole.log('UINavigator.navigateTo[force: $force ; count: $_navigateCount] from: $_lastNavigateRoute $_lastNavigateRouteParameters > to: $route $parameters');

    _currentRoute = route ;
    _currentRouteParameters = copyMapString(parameters) ;

    if (_lastNavigateRoute != null) {
      var navigation = Navigation(_lastNavigateRoute, _lastNavigateRouteParameters);
      _navigationHistory.add(navigation);

      if ( _navigationHistory.length > 12 ) {
        while (_navigationHistory.length > 10) {
          _navigationHistory.removeAt(0);
        }
      }
    }

    _lastNavigateRoute = route ;
    _lastNavigateRouteParameters = copyMapString(parameters) ;

    var routeQueryString = _encodeRouteParameters(parameters) ;

    var fragment = '#$route' ;

    if (routeQueryString.isNotEmpty) fragment += '?$routeQueryString' ;

    var locationUrl = window.location.href ;
    var locationUrl2 = locationUrl.contains('#') ? locationUrl.replaceFirst(RegExp(r'#.*'), fragment) : '$locationUrl$fragment' ;

    _suspend_onChangeRoute();
    try {
      window.location.href = locationUrl2;
    }
    finally {
      _resume_onChangeRouteAsync();
    }

    clearDetachedNavigables();

    for (var container in _navigables) {
      if ( container.canNavigateTo(route) ) {
        container.navigateTo(route, parameters) ;
      }
    }
    
    UIConsole.log('Navigated to $route $parameters');

    _onNavigate.add( route ) ;
  }

  String _encodeRouteParameters(Map<String, String> parameters) {
    var urlEncoded = encodeQueryString(parameters) ;
    var routeEncoded = urlEncoded.replaceAll('%2C', ',') ;
    return routeEncoded ;
  }

  final List<UINavigableComponent> _navigables = [] ;

  UINavigableComponent findNavigable(String route) {
    for (var nav in _navigables) {
      if ( nav.canNavigateTo(route) ) return nav ;
    }
    return null ;
  }

  void registerNavigable(UINavigableComponent navigable) {
    if ( !_navigables.contains(navigable) ) {
      _navigables.add(navigable);
    }

    clearDetachedNavigables() ;
  }

  List<Element> selectNavigables([Element elem]) {
    return elem != null ? elem.querySelectorAll('.UINavigableContainer') : document.querySelectorAll('.UINavigableContainer')  ;
  }

  List<String> findElementNavigableRoutes(Element elem) {
    // ignore: omit_local_variable_types
    List<String> routes = [] ;

    _findElementNavigableRoutes([elem], routes) ;

    return routes ;
  }

  void _findElementNavigableRoutes(List<Element> elems, List<String> routes) {
    for (var elem in elems) {
      var navigateRoute = elem.getAttribute('navigate');
      if ( navigateRoute != null && navigateRoute.isNotEmpty && !routes.contains(navigateRoute) ) {
        routes.add(navigateRoute) ;
      }

      _findElementNavigableRoutes(elem.children, routes) ;
    }
  }

  void clearDetachedNavigables() {
    // ignore: omit_local_variable_types
    List<Element> list = selectNavigables() ;

    // ignore: omit_local_variable_types
    List<UINavigableComponent> navigables = List.from(_navigables) ;

    for (var container in navigables) {
      if ( !list.contains(container.content) ) {
        _navigables.remove(container);
      }
    }
  }

  static StreamSubscription navigateOnClick(Element elem, String route, [Map<String,String> parameters, ParametersProvider parametersProvider, bool force = false]) {
    var paramsStr = parameters != null ? parameters.toString() : '' ;

    var attrRoute = elem.getAttribute('__navigate__route') ;
    var attrParams = elem.getAttribute('__navigate__parameters') ;

    if ( route != attrRoute || paramsStr != attrParams ) {
      elem.setAttribute('__navigate__route', route) ;
      elem.setAttribute('__navigate__parameters', paramsStr) ;

      StreamSubscription subscription = elem.onClick.listen( (e) => navigateTo(route, parameters, parametersProvider, force) ) ;

      if ( elem.style.cursor == null || elem.style.cursor.isEmpty ) {
        elem.style.cursor = 'pointer' ;
      }

      return subscription;
    }

    return null ;
  }

}

