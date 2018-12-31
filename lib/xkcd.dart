class Xkcd {
  final String month;
  final int number;
  final String year;
  final String safeTitle;
  final String alt;
  final String img;
  final String day;

  Xkcd({this.month, this.number, this.year, this.safeTitle, this.alt, this.img, this.day});

  factory Xkcd.fromJson(Map<String, dynamic> json) {
    return Xkcd(
      month: json['month'] as String,
      number: json['num'] as int,
      year: json['year'] as String,
      safeTitle: json['safe_title'] as String,
      alt: json['alt'] as String,
      img: json['img'] as String,
      day: json['day'] as String
    );
  }
}