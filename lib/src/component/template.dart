import 'dart:html';

import 'package:bones_ui/bones_ui_kit.dart';

class UITemplateElementGenerator extends ElementGeneratorBase {
  UITemplateElementGenerator();

  @override
  final String tag = 'ui-template';

  @override
  bool get hasChildrenElements => false;

  @override
  bool get usesContentHolder => false;

  @override
  Element generate(
      DOMGenerator<Node> domGenerator,
      DOMTreeMap<Node> treeMap,
      String tag,
      DOMElement domParent,
      Node parent,
      Map<String, DOMAttribute> attributes,
      Node contentHolder,
      List<DOMNode> contentNodes) {
    var element = DivElement();

    setElementAttributes(element, attributes);

    domGenerator.addChildToElement(parent, element);

    var html = contentNodes.map((e) => e.buildHTML(withIndent: true)).join('');

    DOMElement domElement;

    if (html.contains('{{')) {
      try {
        var template = DOMTemplate.parse(html);
        var variables = getTemplateVariables(domGenerator, attributes);

        var asyncValues = deepCatchesMapValues(variables, (c, k, v) {
          return v is AsyncValue;
        });

        if (asyncValues.isNotEmpty) {
          var futures =
              asyncValues.whereType<AsyncValue>().map((e) => e.future).toList();

          var loadingConfig = UILoadingConfig.from(attributes);

          DivElement uiLoading;
          if (loadingConfig != null) {
            uiLoading = loadingConfig.asDivElement();
            element.append(uiLoading);
          }

          Future.wait(futures).then((_) {
            _normalizeVariables(variables);

            html = template.build(variables,
                elementProvider: (q) => queryElementProvider(treeMap, q));

            uiLoading?.remove();
            domElement = $htmlRoot(element.outerHtml);

            _generateElementContentFromHTML(
                domGenerator, html, domElement, element);
          });
        } else {
          html = template.build(variables,
              elementProvider: (q) => queryElementProvider(treeMap, q));

          domElement = $htmlRoot(element.outerHtml);
          _generateElementContentFromHTML(
              domGenerator, html, domElement, element);
        }
      } catch (e, s) {
        print(e);
        print(s);
        domElement = $span(content: 'error: $e');
        _generateElementContentFromHTML(
            domGenerator, html, domElement, element);
      }
    } else {
      domElement = $htmlRoot(html);
      _generateElementContentFromHTML(domGenerator, html, domElement, element);
    }

    return element;
  }

  static final RegExp REGEXP_TAG_REF =
      RegExp(r'\{\{\s*([\w-]+|\*)\#([\w-]+)\s*\}\}');
  static final RegExp REGEXP_TAG_OPEN =
      RegExp(r'''^\s*<[\w-]+\s(?:".*?"|'.*?'|\s+|[^>\s]+)*>''');
  static final RegExp REGEXP_TAG_CLOSE = RegExp(r'''<\/[\w-]+\s*>\s*$''');

  String queryElementProvider(DOMTreeMap<Node> treeMap, String query) {
    if (isEmptyString(query)) return null;

    var rootDOMNode = treeMap.rootDOMNode as DOMElement;

    var node = rootDOMNode.select(query);

    var html = node.buildHTML();

    html = html.replaceFirst(REGEXP_TAG_OPEN, '');
    html = html.replaceFirst(REGEXP_TAG_CLOSE, '');

    return html;
  }

  void _generateElementContentFromHTML(DOMGenerator domGenerator, String html,
      DOMElement domElement, DivElement element) {
    domGenerator.generateFromHTML(html,
        domParent: domElement, parent: element, finalizeTree: false);
  }

  Map<String, dynamic> getTemplateVariables(
      DOMGenerator domGenerator, Map<String, DOMAttribute> attributes) {
    if (domGenerator.domContext == null) return {};

    var variables = domGenerator.domContext.variables;

    variables['locale'] = UIRoot.getCurrentLocale();

    var routeParameters = UINavigator.currentNavigation?.parameters;

    if (isNotEmptyObject(routeParameters)) {
      variables['parameters'] = routeParameters;
    }

    resolveAttributeVariables(attributes, variables);

    variables['attributes'] =
        attributes.map((key, value) => MapEntry('$key', '$value'));

    _normalizeVariables(variables);

    var attributesResolved = variables['attributes'] as Map<String, String>;

    var dataSourceResponse = getDataSourceResponse(attributesResolved);

    if (dataSourceResponse != null) {
      variables['data'] = AsyncValue.from(dataSourceResponse);
    }

    _normalizeVariables(variables);

    return variables;
  }

  void resolveAttributeVariables(
      Map<String, DOMAttribute> attributes, Map<String, dynamic> variables) {
    var map = parseAttributeVariables(attributes) ?? {};

    for (var entry in map.entries) {
      var k = '${entry.key}';
      var v = entry.value;
      if (isNotEmptyString(k)) {
        variables[k] = v;
      }
    }
  }

  Map parseAttributeVariables(Map<String, DOMAttribute> attributes) {
    var value = attributes['variables']?.toString();

    if (isNotEmptyString(value, trim: true)) {
      if (isJSONMap(value)) {
        return parseJSON(value) as Map;
      } else {
        return decodeQueryString(value);
      }
    }
    return null;
  }

  void _normalizeVariables(Map<String, dynamic> variables) {
    deepReplaceValues(variables, (c, k, v) {
      return v is Function;
    }, (c, k, v) {
      return v();
    });

    deepReplaceValues(variables, (c, k, v) {
      return v is Future;
    }, (c, k, v) {
      return AsyncValue.from(v);
    });

    deepReplaceValues(variables, (c, k, v) {
      return v is AsyncValue && v.isLoaded;
    }, (c, k, v) {
      var v2 = (v as AsyncValue).get();
      return v2;
    });

    deepReplaceValues(variables, (c, k, v) {
      return v is String && v.contains('{{') && v.contains('}}');
    }, (c, k, v) {
      var template = DOMTemplate.parse(v);
      var v2 = template.build(variables);
      return v2;
    });

    print('TEMPLATE VARS:');
    print(variables);
  }

  Future<dynamic> getDataSourceResponse(Map<String, String> attributes) {
    var daraSourceCallAttr = attributes['data-source'];
    if (daraSourceCallAttr == null) return null;
    var dataSourceCall = DataSourceCall.from(daraSourceCallAttr);

    if (dataSourceCall != null) {
      try {
        var response = dataSourceCall.call();
        return response;
      } catch (e, s) {
        print(e);
        print(s);
      }
    }

    return null;
  }

  @override
  bool isGeneratedElement(Node element) {
    return element is DivElement && element.classes.contains(tag);
  }

  @override
  DOMElement revert(DOMGenerator domGenerator, DOMTreeMap treeMap,
      DOMElement domParent, Node parent, Node node) {
    if (node is DivElement) {
      var domElement =
          $tag(tag, classes: node.classes.join(' '), style: node.style.cssText);

      if (treeMap != null) {
        var mappedDOMNode = treeMap.getMappedDOMNode(node);
        if (mappedDOMNode != null) {
          domElement.add(mappedDOMNode.content);
        }
      } else {
        domElement.add(node.text);
      }

      return domElement;
    } else {
      return null;
    }
  }
}