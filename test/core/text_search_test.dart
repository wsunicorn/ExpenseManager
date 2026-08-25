import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/utils/text_search.dart';

/// Bỏ dấu tiếng Việt cho tìm kiếm — `01_DAC_TA_TINH_NANG.md` mục C.4.
void main() {
  group('removeDiacritics', () {
    test('bỏ dấu nhưng giữ hoa thường', () {
      expect(removeDiacritics('Cơm trưa'), 'Com trua');
      expect(removeDiacritics('ĐẦU TƯ'), 'DAU TU');
      expect(removeDiacritics('Tiền điện nước'), 'Tien dien nuoc');
    });

    test('phủ hết 6 nguyên âm có dấu và chữ đ', () {
      expect(removeDiacritics('àáạảãâầấậẩẫăằắặẳẵ'), 'a' * 17);
      expect(removeDiacritics('èéẹẻẽêềếệểễ'), 'e' * 11);
      expect(removeDiacritics('ìíịỉĩ'), 'i' * 5);
      expect(removeDiacritics('òóọỏõôồốộổỗơờớợởỡ'), 'o' * 17);
      expect(removeDiacritics('ùúụủũưừứựửữ'), 'u' * 11);
      expect(removeDiacritics('ỳýỵỷỹ'), 'y' * 5);
      expect(removeDiacritics('đĐ'), 'dD');
    });

    test('chữ không dấu giữ nguyên', () {
      expect(removeDiacritics('MoMo 2026'), 'MoMo 2026');
      expect(removeDiacritics(''), '');
    });

    test('không đụng tới chữ viết ngoài hệ Latin', () {
      expect(removeDiacritics('東京 🍜'), '東京 🍜');
    });

    /// Dấu Latin dùng chung với ngôn ngữ khác cũng bị bỏ — `é` của "café" là
    /// đúng ký tự U+00E9 mà tiếng Việt dùng trong "bé". Không tách được, và
    /// cũng không cần tách: bỏ dấu nó vẫn cho kết quả tìm kiếm đúng.
    test('dấu Latin dùng chung cũng được bỏ', () {
      expect(removeDiacritics('café'), 'cafe');
    });
  });

  group('normalizeForSearch', () {
    test('bỏ dấu và viết thường', () {
      expect(normalizeForSearch('Cơm Trưa'), 'com trua');
      expect(normalizeForSearch('ĐẦU TƯ'), 'dau tu');
    });

    test('gom khoảng trắng thừa và cắt hai đầu', () {
      expect(normalizeForSearch('  Cơm   trưa  '), 'com trua');
      expect(normalizeForSearch('a\t\nb'), 'a b');
    });

    test('chuỗi rỗng và chuỗi toàn khoảng trắng ra rỗng', () {
      expect(normalizeForSearch(''), '');
      expect(normalizeForSearch('    '), '');
    });

    /// Bất biến quan trọng: chuẩn hoá hai lần cũng ra kết quả như một lần.
    /// Nhờ vậy chuẩn hoá lúc ghi và lúc tìm không bao giờ lệch nhau.
    test('chuẩn hoá là luỹ đẳng', () {
      for (final s in ['Cơm trưa', '  ĐẦU  TƯ ', 'MoMo', '']) {
        final once = normalizeForSearch(s);
        expect(normalizeForSearch(once), once, reason: 'với "$s"');
      }
    });

    test('mọi dạng người dùng hay gõ đều quy về cùng một chuỗi', () {
      const expected = 'com trua van phong';
      for (final s in [
        'Cơm trưa văn phòng',
        'COM TRUA VAN PHONG',
        'cơm trưa văn phòng',
        '  Cơm  trưa  văn  phòng  ',
      ]) {
        expect(normalizeForSearch(s), expected, reason: 'với "$s"');
      }
    });
  });
}
