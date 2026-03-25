class AuditDetails {
  String? createdBy;
  String? lastModifiedBy;
  int? createdTime;
  int? lastModifiedTime;

  AuditDetails({this.createdBy, this.lastModifiedBy, this.createdTime, this.lastModifiedTime});

  AuditDetails.fromJson(Map<String, dynamic> json) {
    createdBy = json['createdBy'];
    lastModifiedBy = json['lastModifiedBy'];
    createdTime = json['createdTime'];
    lastModifiedTime = json['lastModifiedTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['createdBy'] = createdBy;
    data['lastModifiedBy'] = lastModifiedBy;
    data['createdTime'] = createdTime;
    data['lastModifiedTime'] = lastModifiedTime;
    return data;
  }
}

class ClientAuditDetails {
  String? createdBy;
  String? lastModifiedBy;
  int? createdTime;
  int? lastModifiedTime;

  ClientAuditDetails({this.createdBy, this.lastModifiedBy, this.createdTime, this.lastModifiedTime});

  ClientAuditDetails.fromJson(Map<String, dynamic> json) {
    createdBy = json['createdBy'];
    lastModifiedBy = json['lastModifiedBy'];
    createdTime = json['createdTime'];
    lastModifiedTime = json['lastModifiedTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['createdBy'] = createdBy;
    data['lastModifiedBy'] = lastModifiedBy;
    data['createdTime'] = createdTime;
    data['lastModifiedTime'] = lastModifiedTime;
    return data;
  }
}

class Address {
  String? id;
  String? tenantId;
  String? doorNo;
  double? latitude;
  double? longitude;
  double? locationAccuracy;
  String? type;
  String? addressLine1;
  String? addressLine2;
  String? landmark;
  String? city;
  String? pincode;
  String? buildingName;
  String? street;
  Locality? locality;
  GeoLocation? geoLocation;
  AuditDetails? auditDetails;

  Address({
    this.id,
    this.tenantId,
    this.doorNo,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.type,
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.city,
    this.pincode,
    this.buildingName,
    this.street,
    this.locality,
    this.auditDetails,
    this.geoLocation,
  });

  Address.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tenantId = json['tenantId'];
    doorNo = json['doorNo'];
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    locationAccuracy = json['locationAccuracy']?.toDouble();
    type = json['type'];
    addressLine1 = json['addressLine1'];
    addressLine2 = json['addressLine2'];
    landmark = json['landmark'];
    city = json['city'];
    pincode = json['pincode'];
    buildingName = json['buildingName'];
    street = json['street'];
    locality = json['locality'] != null
        ? Locality.fromJson(json['locality'])
        : null;
    geoLocation = json['geoLocation'] != null
              ? GeoLocation.fromJson(json['geoLocation'])
              : null;
    auditDetails = json['auditDetails'] != null
        ? AuditDetails.fromJson(json['auditDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['tenantId'] = tenantId;
    data['doorNo'] = doorNo;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['locationAccuracy'] = locationAccuracy;
    data['type'] = type;
    data['addressLine1'] = addressLine1;
    data['addressLine2'] = addressLine2;
    data['landmark'] = landmark;
    data['city'] = city;
    data['pincode'] = pincode;
    data['buildingName'] = buildingName;
    data['street'] = street;
    if (locality != null) {
      data['locality'] = locality!.toJson();
    }
    if (geoLocation != null) {
      data['geoLocation'] = geoLocation!.toJson();
    }
    if (auditDetails != null) {
      data['auditDetails'] = auditDetails!.toJson();
    }
    return data;
  }
}

class Locality {
  String? code;
  String? name;
  String? label;
  String? latitude;
  String? longitude;
  String? materializedPath;

  Locality({
    this.code,
    this.name,
    this.label,
    this.latitude,
    this.longitude,
    this.materializedPath,
  });

  Locality.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    label = json['label'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    materializedPath = json['materializedPath'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['code'] = code;
    data['name'] = name;
    data['label'] = label;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['materializedPath'] = materializedPath;
    return data;
  }
}

class GeoLocation {
  double? latitude;
  double? longitude;
  GeoLocation? geoLocation;

  GeoLocation({this.latitude, this.longitude,});

  GeoLocation.fromJson(Map<String, dynamic> json) {
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}


class AdditionalFields {
  String? schema;
  int? version;
  List<AdditionalFieldEntry>? fields;

  AdditionalFields({this.schema, this.version, this.fields});

  AdditionalFields.fromJson(Map<String, dynamic> json) {
    schema = json['schema'];
    version = json['version'];
    if (json['fields'] != null) {
      fields = <AdditionalFieldEntry>[];
      json['fields'].forEach((v) {
        fields!.add(AdditionalFieldEntry.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'version': version,
      'fields': fields?.map((e) => e.toJson()).toList(),
    };
  }
}

class AdditionalFieldEntry {
  String? key;
  String? value;

  AdditionalFieldEntry({this.key, this.value});

  AdditionalFieldEntry.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }
}