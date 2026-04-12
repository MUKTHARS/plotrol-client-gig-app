import '../common_models.dart';

class HouseholdsResponse {
  List<Household>? households;

  HouseholdsResponse({this.households});

  HouseholdsResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns singular "Household" key (not plural "Households")
    final raw = json['Household'] ?? json['Households'];
    if (raw != null) {
      households = <Household>[];
      raw.forEach((v) {
        households!.add(Household.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (households != null) {
      data['Households'] = households!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Household {
  String? id;
  String? tenantId;
  int? rowVersion;
  bool? nonRecoverableError;
  int? memberCount;
  Address? address;
  AuditDetails? auditDetails;
  AuditDetails? clientAuditDetails;
  String? clientReferenceId;
  bool? isDeleted;
  String? householdType;
  AdditionalFields? additionalFields;
  List<String>? imageUrls;

  Household({
    this.id,
    this.tenantId,
    this.rowVersion,
    this.memberCount,
    this.address,
    this.auditDetails,
    this.clientAuditDetails,
    this.clientReferenceId,
    this.isDeleted = false,
    this.householdType,
    this.additionalFields,
    this.nonRecoverableError = false,
    this.imageUrls,
  });

  Household.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tenantId = json['tenantId'];
    rowVersion = json['rowVersion'];

    memberCount = json['memberCount'];
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
    auditDetails = json['auditDetails'] != null ? AuditDetails.fromJson(json['auditDetails']) : null;
    clientAuditDetails = json['clientAuditDetails'] != null ? AuditDetails.fromJson(json['clientAuditDetails']) : null;
    clientReferenceId = json['clientReferenceId'];
    isDeleted = json['isDeleted'];
    householdType = json['householdType'];
    nonRecoverableError = json['nonRecoverableError'];
    additionalFields = json['additionalFields'] != null
        ? AdditionalFields.fromJson(json['additionalFields'])
        : null;
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tenantId'] = tenantId;
    data['rowVersion'] = rowVersion;
    data['memberCount'] = memberCount;
    data['nonRecoverableError'] = nonRecoverableError;
    if (address != null) {
      data['address'] = address!.toJson();
    }
    if (auditDetails != null) {
      data['auditDetails'] = auditDetails!.toJson();
    }
    if (clientAuditDetails != null) {
      data['clientAuditDetails'] = clientAuditDetails!.toJson();
    }
    data['clientReferenceId'] = clientReferenceId;
    data['isDeleted'] = isDeleted;
    data['householdType'] = householdType;
    if (additionalFields != null) {
      data['additionalFields'] = additionalFields!.toJson();
    }
    if (imageUrls != null) {
      data['imageUrls'] = imageUrls;
    }
    return data;
  }
}

