import 'dart:io';

import 'package:mocktail/mocktail.dart';

// note, copied from https://stackoverflow.com/a/49167253/4299560

class MockHttpOverrides extends HttpOverrides {
  MockHttpOverrides([this.dataByPath = const {}]);

  final Map<String, List<int>> dataByPath;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();
    final request = MockHttpClientRequest();
    final response = MockHttpClientResponse(dataByPath);
    final headers = MockHttpHeaders();

    /// Comment the exception when stub is missing from client
    /// because it complains about missing autoUncompress stub
    /// even setting it up as shown bellow.
    // throwOnMissingStub(client);
    throwOnMissingStub(request);
    throwOnMissingStub(response);
    throwOnMissingStub(headers);
    registerFallbackValue(Uri.parse('https://example.com'));

    // This line is not necessary, it can be omitted.
    when(() => client.autoUncompress).thenReturn(true);

    // Use decompressed, otherwise you will get bad data.
    when(
      () => response.compressionState,
    ).thenReturn(HttpClientResponseCompressionState.decompressed);

    // Capture the url and assigns it to requestedUrl from MockHttpClientResponse.
    when(() => client.getUrl(captureAny())).thenAnswer((invocation) {
      response.requestedUrl = invocation.positionalArguments[0] as Uri;
      return Future<HttpClientRequest>.value(request);
    });

    // This line is not necessary, it can be omitted.
    when(() => request.headers).thenAnswer((_) => headers);

    when(
      () => request.close(),
    ).thenAnswer((_) => Future<HttpClientResponse>.value(response));

    when(
      () => response.contentLength,
    ).thenAnswer((_) => response.findData().length);

    when(() => response.statusCode).thenReturn(HttpStatus.ok);

    when(
      () => response.listen(
        captureAny(),
        cancelOnError: captureAny(named: 'cancelOnError'),
        onDone: captureAny(named: 'onDone'),
        onError: captureAny(named: 'onError'),
      ),
    ).thenAnswer((invocation) {
      final onData =
          invocation.positionalArguments[0] as void Function(List<int>);

      final onDone = invocation.namedArguments[#onDone] as void Function();

      final onError =
          invocation.namedArguments[#onError]
              as void Function(Object, [StackTrace]);

      final cancelOnError = invocation.namedArguments[#cancelOnError] as bool;

      return Stream<List<int>>.fromIterable([response.findData()]).listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );
    });

    return client;
  }
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.dataByPath);
  final Map<String, List<int>> dataByPath;
  Uri? requestedUrl;

  // It is not necessary to override this method to pass the test.
  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, List<int> element) combine,
  ) {
    return Stream.fromIterable([
      findData(),
    ]).fold(initialValue, combine as S Function(S, List<int>?));
  }

  List<int> findData() {
    final uriString = requestedUrl?.toString() ?? '';
    for (final path in dataByPath.keys) {
      if (path == uriString || path.matchAsPrefix(uriString) != null) {
        return dataByPath[path]!;
      }
    }
    return Uri.parse(placeholderImage).data?.contentAsBytes() ?? [0];
  }
}

class MockHttpHeaders extends Mock implements HttpHeaders {}

const placeholderImage =
    'data:image/png;base64,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';
