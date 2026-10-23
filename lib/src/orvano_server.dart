import 'dart:io';

import 'package:http/http.dart' as http;

import 'core/options.dart';
import 'core/transport.dart';
import 'generated/services.dart';
import 'version.dart';

/// A client for one Orvano project, authenticated with a secret key
/// (spec 0004 CLN-1, PLT-3). Open one per project and endpoint, and
/// [close] it when you are done.
///
/// Never use it in a browser or phone app: a secret key there is a leaked
/// key. It throws `UnsupportedError` on Android and iOS.
final class OrvanoServer extends OrvanoServices {
  /// Opens a client for [projectId] on [endpoint] with the secret [apiKey].
  ///
  /// Throws `ArgumentError` when the endpoint is not absolute, carries a
  /// user, a query, or a fragment, is `http` for a host other than localhost
  /// (unless `allowInsecureEndpoint` is set), or when [projectId] or [apiKey]
  /// is empty. Pass [httpClient] to use your own `http.Client`; the SDK
  /// never closes a client it did not create.
  factory OrvanoServer({
    required Uri endpoint,
    required String projectId,
    required String apiKey,
    http.Client? httpClient,
    OrvanoClientOptions options = const OrvanoClientOptions(),
  }) {
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnsupportedError(
        'OrvanoServer holds a secret key and never runs in a phone app. '
        'Use the orvano package there.',
      );
    }
    return OrvanoServer._(
      OrvanoTransport(
        endpoint: endpoint,
        projectId: projectId,
        clientName: 'orvano_server/$packageVersion',
        auth: KeyAuth(apiKey),
        options: options,
        httpClient: httpClient,
      ),
    );
  }

  OrvanoServer._(super.transport);

  /// Closes the client (spec 0004 CLN-5): every call in flight fails with
  /// `OrvanoCancelledException`, and the `http.Client` is closed if the SDK
  /// created it. Any call after this fails with `StateError`. Safe to call
  /// more than once.
  Future<void> close() async => transport.close();

  @override
  String toString() => 'OrvanoServer(projectId: ${transport.projectId})';
}
