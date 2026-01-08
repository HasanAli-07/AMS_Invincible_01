class Subject {
  final String id;
  final String name;
  final String code;
  final String department;
  final int credits;
  final bool isLab; // Lab subject (true) or Theory subject (false)
  final String? description;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.credits,
    required this.isLab,
    this.description,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? department,
    int? credits,
    bool? isLab,
    String? description,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      department: department ?? this.department,
      credits: credits ?? this.credits,
      isLab: isLab ?? this.isLab,
      description: description ?? this.description,
    );
  }
}

