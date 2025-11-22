# Supabase Flutter API Context

This document provides a reference for using Supabase with Flutter, based on the latest `supabase_flutter` package (v2.x).

## 1. Initialization

Add `supabase_flutter` to `pubspec.yaml`.

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(MyApp());
}

// Access the client anywhere
final supabase = Supabase.instance.client;
```

## 2. Authentication

### Sign Up (Email/Password)
```dart
final AuthResponse res = await supabase.auth.signUp(
  email: 'email@example.com',
  password: 'example-password',
);
final User? user = res.user;
```

### Sign In (Email/Password)
```dart
final AuthResponse res = await supabase.auth.signInWithPassword(
  email: 'email@example.com',
  password: 'example-password',
);
```

### Sign Out
```dart
await supabase.auth.signOut();
```

### Listen to Auth State Changes
```dart
supabase.auth.onAuthStateChange.listen((data) {
  final AuthChangeEvent event = data.event;
  final Session? session = data.session;
  // Handle event (signedIn, signedOut, etc.)
});
```

## 3. Database (Postgres)

### Select
```dart
// Get all rows
final data = await supabase.from('cities').select();

// Filter
final data = await supabase
  .from('cities')
  .select()
  .eq('country_id', 123)
  .order('name', ascending: true);

// Single row (expecting one)
final data = await supabase
  .from('cities')
  .select()
  .eq('id', 1)
  .single();
```

### Insert
```dart
await supabase.from('cities').insert({
  'name': 'The Shire',
  'country_id': 554,
});
```

### Update
```dart
await supabase.from('cities').update({
  'name': 'Middle Earth',
}).eq('id', 1);
```

### Delete
```dart
await supabase.from('cities').delete().eq('id', 1);
```

## 4. Realtime

### Stream (Flutter specific)
Use `SupabaseStreamBuilder` to get a `Stream` of data, useful with `StreamBuilder` widget.

```dart
final stream = supabase
  .from('cities')
  .stream(primaryKey: ['id'])
  .eq('country_id', 123)
  .order('name');

// In a widget
StreamBuilder(
  stream: stream,
  builder: (context, snapshot) {
    // ...
  },
)
```

### Channel (Broadcast/Presence/Postgres Changes)
```dart
final channel = supabase.channel('public:cities');

channel.onPostgresChanges(
  event: PostgresChangeEvent.all,
  schema: 'public',
  table: 'cities',
  callback: (payload) {
    print('Change received: ${payload.toString()}');
  },
).subscribe();
```

## 5. Storage

### Upload File
```dart
final File file = File('path/to/file');
await supabase.storage.from('avatars').upload('public/avatar1.png', file);
```

### Get Public URL
```dart
final String publicUrl = supabase
  .storage
  .from('avatars')
  .getPublicUrl('public/avatar1.png');
```

## 6. Edge Functions

```dart
final data = await supabase.functions.invoke('hello-world');
```
