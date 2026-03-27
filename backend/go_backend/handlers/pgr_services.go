package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	dbpkg "plotrol-backend/db"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// PGRHandler handles service request (order) endpoints.
type PGRHandler struct {
	gdb *gorm.DB
}

func NewPGRHandler(gdb *gorm.DB) *PGRHandler {
	return &PGRHandler{gdb: gdb}
}

// generateServiceRequestId creates a unique ID using UUID to avoid race conditions.
func generateServiceRequestId() string {
	date := time.Now().Format("20060102")
	id := uuid.New().String()[:8]
	return fmt.Sprintf("PGR-%s-%s", date, strings.ToUpper(id))
}

// buildServiceWrapper converts a DB ServiceRequest into the JSON map the Flutter app expects.
func buildServiceWrapper(sr *dbpkg.ServiceRequest) map[string]interface{} {
	var additionalDetail interface{}
	if sr.AdditionalDetail != "" {
		if err := json.Unmarshal([]byte(sr.AdditionalDetail), &additionalDetail); err != nil {
			log.Printf("[pgr] buildServiceWrapper: additionalDetail unmarshal error: %v", err)
		}
	}

	var addressMap interface{}
	if sr.AddressJSON != "" {
		if err := json.Unmarshal([]byte(sr.AddressJSON), &addressMap); err != nil {
			log.Printf("[pgr] buildServiceWrapper: addressJSON unmarshal error: %v", err)
		}
	}

	var userMap interface{}
	if sr.UserJSON != "" {
		if err := json.Unmarshal([]byte(sr.UserJSON), &userMap); err != nil {
			log.Printf("[pgr] buildServiceWrapper: userJSON unmarshal error: %v", err)
		}
	}

	var assignes []interface{}
	if sr.WorkflowAssignes != "" && sr.WorkflowAssignes != "null" {
		if err := json.Unmarshal([]byte(sr.WorkflowAssignes), &assignes); err != nil {
			log.Printf("[pgr] buildServiceWrapper: workflowAssignes unmarshal error: %v", err)
		}
	}
	if assignes == nil {
		assignes = []interface{}{}
	}

	var hrmsAssignes []interface{}
	if sr.WorkflowHrmsAssignes != "" && sr.WorkflowHrmsAssignes != "null" {
		if err := json.Unmarshal([]byte(sr.WorkflowHrmsAssignes), &hrmsAssignes); err != nil {
			log.Printf("[pgr] buildServiceWrapper: workflowHrmsAssignes unmarshal error: %v", err)
		}
	}
	if hrmsAssignes == nil {
		hrmsAssignes = []interface{}{}
	}

	return map[string]interface{}{
		"service": map[string]interface{}{
			"id":                idStr(sr.ID),
			"serviceRequestId":  sr.ServiceRequestId,
			"tenantId":          sr.TenantID,
			"serviceCode":       sr.ServiceCode,
			"description":       sr.Description,
			"applicationStatus": sr.ApplicationStatus,
			"source":            sr.Source,
			"active":            sr.Active,
			"rowVersion":        sr.RowVersion,
			"isDeleted":         false,
			"additionalDetail":  additionalDetail,
			"address":           addressMap,
			"user":              userMap,
			"auditDetails": map[string]interface{}{
				"createdBy":        sr.AuditCreatedBy,
				"createdTime":      sr.AuditCreatedTime,
				"lastModifiedBy":   sr.AuditLastModifiedBy,
				"lastModifiedTime": sr.AuditLastModifiedTime,
			},
		},
		"workflow": map[string]interface{}{
			"action":       sr.WorkflowAction,
			"assignes":     assignes,
			"hrmsAssignes": hrmsAssignes,
			"comments":     sr.WorkflowComments,
		},
	}
}

// readBodyForLogging reads the body and restores it so it can be decoded again.
func readBodyForLogging(r *http.Request) string {
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		return fmt.Sprintf("[read error: %v]", err)
	}
	r.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

	// Truncate to 2000 chars to avoid flooding logs
	s := string(bodyBytes)
	if len(s) > 2000 {
		s = s[:2000] + "...[truncated]"
	}
	return s
}

// POST /pgr-services/v2/request/_create
func (h *PGRHandler) CreateServiceRequest(w http.ResponseWriter, r *http.Request) {
	log.Println("[pgr] === CreateServiceRequest called ===")
	log.Printf("[pgr] Method: %s, URL: %s", r.Method, r.URL.String())

	rawBody := readBodyForLogging(r)
	log.Printf("[pgr] Raw request body: %s", rawBody)

	// Use UseNumber so float values like 0.0 are preserved as "0.0" (not integer 0)
	// when re-marshaled for storage and response, preventing Flutter type cast errors.
	dec := json.NewDecoder(r.Body)
	dec.UseNumber()
	var body map[string]interface{}
	if err := dec.Decode(&body); err != nil {
		log.Printf("[pgr] JSON decode error: %v", err)
		writeJSON(w, http.StatusBadRequest, errResp("Invalid JSON: "+err.Error()))
		return
	}
	log.Printf("[pgr] Parsed body keys: %v", mapKeys(body))

	serviceMap, ok := body["service"].(map[string]interface{})
	if !ok {
		log.Printf("[pgr] ERROR: 'service' field missing or wrong type. body['service'] = %T %v", body["service"], body["service"])
		writeJSON(w, http.StatusBadRequest, errResp("service field missing"))
		return
	}
	log.Printf("[pgr] service keys: %v", mapKeys(serviceMap))

	workflowMap, _ := body["workflow"].(map[string]interface{})
	if workflowMap != nil {
		log.Printf("[pgr] workflow keys: %v", mapKeys(workflowMap))
	} else {
		log.Printf("[pgr] workflow field is nil or missing")
	}

	// Extract audit details
	auditMap, _ := serviceMap["auditDetails"].(map[string]interface{})
	createdBy, createdTime, lastModifiedBy, lastModifiedTime := auditFromMapN(auditMap)
	log.Printf("[pgr] auditDetails: createdBy=%q, createdTime=%d, lastModifiedBy=%q, lastModifiedTime=%d", createdBy, createdTime, lastModifiedBy, lastModifiedTime)
	if createdTime == 0 {
		createdTime = time.Now().UnixMilli()
	}
	if lastModifiedTime == 0 {
		lastModifiedTime = createdTime
	}

	// Serialize nested objects
	additionalDetailJSON := marshalToString(serviceMap["additionalDetail"])
	addressJSON := marshalToString(serviceMap["address"])
	userJSON := marshalToString(serviceMap["user"])
	log.Printf("[pgr] additionalDetail JSON (len=%d): %s", len(additionalDetailJSON), truncate(additionalDetailJSON, 300))
	log.Printf("[pgr] address JSON (len=%d): %s", len(addressJSON), truncate(addressJSON, 300))
	log.Printf("[pgr] user JSON (len=%d): %s", len(userJSON), truncate(userJSON, 200))

	// Extract workflow fields
	workflowAction := "CREATE"
	workflowComments := ""
	workflowAssignes := "[]"
	workflowHrmsAssignes := "[]"
	if workflowMap != nil {
		workflowAction = strVal(workflowMap["action"])
		workflowComments = strVal(workflowMap["comments"])
		if wa := marshalToString(workflowMap["assignes"]); wa != "" {
			workflowAssignes = wa
		}
		if wh := marshalToString(workflowMap["hrmsAssignes"]); wh != "" {
			workflowHrmsAssignes = wh
		}
	}
	log.Printf("[pgr] workflow: action=%q, comments=%q, assignes=%s", workflowAction, workflowComments, workflowAssignes)

	// Extract mobile number from user for per-user filtering on search
	mobileNumber := ""
	if uMap, ok2 := serviceMap["user"].(map[string]interface{}); ok2 {
		mobileNumber = strVal(uMap["mobileNumber"])
	}
	log.Printf("[pgr] mobileNumber: %q", mobileNumber)

	tenantID := strVal(serviceMap["tenantId"])
	serviceCode := strVal(serviceMap["serviceCode"])
	description := strVal(serviceMap["description"])
	source := strVal(serviceMap["source"])
	active := boolVal(serviceMap["active"])
	log.Printf("[pgr] service: tenantId=%q, serviceCode=%q, description=%q, source=%q, active=%v", tenantID, serviceCode, description, source, active)

	srID := generateServiceRequestId()
	log.Printf("[pgr] Generated serviceRequestId: %s", srID)

	sr := &dbpkg.ServiceRequest{
		ServiceRequestId:      srID,
		TenantID:              tenantID,
		ServiceCode:           serviceCode,
		Description:           description,
		ApplicationStatus:     "PENDING_ASSIGNMENT",
		Source:                source,
		Active:                active,
		RowVersion:            1,
		AdditionalDetail:      additionalDetailJSON,
		AddressJSON:           addressJSON,
		UserJSON:              userJSON,
		WorkflowAction:        workflowAction,
		WorkflowAssignes:      workflowAssignes,
		WorkflowHrmsAssignes:  workflowHrmsAssignes,
		WorkflowComments:      workflowComments,
		AuditCreatedBy:        createdBy,
		AuditCreatedTime:      createdTime,
		AuditLastModifiedBy:   lastModifiedBy,
		AuditLastModifiedTime: lastModifiedTime,
		MobileNumber:          mobileNumber,
	}

	log.Printf("[pgr] Attempting DB insert for serviceRequestId: %s", sr.ServiceRequestId)
	if result := h.gdb.Create(sr); result.Error != nil {
		log.Printf("[pgr] DB insert error: %v", result.Error)
		writeJSON(w, http.StatusInternalServerError, errResp("failed to save service request: "+result.Error.Error()))
		return
	}
	log.Printf("[pgr] DB insert success: id=%d, serviceRequestId=%s", sr.ID, sr.ServiceRequestId)

	resp := map[string]interface{}{
		"ServiceWrappers": []interface{}{buildServiceWrapper(sr)},
	}
	log.Printf("[pgr] Returning success response with ServiceWrappers count=1")
	writeJSON(w, http.StatusOK, resp)
}

// POST /pgr-services/v2/request/_search
func (h *PGRHandler) SearchServiceRequests(w http.ResponseWriter, r *http.Request) {
	log.Println("[pgr] === SearchServiceRequests called ===")
	log.Printf("[pgr] URL: %s", r.URL.String())

	q := r.URL.Query()
	tenantId := q.Get("tenantId")
	mobileNumber := q.Get("mobileNumber")
	fromDateStr := q.Get("fromDate")
	toDateStr := q.Get("toDate")
	limitStr := q.Get("limit")
	offsetStr := q.Get("offset")
	log.Printf("[pgr] query params: tenantId=%q, mobileNumber=%q, fromDate=%q, toDate=%q, limit=%q, offset=%q",
		tenantId, mobileNumber, fromDateStr, toDateStr, limitStr, offsetStr)

	limit := 200
	if v, err := strconv.Atoi(limitStr); err == nil && v > 0 {
		limit = v
	}
	offset := 0
	if v, err := strconv.Atoi(offsetStr); err == nil && v >= 0 {
		offset = v
	}

	db := h.gdb.Model(&dbpkg.ServiceRequest{})
	if tenantId != "" {
		db = db.Where("tenant_id = ?", tenantId)
	}
	if mobileNumber != "" {
		// Household user: filter by their mobile number and date range (audit_created_time)
		db = db.Where("mobile_number = ?", mobileNumber)
		if fromDateStr != "" {
			if ms, err := strconv.ParseInt(fromDateStr, 10, 64); err == nil {
				log.Printf("[pgr] household date filter: audit_created_time >= %d", ms)
				db = db.Where("audit_created_time >= ?", ms)
			}
		}
		if toDateStr != "" {
			if ms, err := strconv.ParseInt(toDateStr, 10, 64); err == nil {
				log.Printf("[pgr] household date filter: audit_created_time <= %d", ms)
				db = db.Where("audit_created_time <= ?", ms)
			}
		}
	} else {
		// Admin / gig worker: return tasks created in the date range OR all ASSIGNED tasks.
		// This ensures:
		//   - Admin sees today's newly created tasks in their dashboard (filtered locally by createdTime)
		//   - Gig workers see tasks assigned to them even if the assignment happened on a previous day
		fromMs := int64(0)
		toMs := int64(0)
		if fromDateStr != "" {
			if ms, err := strconv.ParseInt(fromDateStr, 10, 64); err == nil {
				fromMs = ms
			}
		}
		if toDateStr != "" {
			if ms, err := strconv.ParseInt(toDateStr, 10, 64); err == nil {
				toMs = ms
			}
		}
		if fromMs > 0 && toMs > 0 {
			// Two-way OR:
			//  1. Tasks CREATED within the date range → covers all statuses including RESOLVED
			//  2. All ASSIGNED tasks regardless of age → gig worker always sees their workload
			// Using audit_created_time for RESOLVED ensures tasks created in the selected
			// period always appear on the completed tab, regardless of when they were resolved.
			log.Printf("[pgr] admin/gig filter: created[%d-%d] OR ASSIGNED", fromMs, toMs)
			db = db.Where(
				"(audit_created_time >= ? AND audit_created_time <= ?) OR application_status = ?",
				fromMs, toMs,
				"ASSIGNED",
			)
		} else if fromMs > 0 {
			log.Printf("[pgr] admin/gig filter: created >= %d OR ASSIGNED", fromMs)
			db = db.Where(
				"(audit_created_time >= ?) OR application_status = ?",
				fromMs,
				"ASSIGNED",
			)
		}
	}

	var records []dbpkg.ServiceRequest
	if result := db.Order("created_at DESC").Limit(limit).Offset(offset).Find(&records); result.Error != nil {
		log.Printf("[pgr] SearchServiceRequests DB error: %v", result.Error)
		writeJSON(w, http.StatusInternalServerError, errResp("failed to query service requests: "+result.Error.Error()))
		return
	}
	log.Printf("[pgr] SearchServiceRequests found %d records (mobileNumber=%q, fromDate=%q, toDate=%q)",
		len(records), mobileNumber, fromDateStr, toDateStr)

	wrappers := make([]interface{}, 0, len(records))
	for i := range records {
		wrappers = append(wrappers, buildServiceWrapper(&records[i]))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ServiceWrappers": wrappers,
	})
}

// POST /pgr-services/v2/request/_update
func (h *PGRHandler) UpdateServiceRequest(w http.ResponseWriter, r *http.Request) {
	log.Println("[pgr] === UpdateServiceRequest called ===")
	log.Printf("[pgr] URL: %s", r.URL.String())

	rawBody := readBodyForLogging(r)
	log.Printf("[pgr] Raw request body: %s", rawBody)

	decU := json.NewDecoder(r.Body)
	decU.UseNumber()
	var body map[string]interface{}
	if err := decU.Decode(&body); err != nil {
		log.Printf("[pgr] JSON decode error: %v", err)
		writeJSON(w, http.StatusBadRequest, errResp("Invalid JSON: "+err.Error()))
		return
	}

	serviceMap, ok := body["service"].(map[string]interface{})
	if !ok {
		log.Printf("[pgr] ERROR: 'service' field missing")
		writeJSON(w, http.StatusBadRequest, errResp("service field missing"))
		return
	}

	workflowMap, _ := body["workflow"].(map[string]interface{})

	// Find existing record
	serviceRequestId := strVal(serviceMap["serviceRequestId"])
	recordId := strVal(serviceMap["id"])
	log.Printf("[pgr] Looking up serviceRequestId=%q, id=%q", serviceRequestId, recordId)

	var sr dbpkg.ServiceRequest
	result := h.gdb.Where("service_request_id = ?", serviceRequestId).First(&sr)
	if result.Error != nil && recordId != "" {
		result = h.gdb.Where("id = ?", recordId).First(&sr)
	}
	if result.Error != nil {
		log.Printf("[pgr] Record not found: %v", result.Error)
		writeJSON(w, http.StatusNotFound, errResp("service request not found"))
		return
	}
	log.Printf("[pgr] Found record id=%d, currentStatus=%s", sr.ID, sr.ApplicationStatus)

	// Update audit
	auditMap, _ := serviceMap["auditDetails"].(map[string]interface{})
	_, _, lastModifiedBy, lastModifiedTime := auditFromMapN(auditMap)
	if lastModifiedTime == 0 {
		lastModifiedTime = time.Now().UnixMilli()
	}
	if lastModifiedBy != "" {
		sr.AuditLastModifiedBy = lastModifiedBy
	}
	sr.AuditLastModifiedTime = lastModifiedTime
	sr.RowVersion++

	// Update application status if provided
	if status := strVal(serviceMap["applicationStatus"]); status != "" {
		log.Printf("[pgr] Updating applicationStatus: %s -> %s", sr.ApplicationStatus, status)
		sr.ApplicationStatus = status
	}

	// Update additionalDetail if provided
	if serviceMap["additionalDetail"] != nil {
		sr.AdditionalDetail = marshalToString(serviceMap["additionalDetail"])
	}

	// Apply workflow action
	if workflowMap != nil {
		action := strings.ToUpper(strVal(workflowMap["action"]))
		sr.WorkflowAction = action
		log.Printf("[pgr] workflow action: %s", action)

		switch action {
		case "ASSIGN":
			if assignes := workflowMap["assignes"]; assignes != nil {
				sr.WorkflowAssignes = marshalToString(assignes)
			}
			if hrms := workflowMap["hrmsAssignes"]; hrms != nil {
				sr.WorkflowHrmsAssignes = marshalToString(hrms)
			}
			// Mark as ASSIGNED so the gig worker's search (which ORs on application_status=ASSIGNED)
			// always returns this task regardless of the date range filter.
			sr.ApplicationStatus = "ASSIGNED"
			log.Printf("[pgr] ASSIGN: assignes=%s, setting applicationStatus=ASSIGNED", sr.WorkflowAssignes)
		case "RESOLVE":
			sr.ApplicationStatus = "RESOLVED"
			log.Printf("[pgr] RESOLVE: setting status to RESOLVED")
		}

		if c := strVal(workflowMap["comments"]); c != "" {
			sr.WorkflowComments = c
		}
	}

	if res := h.gdb.Save(&sr); res.Error != nil {
		log.Printf("[pgr] UpdateServiceRequest DB error: %v", res.Error)
		writeJSON(w, http.StatusInternalServerError, errResp("failed to update service request: "+res.Error.Error()))
		return
	}
	log.Printf("[pgr] UpdateServiceRequest success: id=%d, newStatus=%s", sr.ID, sr.ApplicationStatus)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ServiceWrappers": []interface{}{buildServiceWrapper(&sr)},
	})
}

// int64Any extracts an int64 from a json.Number, float64, or int value.
// Required because UseNumber() makes the decoder return json.Number instead of float64.
func int64Any(v interface{}) int64 {
	switch n := v.(type) {
	case json.Number:
		if i, err := n.Int64(); err == nil {
			return i
		}
		if f, err := n.Float64(); err == nil {
			return int64(f)
		}
	case float64:
		return int64(n)
	case int64:
		return n
	case int:
		return int64(n)
	}
	return 0
}

// auditFromMapN is like auditFromMap but works with json.Number values produced by UseNumber().
func auditFromMapN(m map[string]interface{}) (createdBy string, createdTime int64, lastModifiedBy string, lastModifiedTime int64) {
	if m == nil {
		return
	}
	createdBy = strVal(m["createdBy"])
	lastModifiedBy = strVal(m["lastModifiedBy"])
	createdTime = int64Any(m["createdTime"])
	lastModifiedTime = int64Any(m["lastModifiedTime"])
	return
}

// marshalToString converts any value to its JSON string representation.
func marshalToString(v interface{}) string {
	if v == nil {
		return ""
	}
	b, err := json.Marshal(v)
	if err != nil {
		log.Printf("[pgr] marshalToString error: %v", err)
		return ""
	}
	return string(b)
}

func mapKeys(m map[string]interface{}) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}
