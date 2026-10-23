// Spec 0004 Enforcement: DRT-2 (exactly these runtime dependencies), DRT-3 (no
// dependency_overrides, caret ranges), PKG-5 (no native plugin folders), and
// the Replaces list (banned packages anywhere).
import 'dart:io';

/// Each pubspec, and the runtime dependencies DRT-2 allows it.
const Map<String, Set<String>> _allowed = {
  'pubspec.yaml': {'clock', 'collection', 'http', 'logging', 'meta'},
};

const Set<String> _bannedPackages = {
  'dio',
  'chopper',
  'retrofit',
  'get_it',
  'rxdart',
  'provider',
  'riverpod',
  'flutter_riverpod',
  'bloc',
  'flutter_bloc',
  'get',
  'signals',
  'json_serializable',
  'json_annotation',
  'freezed',
  'freezed_annotation',
  'built_value',
  'build_runner',
  'mockito',
  'mocktail',
  'hive',
  'melos',
};

void main() {
  final problems = <String>[];
  for (final MapEntry(key: path, value: allowed) in _allowed.entries) {
    final sections = _sections(File(path).readAsLinesSync());
    final runtime = sections['dependencies'] ?? const {};
    for (final MapEntry(key: name, value: constraint) in runtime.entries) {
      if (!allowed.contains(name)) {
        problems.add('$path: $name is not on spec 0004 DRT-2\'s list');
      }
      if (!constraint.startsWith('^') && constraint != 'sdk: flutter') {
        problems.add('$path: $name needs a caret range (DRT-3)');
      }
    }
    for (final name in [
      ...runtime.keys,
      ...?sections['dev_dependencies']?.keys,
    ]) {
      if (_bannedPackages.contains(name)) {
        problems.add('$path: $name is on spec 0004\'s Replaces list');
      }
    }
    if (sections.containsKey('dependency_overrides')) {
      problems.add('$path: dependency_overrides (DRT-3)');
    }
    final root = File(path).parent.path;
    for (final folder in ['android', 'ios', 'macos', 'windows', 'linux']) {
      if (Directory('$root/$folder').existsSync()) {
        problems.add('$root/$folder: native plugin code (PKG-5)');
      }
    }
  }
  if (problems.isNotEmpty) {
    stderr.writeln('check_deps:\n  ${problems.join('\n  ')}');
    exit(1);
  }
  print('check_deps: dependencies follow spec 0004 DRT-2 and DRT-3.');
}

/// The top level sections of a pubspec that list packages, as
/// `{section: {package: constraint}}`. Only the two space indented entries
/// count, which is how every Orvano pubspec is written.
Map<String, Map<String, String>> _sections(List<String> lines) {
  final result = <String, Map<String, String>>{};
  Map<String, String>? current;
  final section = RegExp(r'^([a-z_]+):\s*$');
  final entry = RegExp(r'^  ([a-z0-9_]+):\s*(.*)$');
  for (final line in lines) {
    if (section.firstMatch(line) case final match?) {
      final name = match[1] ?? '';
      current = name.contains('dependencies') || name == 'dependency_overrides'
          ? (result[name] = {})
          : null;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      current = null;
    }
    if (current != null) {
      if (entry.firstMatch(line) case final match?) {
        current[match[1] ?? ''] = (match[2] ?? '').trim();
      } else if (line.startsWith('    sdk:')) {
        final last = current.keys.lastOrNull;
        if (last != null) current[last] = 'sdk: ${line.split(':').last.trim()}';
      }
    }
  }
  return result;
}
