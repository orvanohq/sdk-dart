# Orvano Dart Server SDK

`orvano_server` calls your [Orvano](https://github.com/orvanohq/orvano) project from Dart on a server: a backend, a CLI, a job runner, or an Orvano Dart function. Orvano is an open source, self hostable backend as a service. For a Flutter or browser app, use the `orvano` package from [orvanohq/sdk-flutter](https://github.com/orvanohq/sdk-flutter) instead.

## Install

```bash
dart pub add orvano_server
```

It runs on the Dart VM and in `dart compile exe` builds on Linux, macOS, and Windows. It holds a secret key, so it never runs in a browser or a phone app: web builds don't compile, and it throws `UnsupportedError` on Android and iOS.

## Quick start

```dart
import 'package:orvano_server/orvano_server.dart';

Future<void> main() async {
  final orvano = OrvanoServer(
    endpoint: Uri.parse('https://orvano.example.com'),
    projectId: '0192f0c1-0000-7000-8000-000000000001',
    apiKey: 'orv_sk_...', // read it from your environment, never commit it
  );
  try {
    final health = await orvano.health.get();
    print(health.status);
  } on OrvanoException catch (error) {
    print('The call failed: $error');
  } finally {
    await orvano.close();
  }
}
```

Open one client per project and endpoint, and `close()` it when you're done. Every failure is an `OrvanoException`, a sealed family you can `switch` over: `OrvanoApiException` (the server answered with an error; compare `code` with `OrvanoErrorCodes`), `OrvanoNetworkException`, `OrvanoTimeoutException`, `OrvanoCancelledException`, and `OrvanoProtocolException`.

## Timeouts and retries

Each attempt has 30 seconds (`OrvanoClientOptions(timeout: ...)`, or per call with `OrvanoRequestOptions`). GET requests are retried up to 2 times after a 408, 429, 502, 503, or 504, a timeout, or a dropped connection, with backoff or the server's `Retry-After` (up to 30 seconds; a longer one throws). Other methods are never retried. So the worst case for one GET is 3 attempts of 30 seconds plus the waits. `RetryOptions(maxRetries: 0)` turns retries off.

Pass an `OrvanoCancelToken` in `OrvanoRequestOptions(cancelToken: ...)` to cancel calls.

## Security notes

- The endpoint must be `https`, except for `localhost`, `127.0.0.1`, `::1`, and `*.localhost`. Set `OrvanoClientOptions(allowInsecureEndpoint: true)` for a server on your own network.
- The SDK never follows a redirect, so your key never reaches another host.
- No exception, log line, or `toString` shows your key. Request logs (`package:logging`, logger `orvano.http`, level `FINE`) show the method, path, status, and duration only.
- Pass your own `http.Client` (`httpClient:`) for a proxy or certificate pinning. The SDK never closes a client it did not create.

## Testing your code

Use the real client with `MockClient` from `package:http/testing.dart`:

```dart
final orvano = OrvanoServer(
  endpoint: Uri.parse('https://orvano.test'),
  projectId: 'test-project',
  apiKey: 'orv_sk_test',
  httpClient: MockClient(
    (request) async => http.Response('{"status":"ok","apiVersions":["2026-10-22"]}', 200),
  ),
);
```

## Working on this repo

Most of the code is generated from the Orvano contract (spec 0014): `lib/src/generated/`, `lib/src/core/` (the runtime shared with the Flutter SDK), and `test/conformance/dispatch.g.dart`. Never edit them by hand; change the generator or its templates in `orvanohq/orvano`, then regenerate.

You'll need Dart 3.10 or later, and for regenerating, git, Node 24, and pnpm (`corepack enable`).

```bash
dart run tool/regenerate.dart            # regenerate from the commit in orvano-contract.json
dart run tool/regenerate.dart --pin <sha> # move the pin to another orvano commit first
dart test --exclude-tags conformance     # the unit tests
```

The conformance suite runs every shared scenario against a real Orvano server and the stub server, from the pinned commit's `api/conformance/compose.yaml`:

```bash
dart run tool/regenerate.dart --fetch-only
docker build --file .orvano/deploy/Dockerfile --tag orvano:pinned .orvano
ORVANO_IMAGE=orvano ORVANO_IMAGE_TAG=pinned docker compose --file .orvano/api/conformance/compose.yaml up --detach --wait
dart test --tags conformance
```

Set `ORVANO_CONFORMANCE_PARTIAL=1` when you run only some scenarios with `--name`. A scenario that can't run here goes in `test/conformance/skip.json` with a reason and an issue link.

## License

Apache License 2.0 (see `LICENSE` and `NOTICE`). The name "Orvano" and its logo aren't covered by the license; see [TRADEMARKS.md](https://github.com/orvanohq/orvano/blob/main/TRADEMARKS.md).
