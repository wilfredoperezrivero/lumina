import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumina/services/auth_service.dart';
import 'package:mockito/mockito.dart';

// Mock User class since we can't easily instantiate it with all properties
class MockUser extends Mock implements User {
  @override
  final Map<String, dynamic>? userMetadata;
  @override
  final Map<String, dynamic> appMetadata;

  MockUser({this.userMetadata, required this.appMetadata});
}

void main() {
  group('AuthService.resolveUserRole', () {
    test('returns null when user is null', () {
      expect(AuthService.resolveUserRole(null), isNull);
    });

    test('returns role from userMetadata if present', () {
      final user = User(
        id: '123',
        appMetadata: {},
        userMetadata: {'role': 'admin'},
        aud: 'authenticated',
        createdAt: '',
      );
      expect(AuthService.resolveUserRole(user), 'admin');
    });

    test('returns role from appMetadata if not in userMetadata', () {
      final user = User(
        id: '123',
        appMetadata: {'role': 'family'},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '',
      );
      expect(AuthService.resolveUserRole(user), 'family');
    });

    test('returns null if role is missing in both', () {
      final user = User(
        id: '123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '',
      );
      expect(AuthService.resolveUserRole(user), isNull);
    });

    test('returns null if role is empty string', () {
      final user = User(
        id: '123',
        appMetadata: {'role': ''},
        userMetadata: {'role': ''},
        aud: 'authenticated',
        createdAt: '',
      );
      expect(AuthService.resolveUserRole(user), isNull);
    });
  });
}
