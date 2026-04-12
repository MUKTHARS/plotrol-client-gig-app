package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

// IndividualHandler handles individual search requests.
type IndividualHandler struct {
	db *sql.DB
}

// NewIndividualHandler returns a new IndividualHandler.
func NewIndividualHandler(db *sql.DB) *IndividualHandler {
	return &IndividualHandler{db: db}
}

// SearchIndividuals handles POST /individual/v1/_search
// Flutter sends:
//
//	{
//	  "RequestInfo": {...},
//	  "Individual": { "mobileNumber": ["9876543210"] }
//	}
func (h *IndividualHandler) SearchIndividuals(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusOK, map[string]interface{}{"Individual": []interface{}{}})
		return
	}

	// Extract mobileNumber list from body["Individual"]["mobileNumber"]
	mobile := extractFirstMobile(body)
	if mobile == "" {
		writeJSON(w, http.StatusOK, map[string]interface{}{"Individual": []interface{}{}})
		return
	}

	var u User
	err := h.db.QueryRow(`
		SELECT id, uuid, user_name, name, first_name, last_name,
		       mobile_number, email_id, city, state_name, address,
		       suburb, postcode, latitude, longitude, tenant_id, tenant_image
		FROM users
		WHERE mobile_number = $1
		LIMIT 1
	`, mobile).Scan(
		&u.ID, &u.UUID, &u.UserName, &u.Name,
		&u.FirstName, &u.LastName,
		&u.MobileNumber, &u.EmailID,
		&u.City, &u.StateName, &u.Address,
		&u.Suburb, &u.Postcode,
		&u.Latitude, &u.Longitude,
		&u.TenantID, &u.TenantImage,
	)

	if err == sql.ErrNoRows {
		writeJSON(w, http.StatusOK, map[string]interface{}{"Individual": []interface{}{}})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]interface{}{"Individual": []interface{}{}})
		return
	}

	// Look up the individual's clientReferenceId from the individuals table.
	// This UUID is stored in household_members.individual_client_reference_id and
	// is the key used to filter household members for this user.
	//
	// Two paths are tried in one query to handle all record ages:
	//   1. JOIN via created_by = users.uuid  — reliable for all records because
	//      auditDetails.createdBy is always the logged-in user's UUID.
	//   2. Direct mobile_number match        — works when mobile was stored.
	var indClientRefId string
	_ = h.db.QueryRow(`
		SELECT i.client_reference_id
		FROM individuals i
		LEFT JOIN users u ON u.uuid = i.created_by
		WHERE i.client_reference_id != ''
		  AND (i.mobile_number = $1 OR u.mobile_number = $1)
		ORDER BY i.id ASC
		LIMIT 1
	`, mobile).Scan(&indClientRefId)

	log.Printf("[SearchIndividuals] mobile=%s usersId=%d indClientRefId=%q", mobile, u.ID, indClientRefId)

	individual := map[string]interface{}{
		"id":                 fmt.Sprintf("IND-%d", u.ID),
		"individualId":       fmt.Sprintf("IND-%d", u.ID),
		"clientReferenceId":  indClientRefId, // UUID stored during property creation — used to filter household members
		"tenantId":           u.TenantID,
		"userUuid":           u.UUID, // must NOT be null – Flutter filters on this
		"userId":             fmt.Sprintf("%d", u.ID),
		"mobileNumber":       nullStr(u.MobileNumber),
		"email":              nullStr(u.EmailID),
		"isDeleted":          false,
		"isSystemUser":       false,
		"name": map[string]interface{}{
			"givenName":  nullStr(u.FirstName),
			"familyName": nullStr(u.LastName),
		},
		"address": []map[string]interface{}{
			{
				"locality": map[string]interface{}{
					// Default boundary code used for property lookups
					"code": "MZ.ADMIN.WARD1",
					"name": "Ward 1",
				},
				"city":     nullStr(u.City),
				"street":   nullStr(u.Address),
				"suburb":   nullStr(u.Suburb),
				"postcode": nullStr(u.Postcode),
			},
		},
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Individual": []interface{}{individual},
	})
}

// extractFirstMobile pulls the first mobile number from the request body.
func extractFirstMobile(body map[string]interface{}) string {
	ind, ok := body["Individual"].(map[string]interface{})
	if !ok {
		return ""
	}
	mobiles, ok := ind["mobileNumber"].([]interface{})
	if !ok || len(mobiles) == 0 {
		return ""
	}
	if s, ok := mobiles[0].(string); ok {
		return s
	}
	return ""
}
