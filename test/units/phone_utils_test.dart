// 文件：单元测试 — phoneutils
//
// 验证 phoneutils 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/core/phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneUtils.toE164', () {
    test('accepts 11-digit national number', () {
      expect(PhoneUtils.toE164('13812345678'), '+8613812345678');
    });

    test('accepts number with 86 prefix', () {
      expect(PhoneUtils.toE164('8613812345678'), '+8613812345678');
    });

    test('rejects invalid number', () {
      expect(PhoneUtils.toE164('12345'), isNull);
      expect(PhoneUtils.toE164('23812345678'), isNull);
    });
  });

  group('PhoneUtils.mask', () {
    test('masks E.164 phone', () {
      expect(PhoneUtils.mask('+8613812345678'), '138 **** 5678');
    });
  });
}
