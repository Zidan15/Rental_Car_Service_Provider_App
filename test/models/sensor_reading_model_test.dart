import 'package:flutter_test/flutter_test.dart';
import 'package:fleetwise/models/sensor_reading.dart';

void main() {
  group('SensorReading Model', () {
    test('deserializes from JSON with double value', () {
      final json = {
        'timestamp': '2026-03-15T12:30:00.000Z',
        'value': 88.5,
      };

      final reading = SensorReading.fromJson(json);

      expect(reading.timestamp, equals(DateTime.parse('2026-03-15T12:30:00.000Z')));
      expect(reading.value, equals(88.5));
    });

    test('deserializes from JSON with integer value safely (num casting)', () {
      final json = {
        'timestamp': '2026-03-15T12:30:00.000Z',
        'value': 90, // int instead of double
      };

      final reading = SensorReading.fromJson(json);

      expect(reading.timestamp, equals(DateTime.parse('2026-03-15T12:30:00.000Z')));
      expect(reading.value, equals(90.0));
    });

    test('deserializes safely with empty map or null fields (null safety defaults)', () {
      final readingEmpty = SensorReading.fromJson({});
      expect(readingEmpty.value, equals(0.0));
      expect(readingEmpty.timestamp, isNotNull);

      final readingNulls = SensorReading.fromJson({
        'timestamp': null,
        'value': null,
      });
      expect(readingNulls.value, equals(0.0));
      expect(readingNulls.timestamp, isNotNull);
    });

    test('handles malformed timestamp string gracefully', () {
      final reading = SensorReading.fromJson({
        'timestamp': 'not-a-valid-timestamp',
        'value': 42.0,
      });
      expect(reading.value, equals(42.0));
      expect(reading.timestamp, isNotNull);
    });

    test('serializes to JSON correctly', () {
      final date = DateTime.parse('2026-03-15T12:30:00.000Z');
      final reading = SensorReading(
        timestamp: date,
        value: 75.2,
      );

      final json = reading.toJson();

      expect(json['timestamp'], equals(date.toIso8601String()));
      expect(json['value'], equals(75.2));
    });
  });
}
