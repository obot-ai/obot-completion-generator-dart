class FetcherException implements Exception {
  final String message;

  FetcherException(this.message);

  @override
  String toString() {
    return 'FetcherException(message: $message)';
  }
}

class FetchFailedException extends FetcherException {
  final int statusCode;
  final String responseBody;

  FetchFailedException(super.message, this.statusCode, this.responseBody);

  @override
  String toString() {
    return 'FetchFailedException(message: $message, statusCode: $statusCode)';
  }
}

class UnexpectedResponseBodyException extends FetcherException {
  final int statusCode;

  UnexpectedResponseBodyException(super.message, this.statusCode);

  @override
  String toString() {
    return 'UnexpectedResponseBodyException(message: $message, statusCode: $statusCode)';
  }
}
