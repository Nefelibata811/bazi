import 'package:bazi_app/domain/services/bazi_record_repository.dart';
import 'package:bazi_app/features/history/infrastructure/collections_local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('CollectionsLocalCache round-trip', () async {
    const userId = 'user-1';
    final items = [
      CollectionModel(
        id: 'c1',
        userId: userId,
        name: '家人',
        createdAt: DateTime(2024, 1, 2),
      ),
    ];

    await CollectionsLocalCache.save(userId, items);
    final loaded = await CollectionsLocalCache.load(userId);
    expect(loaded, hasLength(1));
    expect(loaded.first.name, '家人');

    await CollectionsLocalCache.clear(userId);
    expect(await CollectionsLocalCache.load(userId), isEmpty);
  });
}
