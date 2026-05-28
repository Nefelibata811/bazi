// 文件：phoneutils
//
// 路径：`lib/core/phone_utils.dart`。
//
abstract final class PhoneUtils {
  /// Normalizes input to E.164, e.g. `+8613812345678`.
  static String? toE164(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    String national;
    if (digits.startsWith('86') && digits.length == 13) {
      national = digits.substring(2);
    } else if (digits.length == 11) {
      national = digits;
    } else {
      return null;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(national)) {
      return null;
    }
    return '+86$national';
  }

  /// Display as `138 **** 5678`.
  static String mask(String? e164) {
    if (e164 == null || e164.isEmpty) return '未绑定';
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    final national = digits.length >= 13 && digits.startsWith('86')
        ? digits.substring(2)
        : digits.length == 11
            ? digits
            : digits;
    if (national.length != 11) return e164;
    return '${national.substring(0, 3)} **** ${national.substring(7)}';
  }
}
