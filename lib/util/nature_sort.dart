class NaturalSort {
  NaturalSort._();

  static int _commonPrefix(String a, String b) {
    int m = a.length;
    int n = b.length;
    if (n < m) {
      m = n;
    }
    if (m == 0) {
      return 0;
    }

    for (int i = 0; i < m; i++) {
      String ca = a[i];
      String cb = b[i];
      if ((ca.compareTo('0') >= 0 && ca.compareTo('9') <= 0) ||
          (cb.compareTo('0') >= 0 && cb.compareTo('9') <= 0) ||
          ca != cb) {
        return i;
      }
    }
    return m;
  }

  static int _digits(String s) {
    for (int i = 0; i < s.length; i++) {
      String c = s[i];
      if (c.compareTo('0') < 0 || c.compareTo('9') > 0) {
        return i;
      }
    }
    return s.length;
  }

  static int compare(String a, String b) {
    if (a == b) {
      return 0;
    }

    while (true) {
      int p = _commonPrefix(a, b);
      if (p != 0) {
        a = a.substring(p);
        b = b.substring(p);
      }
      if (a.isEmpty) {
        return b.isNotEmpty ? -1 : 1;
      }
      int ia = _digits(a);
      if (ia > 0) {
        int ib = _digits(b);
        if (ib > 0) {
          // Both sides have digits.
          int an = int.parse(a.substring(0, ia));
          int bn = int.parse(b.substring(0, ib));
          if (an != bn) {
            return an.compareTo(bn);
          }
          // Semantically the same digits.
          if (ia != a.length && ib != b.length) {
            a = a.substring(ia);
            b = b.substring(ib);
            continue;
          }
        }
      }
      return a.compareTo(b);
    }
  }
}
