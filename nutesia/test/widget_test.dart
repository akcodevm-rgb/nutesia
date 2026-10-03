import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutesia/shared/models/member_model.dart';
import 'package:nutesia/shared/models/nutrition_space_model.dart';
import 'package:nutesia/shared/widgets/header_profile_switcher.dart';
import 'package:nutesia/features/profile/providers/nutrition_space_provider.dart';
import 'package:nutesia/features/home/providers/home_provider.dart';

void main() {
  testWidgets('HeaderProfileSwitcher renders active member profile name', (WidgetTester tester) async {
    final testSpace = NutritionSpaceModel(
      id: 'test_space_1',
      ownerUserId: 'user_1',
      mode: 'PERSONAL',
      activeProfileId: 'mem_1',
      profiles: [
        MemberModel(
          id: 'mem_1',
          spaceId: 'test_space_1',
          name: 'Sarah',
          relationship: 'owner',
          dateOfBirth: '1995-05-10',
          heightCm: 165.0,
          weightKg: 58.0,
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final spaceProvider = TestNutritionSpaceProvider(testSpace);
    final homeProvider = HomeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NutritionSpaceProvider>.value(value: spaceProvider),
          ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HeaderProfileSwitcher(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sarah'), findsOneWidget);
  });
}

class TestNutritionSpaceProvider extends NutritionSpaceProvider {
  final NutritionSpaceModel _initialSpace;

  TestNutritionSpaceProvider(this._initialSpace);

  @override
  NutritionSpaceModel? get space => _initialSpace;

  @override
  String get activeMemberId => _initialSpace.activeProfileId;

  @override
  MemberModel? get activeMember => _initialSpace.profiles.first;

  @override
  Future<void> loadSpace() async {}

  @override
  Future<void> loadWallet() async {}
}
