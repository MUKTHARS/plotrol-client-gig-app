import '../common_models.dart';

class HouseholdMembersResponse {
  List<HouseholdMember>? householdMembers;

  HouseholdMembersResponse({this.householdMembers});

  HouseholdMembersResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns singular "HouseholdMember" key (not plural "HouseholdMembers")
    final raw = json['HouseholdMember'] ?? json['HouseholdMembers'];
    if (raw != null) {
      householdMembers = <HouseholdMember>[];
      raw.forEach((v) {
        householdMembers!.add(HouseholdMember.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (householdMembers != null) {
      data['HouseholdMembers'] =
          householdMembers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HouseholdMember {
  String? id;
  String? householdId;
  String? householdClientReferenceId;
  String? clientReferenceId;
  String? individualId;
  String? individualClientReferenceId;
  bool? isHeadOfHousehold;
  String? tenantId;
  AdditionalFields? additionalFields;
  bool? isDeleted;
  int? rowVersion;
  AuditDetails? auditDetails;
  AuditDetails? clientAuditDetails;
  bool? nonRecoverableError;

  HouseholdMember({
    this.id,
    this.householdId,
    this.clientReferenceId,
    this.householdClientReferenceId,
    this.individualId,
    this.individualClientReferenceId,
    this.isHeadOfHousehold,
    this.tenantId,
    this.additionalFields,
    this.isDeleted = false,
    this.rowVersion,
    this.auditDetails,
    this.nonRecoverableError = false,
    this.clientAuditDetails,
  });

  HouseholdMember.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    householdId = json['householdId'];
    householdClientReferenceId = json['householdClientReferenceId'];
    individualId = json['individualId'];
    individualClientReferenceId = json['individualClientReferenceId'];
    isHeadOfHousehold = json['isHeadOfHousehold'];
    tenantId = json['tenantId'];
    clientReferenceId = json['clientReferenceId'];
    nonRecoverableError = json['nonRecoverableError'];
    additionalFields = json['additionalFields'] != null
        ? AdditionalFields.fromJson(json['additionalFields'])
        : null;
    isDeleted = json['isDeleted'];
    rowVersion = json['rowVersion'];
    auditDetails = json['auditDetails'] != null
        ? AuditDetails.fromJson(json['auditDetails'])
        : null;
    clientAuditDetails = json['clientAuditDetails'] != null
        ? AuditDetails.fromJson(json['clientAuditDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['householdId'] = householdId;
    data['householdClientReferenceId'] = householdClientReferenceId;
    data['individualId'] = individualId;
    data['individualClientReferenceId'] = individualClientReferenceId;
    data['isHeadOfHousehold'] = isHeadOfHousehold;
    data['tenantId'] = tenantId;
    data['clientReferenceId'] = clientReferenceId;
    data['nonRecoverableError'] = nonRecoverableError;
    if (additionalFields != null) {
      data['additionalFields'] = additionalFields!.toJson();
    }
    data['isDeleted'] = isDeleted;
    data['rowVersion'] = rowVersion;
    if (auditDetails != null) {
      data['auditDetails'] = auditDetails!.toJson();
    }
    if (clientAuditDetails != null) {
      data['clientAuditDetails'] = clientAuditDetails!.toJson();
    }
    return data;
  }
}
