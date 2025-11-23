// Sends RPCs to a soia service.
// See start_service.dart for how to start one.
//
// Run:
//   dart run bin/call_service.dart

import 'package:soia/soia.dart' as soia;
import 'package:soia_dart_example/soiagen/service.dart';
import 'package:soia_dart_example/soiagen/user.dart';

void main() async {
  final serviceClient = soia.ServiceClient('http://localhost:8787/myapi');

  print('');
  print('About to add 2 users: John Doe and Tarzan');

  await serviceClient.wrap(addUserMethod).invoke(
        AddUserRequest(
          user: User(
            userId: 42,
            name: 'John Doe',
            quote: '',
            pets: [],
            subscriptionStatus: User_SubscriptionStatus.unknown,
          ),
        ),
      );

  await serviceClient.wrap(addUserMethod).invoke(
    AddUserRequest(user: tarzan),
    headers: {'X-Foo': 'hi'},
  );

  // Note: The Dart ServiceClient API doesn't currently provide access to
  // response headers. This is a limitation compared to the Python version.

  print('Done');

  final foundUser = await serviceClient.wrap(getUserMethod).invoke(
        GetUserRequest(userId: 123),
      );

  print('Found user: $foundUser');

  serviceClient.close();
}
