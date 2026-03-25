package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	dbpkg "plotrol-backend/db"

	"gorm.io/gorm"
)

// idStr converts a uint primary key to the string form Flutter expects.
func idStr(id uint) string { return fmt.Sprintf("%d", id) }

func jsonDecode(r *http.Request, dst interface{}) error {
	return json.NewDecoder(r.Body).Decode(dst)
}

// PropertyHandler handles Individual, Household, and HouseholdMember endpoints.
type PropertyHandler struct {
	gdb *gorm.DB
}

func NewPropertyHandler(gdb *gorm.DB) *PropertyHandler {
	return &PropertyHandler{gdb: gdb}
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func auditFromMap(m map[string]interface{}) (createdBy string, createdTime int64, lastModifiedBy string, lastModifiedTime int64) {
	if m == nil {
		return
	}
	createdBy = strVal(m["createdBy"])
	lastModifiedBy = strVal(m["lastModifiedBy"])
	if v, ok := m["createdTime"].(float64); ok {
		createdTime = int64(v)
	}
	if v, ok := m["lastModifiedTime"].(float64); ok {
		lastModifiedTime = int64(v)
	}
	return
}

func intVal(v interface{}) int {
	if f, ok := v.(float64); ok {
		return int(f)
	}
	return 0
}

func floatVal(v interface{}) float64 {
	if f, ok := v.(float64); ok {
		return f
	}
	return 0
}

func boolVal(v interface{}) bool {
	if b, ok := v.(bool); ok {
		return b
	}
	return false
}

func nowMillis() int64 { return time.Now().UnixMilli() }

// buildAuditResp builds a standard auditDetails map for responses.
func buildAuditResp(createdBy string, createdTime int64, lastModifiedBy string, lastModifiedTime int64) map[string]interface{} {
	return map[string]interface{}{
		"createdBy":        createdBy,
		"createdTime":      createdTime,
		"lastModifiedBy":   lastModifiedBy,
		"lastModifiedTime": lastModifiedTime,
	}
}

// ─── POST /individual/v1/_create ──────────────────────────────────────────────

func (h *PropertyHandler) CreateIndividual(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if !decodeJSON(w, r, &body) {
		return
	}

	indMap, ok := body["Individual"].(map[string]interface{})
	if !ok {
		writeJSON(w, http.StatusBadRequest, errResp("Individual field missing"))
		return
	}

	clientRefId := strVal(indMap["clientReferenceId"])

	nameMap, _ := indMap["name"].(map[string]interface{})
	givenName, familyName := "", ""
	if nameMap != nil {
		givenName = strVal(nameMap["givenName"])
		familyName = strVal(nameMap["familyName"])
	}

	auditMap, _ := indMap["auditDetails"].(map[string]interface{})
	cb, ct, lmb, lmt := auditFromMap(auditMap)

	rowVersion := 1
	if rv := intVal(indMap["rowVersion"]); rv > 0 {
		rowVersion = rv
	}

	rec := dbpkg.Individual{
		ClientReferenceId:   clientRefId,
		TenantID:            strVal(indMap["tenantId"]),
		GivenName:           givenName,
		FamilyName:          familyName,
		MobileNumber:        strVal(indMap["mobileNumber"]),
		Email:               strVal(indMap["email"]),
		UserUUID:            strVal(indMap["userUuid"]),
		IsDeleted:           false,
		IsSystemUser:        boolVal(indMap["isSystemUser"]),
		NonRecoverableError: false,
		RowVersion:          rowVersion,
		CreatedBy:           cb,
		CreatedTime:         ct,
		LastModifiedBy:      lmb,
		LastModifiedTime:    lmt,
	}

	if err := h.gdb.Create(&rec).Error; err != nil {
		writeJSON(w, http.StatusInternalServerError, errResp("Failed to create individual: "+err.Error()))
		return
	}

	// Save addresses
	if addrsRaw, ok := indMap["address"].([]interface{}); ok {
		for _, ar := range addrsRaw {
			if am, ok := ar.(map[string]interface{}); ok {
				loc, _ := am["locality"].(map[string]interface{})
				aAudit, _ := am["auditDetails"].(map[string]interface{})
				acb, act, _, _ := auditFromMap(aAudit)
				addr := dbpkg.IndividualAddress{
					IndividualID: rec.ID,
					TenantID:     strVal(am["tenantId"]),
					Type:         strVal(am["type"]),
					AddressLine1: strVal(am["addressLine1"]),
					AddressLine2: strVal(am["addressLine2"]),
					Landmark:     strVal(am["landmark"]),
					City:         strVal(am["city"]),
					Pincode:      strVal(am["pincode"]),
					BuildingName: strVal(am["buildingName"]),
					Street:       strVal(am["street"]),
					Latitude:     floatVal(am["latitude"]),
					Longitude:    floatVal(am["longitude"]),
					CreatedBy:    acb,
					CreatedTime:  act,
				}
				if loc != nil {
					addr.LocalityCode = strVal(loc["code"])
					addr.LocalityName = strVal(loc["name"])
				}
				h.gdb.Create(&addr)
			}
		}
	}

	// Save identifiers
	if idsRaw, ok := indMap["identifiers"].([]interface{}); ok {
		for _, ir := range idsRaw {
			if im, ok := ir.(map[string]interface{}); ok {
				h.gdb.Create(&dbpkg.IndividualIdentifier{
					IndividualID:      rec.ID,
					ClientReferenceId: strVal(im["clientReferenceId"]),
					IdentifierType:    strVal(im["identifierType"]),
					IdentifierId:      strVal(im["identifierId"]),
				})
			}
		}
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Individual": buildIndividualMap(rec, indMap),
	})
}

func buildIndividualMap(rec dbpkg.Individual, src map[string]interface{}) map[string]interface{} {
	resp := map[string]interface{}{
		"id":                  idStr(rec.ID),
		"individualId":        rec.ClientReferenceId,
		"clientReferenceId":   rec.ClientReferenceId,
		"tenantId":            rec.TenantID,
		"rowVersion":          rec.RowVersion,
		"isDeleted":           rec.IsDeleted,
		"isSystemUser":        rec.IsSystemUser,
		"nonRecoverableError": rec.NonRecoverableError,
		"mobileNumber":        rec.MobileNumber,
		"email":               rec.Email,
		"userUuid":            rec.UserUUID,
		"name": map[string]interface{}{
			"givenName":  rec.GivenName,
			"familyName": rec.FamilyName,
		},
		"auditDetails": buildAuditResp(rec.CreatedBy, rec.CreatedTime, rec.LastModifiedBy, rec.LastModifiedTime),
		"skills":       []interface{}{},
		"identifiers":  src["identifiers"],
		"address":      src["address"],
		"photo":        src["photo"],
	}
	return resp
}


// ─── POST /household/v1/_create ───────────────────────────────────────────────

func (h *PropertyHandler) CreateHousehold(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if !decodeJSON(w, r, &body) {
		return
	}

	hMap, ok := body["Household"].(map[string]interface{})
	if !ok {
		writeJSON(w, http.StatusBadRequest, errResp("Household field missing"))
		return
	}

	clientRefId := strVal(hMap["clientReferenceId"])

	addrMap, _ := hMap["address"].(map[string]interface{})
	loc, _ := func() (map[string]interface{}, bool) {
		if addrMap == nil {
			return nil, false
		}
		l, ok := addrMap["locality"].(map[string]interface{})
		return l, ok
	}()

	auditMap, _ := hMap["auditDetails"].(map[string]interface{})
	cb, ct, lmb, lmt := auditFromMap(auditMap)

	rowVersion := 1
	if rv := intVal(hMap["rowVersion"]); rv > 0 {
		rowVersion = rv
	}
	memberCount := 1
	if mc := intVal(hMap["memberCount"]); mc > 0 {
		memberCount = mc
	}

	rec := dbpkg.Household{
		ClientReferenceId:   clientRefId,
		TenantID:            strVal(hMap["tenantId"]),
		HouseholdType:       strVal(hMap["householdType"]),
		MemberCount:         memberCount,
		IsDeleted:           false,
		NonRecoverableError: false,
		RowVersion:          rowVersion,
		CreatedBy:           cb,
		CreatedTime:         ct,
		LastModifiedBy:      lmb,
		LastModifiedTime:    lmt,
	}

	if addrMap != nil {
		rec.AddrTenantID = strVal(addrMap["tenantId"])
		rec.AddrType = strVal(addrMap["type"])
		rec.AddrAddressLine1 = strVal(addrMap["addressLine1"])
		rec.AddrAddressLine2 = strVal(addrMap["addressLine2"])
		rec.AddrLandmark = strVal(addrMap["landmark"])
		rec.AddrCity = strVal(addrMap["city"])
		rec.AddrPincode = strVal(addrMap["pincode"])
		rec.AddrBuildingName = strVal(addrMap["buildingName"])
		rec.AddrStreet = strVal(addrMap["street"])
		rec.AddrLatitude = floatVal(addrMap["latitude"])
		rec.AddrLongitude = floatVal(addrMap["longitude"])
		if loc != nil {
			rec.AddrLocalityCode = strVal(loc["code"])
			rec.AddrLocalityName = strVal(loc["name"])
		}
	}

	if err := h.gdb.Create(&rec).Error; err != nil {
		writeJSON(w, http.StatusInternalServerError, errResp("Failed to create household: "+err.Error()))
		return
	}

	// Save additional fields
	if af, ok := hMap["additionalFields"].(map[string]interface{}); ok {
		if fields, ok := af["fields"].([]interface{}); ok {
			for _, f := range fields {
				if fm, ok := f.(map[string]interface{}); ok {
					h.gdb.Create(&dbpkg.HouseholdAdditionalField{
						HouseholdID: rec.ID,
						Key:         strVal(fm["key"]),
						Value:       strVal(fm["value"]),
					})
				}
			}
		}
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Household": buildHouseholdMap(rec, hMap),
	})
}

func buildHouseholdMap(rec dbpkg.Household, src map[string]interface{}) map[string]interface{} {
	return map[string]interface{}{
		"id":                  idStr(rec.ID),
		"clientReferenceId":   rec.ClientReferenceId,
		"tenantId":            rec.TenantID,
		"householdType":       rec.HouseholdType,
		"memberCount":         rec.MemberCount,
		"rowVersion":          rec.RowVersion,
		"isDeleted":           rec.IsDeleted,
		"nonRecoverableError": rec.NonRecoverableError,
		"auditDetails":        buildAuditResp(rec.CreatedBy, rec.CreatedTime, rec.LastModifiedBy, rec.LastModifiedTime),
		"clientAuditDetails":  buildAuditResp(rec.CreatedBy, rec.CreatedTime, rec.LastModifiedBy, rec.LastModifiedTime),
		"address":             src["address"],
		"additionalFields":    src["additionalFields"],
	}
}

// ─── POST /household/v1/_search ───────────────────────────────────────────────

func (h *PropertyHandler) SearchHouseholds(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if !decodeJSON(w, r, &body) {
		return
	}

	filter, _ := body["Household"].(map[string]interface{})

	query := h.gdb.Model(&dbpkg.Household{}).Where("is_deleted = false")

	if filter != nil {
		if tenantID := strVal(filter["tenantId"]); tenantID != "" {
			query = query.Where("tenant_id = ?", tenantID)
		}
		if refs, ok := filter["clientReferenceId"].([]interface{}); ok && len(refs) > 0 {
			ids := make([]string, 0, len(refs))
			for _, r := range refs {
				if s := strVal(r); s != "" {
					ids = append(ids, s)
				}
			}
			if len(ids) > 0 {
				query = query.Where("client_reference_id IN ?", ids)
			}
		}
	}

	var records []dbpkg.Household
	if err := query.Find(&records).Error; err != nil {
		writeJSON(w, http.StatusInternalServerError, errResp("DB error: "+err.Error()))
		return
	}

	list := make([]map[string]interface{}, 0, len(records))
	for _, rec := range records {
		// Load additional fields
		var fields []dbpkg.HouseholdAdditionalField
		h.gdb.Where("household_id = ?", rec.ID).Find(&fields)

		af := map[string]interface{}{
			"schema":  "Household",
			"version": 1,
			"fields":  buildAdditionalFields(fields),
		}

		m := buildHouseholdMap(rec, nil)
		m["additionalFields"] = af
		m["address"] = buildHouseholdAddress(rec)
		list = append(list, m)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"Households": list})
}

func buildAdditionalFields(fields []dbpkg.HouseholdAdditionalField) []map[string]interface{} {
	out := make([]map[string]interface{}, 0, len(fields))
	for _, f := range fields {
		out = append(out, map[string]interface{}{"key": f.Key, "value": f.Value})
	}
	return out
}

func buildHouseholdAddress(rec dbpkg.Household) map[string]interface{} {
	return map[string]interface{}{
		"tenantId":     rec.AddrTenantID,
		"type":         rec.AddrType,
		"addressLine1": rec.AddrAddressLine1,
		"addressLine2": rec.AddrAddressLine2,
		"landmark":     rec.AddrLandmark,
		"city":         rec.AddrCity,
		"pincode":      rec.AddrPincode,
		"buildingName": rec.AddrBuildingName,
		"street":       rec.AddrStreet,
		"latitude":     rec.AddrLatitude,
		"longitude":    rec.AddrLongitude,
		"locality": map[string]interface{}{
			"code": rec.AddrLocalityCode,
			"name": rec.AddrLocalityName,
		},
	}
}

// ─── POST /household/member/v1/_create ───────────────────────────────────────

func (h *PropertyHandler) CreateHouseholdMember(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if !decodeJSON(w, r, &body) {
		return
	}

	mMap, ok := body["HouseholdMember"].(map[string]interface{})
	if !ok {
		writeJSON(w, http.StatusBadRequest, errResp("HouseholdMember field missing"))
		return
	}

	clientRefId := strVal(mMap["clientReferenceId"])
	hcRefId := strVal(mMap["householdClientReferenceId"])
	icRefId := strVal(mMap["individualClientReferenceId"])

	auditMap, _ := mMap["auditDetails"].(map[string]interface{})
	cb, ct, lmb, lmt := auditFromMap(auditMap)

	rowVersion := 1
	if rv := intVal(mMap["rowVersion"]); rv > 0 {
		rowVersion = rv
	}

	// Look up parent IDs
	var householdID, individualID uint
	var hhRec dbpkg.Household
	if err := h.gdb.Where("client_reference_id = ?", hcRefId).First(&hhRec).Error; err == nil {
		householdID = hhRec.ID
	}
	var indRec dbpkg.Individual
	if err := h.gdb.Where("client_reference_id = ?", icRefId).First(&indRec).Error; err == nil {
		individualID = indRec.ID
	}

	rec := dbpkg.HouseholdMember{
		ClientReferenceId:           clientRefId,
		HouseholdID:                 householdID,
		HouseholdClientReferenceId:  hcRefId,
		IndividualID:                individualID,
		IndividualClientReferenceId: icRefId,
		IsHeadOfHousehold:           boolVal(mMap["isHeadOfHousehold"]),
		TenantID:                    strVal(mMap["tenantId"]),
		IsDeleted:                   false,
		NonRecoverableError:         false,
		RowVersion:                  rowVersion,
		CreatedBy:                   cb,
		CreatedTime:                 ct,
		LastModifiedBy:              lmb,
		LastModifiedTime:            lmt,
	}

	if err := h.gdb.Create(&rec).Error; err != nil {
		writeJSON(w, http.StatusInternalServerError, errResp("Failed to create household member: "+err.Error()))
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"HouseholdMember": map[string]interface{}{
			"id":                          idStr(rec.ID),
			"clientReferenceId":           rec.ClientReferenceId,
			"householdId":                 idStr(rec.HouseholdID),
			"householdClientReferenceId":  rec.HouseholdClientReferenceId,
			"individualId":                idStr(rec.IndividualID),
			"individualClientReferenceId": rec.IndividualClientReferenceId,
			"isHeadOfHousehold":           rec.IsHeadOfHousehold,
			"tenantId":                    rec.TenantID,
			"isDeleted":                   rec.IsDeleted,
			"nonRecoverableError":         rec.NonRecoverableError,
			"rowVersion":                  rec.RowVersion,
			"auditDetails":                buildAuditResp(rec.CreatedBy, rec.CreatedTime, rec.LastModifiedBy, rec.LastModifiedTime),
			"clientAuditDetails":          buildAuditResp(rec.CreatedBy, rec.CreatedTime, rec.LastModifiedBy, rec.LastModifiedTime),
		},
	})
}

// ─── POST /household/member/v1/_search ───────────────────────────────────────

func (h *PropertyHandler) SearchHouseholdMembers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if !decodeJSON(w, r, &body) {
		return
	}

	filter, _ := body["HouseholdMember"].(map[string]interface{})

	query := h.gdb.Model(&dbpkg.HouseholdMember{}).Where("is_deleted = false")

	if filter != nil {
		if tenantID := strVal(filter["tenantId"]); tenantID != "" {
			query = query.Where("tenant_id = ?", tenantID)
		}
		if hcRefId := strVal(filter["householdClientReferenceId"]); hcRefId != "" {
			query = query.Where("household_client_reference_id = ?", hcRefId)
		}
		if icRefId := strVal(filter["individualClientReferenceId"]); icRefId != "" {
			query = query.Where("individual_client_reference_id = ?", icRefId)
		}
	}

	var records []dbpkg.HouseholdMember
	if err := query.Find(&records).Error; err != nil {
		writeJSON(w, http.StatusInternalServerError, errResp("DB error: "+err.Error()))
		return
	}

	list := make([]map[string]interface{}, 0, len(records))
	for _, rec := range records {
		list = append(list, map[string]interface{}{
			"id":                          idStr(rec.ID),
			"clientReferenceId":           rec.ClientReferenceId,
			"householdId":                 idStr(rec.HouseholdID),
			"householdClientReferenceId":  rec.HouseholdClientReferenceId,
			"individualId":                idStr(rec.IndividualID),
			"individualClientReferenceId": rec.IndividualClientReferenceId,
			"isHeadOfHousehold":           rec.IsHeadOfHousehold,
			"tenantId":                    rec.TenantID,
			"isDeleted":                   rec.IsDeleted,
			"nonRecoverableError":         rec.NonRecoverableError,
			"rowVersion":                  rec.RowVersion,
			"auditDetails":                buildAuditResp(rec.CreatedBy, rec.CreatedTime, rec.LastModifiedBy, rec.LastModifiedTime),
		})
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"HouseholdMembers": list})
}

// ─── shared decode helper ─────────────────────────────────────────────────────

func decodeJSON(w http.ResponseWriter, r *http.Request, dst interface{}) bool {
	if err := jsonDecode(r, dst); err != nil {
		writeJSON(w, http.StatusBadRequest, errResp("Invalid JSON: "+err.Error()))
		return false
	}
	return true
}

func errResp(msg string) map[string]interface{} {
	return map[string]interface{}{
		"Errors": []map[string]interface{}{{"code": "SERVER_ERROR", "message": msg}},
	}
}
