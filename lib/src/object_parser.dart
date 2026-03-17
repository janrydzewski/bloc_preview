/// Parses Dart `toString()` output into structured JSON-compatible values.
///
/// Most Dart classes produce output in one of the following shapes when
/// `toString()` is called:
///
/// * `ClassName(field: value, other: value)`
/// * `EnumType.member`
/// * `ClassName.namedCtor(field: value)`
/// * `[item1, item2]`
/// * `{key: value}`
///
/// This function attempts to turn such strings back into [Map]s, [List]s, and
/// primitives so they can be rendered as a structured tree in the web
/// dashboard.
///
/// When parsing fails the original [input] string is returned unchanged.
///
/// ```dart
/// final result = parseObjectNotation('Counter(count: 42)');
/// // => {'_type': 'Counter', 'count': 42}
/// ```
dynamic parseObjectNotation(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;

  final scanner = _NotationScanner(trimmed);
  try {
    return scanner.scanValue();
  } catch (_) {
    return trimmed;
  }
}

// ---------------------------------------------------------------------------
// Private recursive-descent scanner
// ---------------------------------------------------------------------------

class _NotationScanner {
  _NotationScanner(this._source);

  final String _source;
  int _cursor = 0;

  // -- Helpers --------------------------------------------------------------

  bool get _atEnd => _cursor >= _source.length;
  String get _peek => _atEnd ? '' : _source[_cursor];

  void _skipWhitespace() {
    while (!_atEnd && _isSpace(_peek)) {
      _cursor++;
    }
  }

  bool _match(String expected) {
    if (_cursor + expected.length > _source.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (_source[_cursor + i] != expected[i]) return false;
    }
    // Ensure the keyword is not part of a longer identifier.
    final end = _cursor + expected.length;
    if (end < _source.length && _isIdentChar(_source[end])) return false;
    return true;
  }

  // -- Top-level entry point ------------------------------------------------

  dynamic scanValue() {
    _skipWhitespace();
    if (_atEnd) return '';

    // Keywords
    if (_match('null')) {
      _cursor += 4;
      return null;
    }
    if (_match('true')) {
      _cursor += 4;
      return true;
    }
    if (_match('false')) {
      _cursor += 5;
      return false;
    }

    // Containers
    if (_peek == '[') return _scanList();
    if (_peek == '{') return _scanMap();

    // Numbers (including negative)
    if (_peek == '-' &&
        _cursor + 1 < _source.length &&
        _isDigit(_source[_cursor + 1])) {
      return _scanNumber();
    }
    if (_isDigit(_peek)) return _scanNumber();

    // Quoted strings
    if (_peek == "'" || _peek == '"') return _scanQuotedString();

    // Identifiers (classes, enums, plain words)
    if (_isIdentStart(_peek)) return _scanIdentifierOrObject();

    // Fallback: consume until a structural character.
    return _scanRawToken();
  }

  // -- Lists ----------------------------------------------------------------

  List<dynamic> _scanList() {
    _cursor++; // skip [
    final items = <dynamic>[];
    _skipWhitespace();
    if (_peek == ']') {
      _cursor++;
      return items;
    }

    while (!_atEnd) {
      _skipWhitespace();
      if (_peek == ']') {
        _cursor++;
        break;
      }
      items.add(scanValue());
      _skipWhitespace();
      if (_peek == ',') {
        _cursor++;
        continue;
      }
      if (_peek == ']') {
        _cursor++;
        break;
      }
      break;
    }
    return items;
  }

  // -- Maps -----------------------------------------------------------------

  Map<String, dynamic> _scanMap() {
    _cursor++; // skip {
    final map = <String, dynamic>{};
    _skipWhitespace();
    if (_peek == '}') {
      _cursor++;
      return map;
    }

    while (!_atEnd) {
      _skipWhitespace();
      if (_peek == '}') {
        _cursor++;
        break;
      }
      final key = scanValue();
      _skipWhitespace();
      if (_peek == ':') {
        _cursor++;
        _skipWhitespace();
        map[key.toString()] = scanValue();
      }
      _skipWhitespace();
      if (_peek == ',') {
        _cursor++;
        continue;
      }
      if (_peek == '}') {
        _cursor++;
        break;
      }
      break;
    }
    return map;
  }

  // -- Identifiers / Dart objects -------------------------------------------

  dynamic _scanIdentifierOrObject() {
    final saved = _cursor;
    final typeName = _readDottedIdentifier();
    _skipWhitespace();

    if (!_atEnd &&
        _peek != '(' &&
        _peek != ',' &&
        _peek != ')' &&
        _peek != ']' &&
        _peek != '}') {
      _cursor = saved;
      return _scanRawToken();
    }

    // No parentheses — this is an enum value or a plain word.
    if (_atEnd || _peek != '(') return typeName;

    // Parenthesised body — a Dart object.
    _cursor++; // skip (
    _skipWhitespace();
    if (_peek == ')') {
      _cursor++;
      return <String, dynamic>{'_type': typeName};
    }

    if (_looksLikeNamedFields()) {
      return _scanNamedFields(typeName);
    }
    return _scanPositionalArgs(typeName);
  }

  /// Determines whether the scanner is looking at `identifier:` (a named
  /// field) as opposed to a URL scheme like `https://`.
  bool _looksLikeNamedFields() {
    final saved = _cursor;
    _skipWhitespace();

    if (!_isIdentStart(_peek)) {
      _cursor = saved;
      return false;
    }

    // Skip potential key identifier.
    while (!_atEnd && _isIdentChar(_peek)) {
      _cursor++;
    }
    _skipWhitespace();

    if (_atEnd || _peek != ':') {
      _cursor = saved;
      return false;
    }

    // Distinguish `key: value` from `https://...`.
    if (_cursor + 2 < _source.length &&
        _source[_cursor + 1] == '/' &&
        _source[_cursor + 2] == '/') {
      _cursor = saved;
      return false;
    }

    _cursor = saved;
    return true;
  }

  // -- Named fields  --------------------------------------------------------

  Map<String, dynamic> _scanNamedFields(String typeName) {
    final fields = <String, dynamic>{'_type': typeName};

    while (!_atEnd) {
      _skipWhitespace();
      if (_peek == ')') {
        _cursor++;
        break;
      }

      final key = _readIdentifier();
      _skipWhitespace();
      if (_peek == ':') {
        _cursor++;
        _skipWhitespace();
        fields[key] = _scanFieldValue();
      }

      _skipWhitespace();
      if (_peek == ',') {
        _cursor++;
        continue;
      }
      if (_peek == ')') {
        _cursor++;
        break;
      }
      break;
    }
    return fields;
  }

  /// Scans a single field value inside named-field parentheses.
  ///
  /// This is similar to [scanValue] but handles raw (unquoted) text that
  /// should be consumed up to the next field separator.
  dynamic _scanFieldValue() {
    _skipWhitespace();
    if (_atEnd) return '';

    // Keywords
    if (_match('null')) {
      _cursor += 4;
      return null;
    }
    if (_match('true')) {
      _cursor += 4;
      return true;
    }
    if (_match('false')) {
      _cursor += 5;
      return false;
    }

    // Containers
    if (_peek == '[') return _scanList();
    if (_peek == '{') return _scanMap();

    // Numbers
    if (_peek == '-' &&
        _cursor + 1 < _source.length &&
        _isDigit(_source[_cursor + 1])) {
      return _scanNumber();
    }
    if (_isDigit(_peek)) return _scanNumber();

    // Quoted strings
    if (_peek == "'" || _peek == '"') return _scanQuotedString();

    // Identifier — might be a nested object or a simple value.
    if (_isIdentStart(_peek)) {
      final saved = _cursor;
      final name = _readDottedIdentifier();
      _skipWhitespace();

      if (!_atEnd && _peek == '(') {
        _cursor++; // skip (
        _skipWhitespace();
        if (_peek == ')') {
          _cursor++;
          return <String, dynamic>{'_type': name};
        }
        if (_looksLikeNamedFields()) {
          return _scanNamedFields(name);
        }
        return _scanPositionalArgs(name);
      }

      // Simple value — check if it's completely consumed.
      if (_atEnd || _peek == ',' || _peek == ')') return name;

      // Raw text fallback.
      _cursor = saved;
      return _scanRawFieldValue();
    }

    return _scanRawFieldValue();
  }

  /// Consumes free-form text until the next field boundary (`, key:` or `)`).
  String _scanRawFieldValue() {
    final start = _cursor;
    var depth = 0;

    while (!_atEnd) {
      final ch = _peek;
      if (ch == '(' || ch == '[' || ch == '{') depth++;
      if (ch == ')' || ch == ']' || ch == '}') {
        if (depth == 0) break;
        depth--;
      }
      if (ch == ',' && depth == 0) {
        // Peek ahead to check for `, identifier:` pattern.
        final saved = _cursor;
        _cursor++; // skip ,
        _skipWhitespace();
        if (_isIdentStart(_peek)) {
          while (!_atEnd && _isIdentChar(_peek)) {
            _cursor++;
          }
          _skipWhitespace();
          if (!_atEnd &&
              _peek == ':' &&
              !(_cursor + 2 < _source.length &&
                  _source[_cursor + 1] == '/' &&
                  _source[_cursor + 2] == '/')) {
            // This comma belongs to the field separator.
            _cursor = saved;
            break;
          }
        }
        _cursor = saved;
        _cursor++;
        continue;
      }
      _cursor++;
    }
    return _source.substring(start, _cursor).trim();
  }

  // -- Positional arguments -------------------------------------------------

  Map<String, dynamic> _scanPositionalArgs(String typeName) {
    final result = <String, dynamic>{'_type': typeName};
    final args = <dynamic>[];

    while (!_atEnd) {
      _skipWhitespace();
      if (_peek == ')') {
        _cursor++;
        break;
      }
      args.add(scanValue());
      _skipWhitespace();
      if (_peek == ',') {
        _cursor++;
        continue;
      }
      if (_peek == ')') {
        _cursor++;
        break;
      }
      break;
    }

    if (args.length == 1) {
      result['value'] = args[0];
    } else if (args.isNotEmpty) {
      result['args'] = args;
    }
    return result;
  }

  // -- Numbers --------------------------------------------------------------

  num _scanNumber() {
    final start = _cursor;
    if (_peek == '-') _cursor++;
    while (!_atEnd && _isDigit(_peek)) {
      _cursor++;
    }
    if (!_atEnd &&
        _peek == '.' &&
        _cursor + 1 < _source.length &&
        _isDigit(_source[_cursor + 1])) {
      _cursor++; // skip .
      while (!_atEnd && _isDigit(_peek)) {
        _cursor++;
      }
      return double.parse(_source.substring(start, _cursor));
    }
    return int.parse(_source.substring(start, _cursor));
  }

  // -- Quoted strings -------------------------------------------------------

  String _scanQuotedString() {
    final quote = _peek;
    _cursor++;
    final buffer = StringBuffer();
    while (!_atEnd && _peek != quote) {
      if (_peek == r'\' && _cursor + 1 < _source.length) {
        _cursor++;
        buffer.write(_peek);
      } else {
        buffer.write(_peek);
      }
      _cursor++;
    }
    if (!_atEnd) _cursor++; // skip closing quote
    return buffer.toString();
  }

  // -- Identifiers ----------------------------------------------------------

  String _readIdentifier() {
    final start = _cursor;
    while (!_atEnd && _isIdentChar(_peek)) {
      _cursor++;
    }
    return _source.substring(start, _cursor);
  }

  String _readDottedIdentifier() {
    final buffer = StringBuffer()..write(_readIdentifier());
    while (!_atEnd && _peek == '.') {
      _cursor++;
      buffer
        ..write('.')
        ..write(_readIdentifier());
    }
    return buffer.toString();
  }

  // -- Raw fallback ---------------------------------------------------------

  String _scanRawToken() {
    final start = _cursor;
    var depth = 0;
    while (!_atEnd) {
      final ch = _peek;
      if (ch == '(' || ch == '[' || ch == '{') depth++;
      if (ch == ')' || ch == ']' || ch == '}') {
        if (depth == 0) break;
        depth--;
      }
      if (ch == ',' && depth == 0) break;
      _cursor++;
    }
    return _source.substring(start, _cursor).trim();
  }

  // -- Character tests ------------------------------------------------------

  static bool _isSpace(String ch) =>
      ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';

  static bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 48 && c <= 57;
  }

  static bool _isIdentStart(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95;
  }

  static bool _isIdentChar(String ch) => _isIdentStart(ch) || _isDigit(ch);
}
