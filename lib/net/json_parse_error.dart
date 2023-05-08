class JsonParseException implements Exception {
final String message;

  JsonParseException(this.message);

  @override
  String toString() {
    String report = "Error: $message";
    return report;
  }
}
