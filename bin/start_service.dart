// Starts a soia service on http://localhost:8787/myapi
//
// Run with:
//   dart run bin/start_service.dart
//
// Run call_service.dart to call this service from another process.

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soia/soia.dart' as soia;
import 'package:soia_dart_example/soiagen/service.dart';
import 'package:soia_dart_example/soiagen/user.dart';

/// Custom request metadata that includes both request and response headers.
class RequestMetadata {
  final Map<String, String> requestHeaders;
  final Map<String, String> responseHeaders;

  RequestMetadata(this.requestHeaders, this.responseHeaders);
}

class ServiceImpl {
  final Map<int, User> _idToUser = {};

  GetUserResponse getUser(
    GetUserRequest request,
    RequestMetadata metadata,
  ) {
    final userId = request.userId;
    final user = _idToUser[userId];
    return GetUserResponse(user: user);
  }

  AddUserResponse addUser(
    AddUserRequest request,
    RequestMetadata metadata,
  ) {
    final user = request.user;
    if (user.userId == 0) {
      throw ArgumentError('invalid user id');
    }
    print('Adding user: $user');
    _idToUser[user.userId] = user;
    metadata.responseHeaders['x-bar'] =
        (metadata.requestHeaders['x-foo'] ?? '').toUpperCase();
    return AddUserResponse();
  }
}

void main() async {
  final serviceImpl = ServiceImpl();

  Future<Response> handleRequest(Request request) async {
    final requestBody = request.method == 'POST'
        ? await request.readAsString()
        : Uri.decodeComponent(request.url.query);

    final requestHeaders = <String, String>{};
    request.headers.forEach((key, value) {
      requestHeaders[key.toLowerCase()] = value;
    });

    final responseHeaders = <String, String>{};
    final metadata = RequestMetadata(requestHeaders, responseHeaders);

    // Build a service for this request with access to metadata
    final soiaService = soia.Service.builderWithMeta<RequestMetadata>(
      (_) => metadata,
    ).addMethod(addUserMethod, (req, meta) async {
      return serviceImpl.addUser(req, meta);
    }).addMethod(getUserMethod, (req, meta) async {
      return serviceImpl.getUser(req, meta);
    }).build();

    final rawResponse = await soiaService.handleRequest(
      requestBody,
      requestHeaders,
    );

    return Response(
      rawResponse.statusCode,
      body: rawResponse.data,
      headers: {
        'content-type': rawResponse.contentType,
        ...responseHeaders,
      },
    );
  }

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler((request) async {
    if (request.url.path == '') {
      return Response.ok('Hello, World!');
    } else if (request.url.path == 'myapi') {
      return await handleRequest(request);
    } else {
      return Response.notFound('Not found');
    }
  });

  final server = await shelf_io.serve(handler, 'localhost', 8787);
  print('Serving at http://${server.address.host}:${server.port}');
}
