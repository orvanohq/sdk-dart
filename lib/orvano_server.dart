/// The Orvano server SDK for Dart: call your Orvano project from a backend,
/// a CLI, or a Dart function with a secret key.
library;

// Deviation DRT-8: the generated barrel carries the show lists, so a new
// service reaches the public API without a hand edit (spec 0014 GNR-9).
export 'src/generated/exports.dart';
export 'src/orvano_server.dart' show OrvanoServer;
export 'src/version.dart' show packageVersion;
