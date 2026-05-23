import '../entities/bazi_reverse_candidate.dart';
import '../entities/bazi_reverse_query.dart';

abstract class BaziReverseLookup {
  Future<List<BaziReverseCandidate>> search(BaziReverseQuery query);
}
