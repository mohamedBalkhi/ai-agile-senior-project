import 'dart:io';
import 'package:just_audio/just_audio.dart';

class CustomHeaderAudioSource extends StreamAudioSource {
  final Uri uri;
  final Map<String, String> headers;

  CustomHeaderAudioSource(this.uri, {this.headers = const {}});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final client = HttpClient();
    final request = await client.getUrl(uri);

    // Add custom headers
    headers.forEach((key, value) {
      request.headers.set(key, value);
    });

    // Handle byte range requests for seeking
    if (start != null || end != null) {
      request.headers.add(
        HttpHeaders.rangeHeader, 
        'bytes=${start ?? ''}-${end ?? ''}'
      );
    }

    final response = await request.close();

    // Handle both OK and PartialContent status codes
    if (response.statusCode != HttpStatus.ok && 
        response.statusCode != HttpStatus.partialContent) {
      throw HttpException(
        'Failed to load audio: ${response.statusCode} ${response.reasonPhrase}',
        uri: uri
      );
    }

    return StreamAudioResponse(
      sourceLength: response.contentLength,
      contentLength: response.contentLength,
      offset: start ?? 0,
      stream: response,
      contentType: response.headers.contentType?.toString() ?? 'audio/mpeg',
    );
  }
} 