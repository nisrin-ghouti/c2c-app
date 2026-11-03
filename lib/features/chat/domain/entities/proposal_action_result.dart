enum ProposeMeetingResult {
  ok,
  forbidden,
  notFound,
  invalidWindow,

  /// These two students already have an accepted meeting on that date — a
  /// student may meet the same student only once per day.
  dailyPairLimit,

  /// One of the two already has accepted meetings with 5 different students
  /// on that date, which is the daily cap.
  dailyPartnerLimitSelf,
  dailyPartnerLimitOther,

  unknown,
}

enum RespondProposalResult {
  ok,
  forbidden,
  notFound,
  alreadyResponded,

  /// Accepting would break a daily meeting limit (see [ProposeMeetingResult]).
  dailyPairLimit,
  dailyPartnerLimitSelf,
  dailyPartnerLimitOther,

  unknown,
}
