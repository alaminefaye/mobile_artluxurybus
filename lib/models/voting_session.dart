class VotingSession {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool showResultsDuringVote;
  final int totalVotes;
  final bool hasVoted;
  final VotedCandidate? votedCandidate;
  final List<Candidate> candidates;

  VotingSession({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.showResultsDuringVote,
    required this.totalVotes,
    this.hasVoted = false,
    this.votedCandidate,
    required this.candidates,
  });

  factory VotingSession.fromJson(Map<String, dynamic> json) {
    return VotingSession(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      showResultsDuringVote: json['show_results_during_vote'] as bool? ?? false,
      totalVotes: json['total_votes'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? false,
      votedCandidate: json['voted_candidate'] != null
          ? VotedCandidate.fromJson(
              json['voted_candidate'] as Map<String, dynamic>)
          : null,
      candidates: (json['candidates'] as List<dynamic>?)
              ?.map((c) => Candidate.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'show_results_during_vote': showResultsDuringVote,
      'total_votes': totalVotes,
      'has_voted': hasVoted,
      'voted_candidate': votedCandidate?.toJson(),
      'candidates': candidates.map((c) => c.toJson()).toList(),
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String get timeRemaining {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return 'Commence dans ${_formatDuration(startTime.difference(now))}';
    } else if (now.isBefore(endTime)) {
      return 'Termine dans ${_formatDuration(endTime.difference(now))}';
    } else {
      return 'Terminé';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
}

class Candidate {
  final int id;
  final String candidateName;
  final String? candidateNumber;
  final String? photoPath;
  final String? description;
  final int voteCount;
  final double votePercentage;

  Candidate({
    required this.id,
    required this.candidateName,
    this.candidateNumber,
    this.photoPath,
    this.description,
    this.voteCount = 0,
    this.votePercentage = 0.0,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as int,
      candidateName: json['candidate_name'] as String,
      candidateNumber: json['candidate_number'] as String?,
      photoPath: json['photo_path'] as String?,
      description: json['description'] as String?,
      voteCount: json['vote_count'] as int? ?? 0,
      votePercentage: (json['vote_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidate_name': candidateName,
      'candidate_number': candidateNumber,
      'photo_path': photoPath,
      'description': description,
      'vote_count': voteCount,
      'vote_percentage': votePercentage,
    };
  }
}

class VotedCandidate {
  final int id;
  final String candidateName;

  VotedCandidate({
    required this.id,
    required this.candidateName,
  });

  factory VotedCandidate.fromJson(Map<String, dynamic> json) {
    return VotedCandidate(
      id: json['id'] as int,
      candidateName: json['candidate_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidate_name': candidateName,
    };
  }
}

class VoteResult {
  final int voteId;
  final String candidateName;
  final DateTime votedAt;
  final int totalVotes;

  VoteResult({
    required this.voteId,
    required this.candidateName,
    required this.votedAt,
    required this.totalVotes,
  });

  factory VoteResult.fromJson(Map<String, dynamic> json) {
    return VoteResult(
      voteId: json['vote_id'] as int,
      candidateName: json['candidate_name'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
      totalVotes: json['total_votes'] as int,
    );
  }
}
