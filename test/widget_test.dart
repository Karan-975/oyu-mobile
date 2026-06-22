import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/data_models.dart';
import 'package:mobile_app/widgets/app_widgets.dart';

void main() {
  group('Models Serialization Tests', () {
    test('Borehole toJson & fromJson', () {
      final jsonMap = {
        'id': 'bh-1',
        'unique_id': 'BH-001',
        'village': 'Village A',
        'taluka': 'Taluka B',
        'district': 'District C',
        'state': 'State D',
        'latitude': 12.345,
        'longitude': 67.890,
        'water_table_depth': '50m',
        'formation_type': 'Sandy',
        'status': 'active',
        'assignment_status': 'assigned',
        'ngo_id': 'ngo-1',
        'contractor_id': 'contractor-1',
        'created_at': '2026-06-18T10:00:00.000Z',
      };

      final borehole = Borehole.fromJson(jsonMap);
      expect(borehole.id, 'bh-1');
      expect(borehole.uniqueId, 'BH-001');
      expect(borehole.latitude, 12.345);
      expect(borehole.longitude, 67.890);

      final serialized = borehole.toJson();
      expect(serialized['id'], 'bh-1');
      expect(serialized['unique_id'], 'BH-001');
      expect(serialized['latitude'], 12.345);
    });

    test('SurveySubmission toJson & fromJson', () {
      final jsonMap = {
        'id': 'sub-1',
        'borehole_id': 'bh-1',
        'survey_module_id': 'recce',
        'form_data': {'question1': 'answer1'},
        'latitude': 12.345,
        'longitude': 67.890,
        'status': 'submitted',
      };

      final submission = SurveySubmission.fromJson(jsonMap);
      expect(submission.id, 'sub-1');
      expect(submission.boreholId, 'bh-1');
      expect(submission.surveyModuleId, 'recce');
      expect(submission.formData['question1'], 'answer1');

      final serialized = submission.toJson();
      expect(serialized['id'], 'sub-1');
      expect(serialized['borehole_id'], 'bh-1');
      expect(serialized['form_data']['question1'], 'answer1');
    });
  });

  group('Widget Tests', () {
    testWidgets('AppCard renders child and responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () {
                tapped = true;
              },
              child: const Text('Hello World'),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);

      await tester.tap(find.text('Hello World'));
      expect(tapped, isTrue);
    });

    testWidgets('SectionHeader renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Main Title',
              subtitle: 'Sub Title Description',
            ),
          ),
        ),
      );

      expect(find.text('Main Title'), findsOneWidget);
      expect(find.text('Sub Title Description'), findsOneWidget);
    });
  });
}
