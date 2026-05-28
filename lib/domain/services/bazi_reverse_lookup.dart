// 文件：八字反查lookup
//
// 路径：`lib/domain/services/bazi_reverse_lookup.dart`。
//
import '../entities/bazi_reverse_candidate.dart';
import '../entities/bazi_reverse_query.dart';

abstract class BaziReverseLookup {
  Future<List<BaziReverseCandidate>> search(BaziReverseQuery query);
}
