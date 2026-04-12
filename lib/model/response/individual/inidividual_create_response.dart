import 'individual_response.dart';

class IndividualCreateResponse {
  Individual? individual;

  IndividualCreateResponse({this.individual});

  IndividualCreateResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns "Individual" as an array even for a single record.
    final raw = json['Individual'];
    if (raw is List && (raw as List).isNotEmpty) {
      individual = Individual.fromJson((raw as List).first as Map<String, dynamic>);
    } else if (raw is Map) {
      individual = Individual.fromJson(raw as Map<String, dynamic>);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (individual != null) {
      data['Individual'] = individual!.toJson();
    }
    return data;
  }
}
