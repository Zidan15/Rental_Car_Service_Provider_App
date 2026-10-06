import 'package:flutter_test/flutter_test.dart';
import 'package:fleetwise/services/env_service.dart';

void main() {
  setUp(() {
    Env.reset();
  });

  tearDown(() {
    Env.reset();
  });

  group('Env Service - Service Provider App Configuration', () {
    test('parses standard unquoted key-value pairs', () {
      const sampleEnv = '''
SUPABASE_URL=https://provider-project.supabase.co
SUPABASE_ANON_KEY=provider-anon-key-67890
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://provider-project.supabase.co'));
      expect(Env.supabaseAnonKey, equals('provider-anon-key-67890'));
    });

    test('strips double and single quotes around environment values', () {
      const sampleEnv = '''
SUPABASE_URL="https://quoted-url.supabase.co"
SUPABASE_ANON_KEY='single-quoted-key'
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://quoted-url.supabase.co'));
      expect(Env.supabaseAnonKey, equals('single-quoted-key'));
    });

    test('ignores full-line comments and empty rows', () {
      const sampleEnv = '''
# Database configuration for Rent.Goa Provider App
# Do not commit live keys

SUPABASE_URL=https://my-db.supabase.co

# Anon API key
SUPABASE_ANON_KEY=valid-anon-key-provider
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://my-db.supabase.co'));
      expect(Env.supabaseAnonKey, equals('valid-anon-key-provider'));
    });

    test('returns default value when key is not present', () {
      expect(Env.get('MISSING_KEY'), equals(''));
      expect(Env.get('MISSING_KEY', defaultValue: 'default_fallback'), equals('default_fallback'));
    });

    test('handles whitespace around keys and values gracefully', () {
      const sampleEnv = '''
   SUPABASE_URL   =   https://spaced.supabase.co   
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://spaced.supabase.co'));
    });

    test('handles values containing multiple equal signs', () {
      const sampleEnv = '''
CUSTOM_TOKEN=abc=123=xyz==
''';

      Env.parse(sampleEnv);

      expect(Env.get('CUSTOM_TOKEN'), equals('abc=123=xyz=='));
    });

    test('reset clears all loaded configuration values', () {
      Env.parse('SUPABASE_URL=https://active.supabase.co');
      expect(Env.supabaseUrl, equals('https://active.supabase.co'));

      Env.reset();
      expect(Env.supabaseUrl, equals(''));
    });
  });
}
