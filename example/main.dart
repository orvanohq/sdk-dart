// Spec 0004 PUB-2: the quick start. Run it against your own server:
//   ORVANO_ENDPOINT=http://localhost:8080 ORVANO_PROJECT_ID=... \
//   ORVANO_API_KEY=orv_sk_... dart run example/main.dart
import 'dart:io';

import 'package:orvano_server/orvano_server.dart';

String requireEnv(String name) =>
    Platform.environment[name] ?? (throw StateError('$name is not set'));

Future<void> main() async {
  final orvano = OrvanoServer(
    endpoint: Uri.parse(requireEnv('ORVANO_ENDPOINT')),
    projectId: requireEnv('ORVANO_PROJECT_ID'),
    apiKey: requireEnv('ORVANO_API_KEY'),
  );
  try {
    final health = await orvano.health.get();
    print('Orvano is ${health.status}; it serves ${health.apiVersions}.');
  } on OrvanoException catch (error) {
    print('Orvano did not answer: $error');
  } finally {
    await orvano.close();
  }
}
