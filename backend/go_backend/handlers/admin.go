package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"plotrol-backend/config"
	dbpkg "plotrol-backend/db"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// ─── AdminHandler ─────────────────────────────────────────────────────────────

// AdminHandler handles admin-specific routes: employee management, user search,
// admin user creation, and gig-worker management.
type AdminHandler struct {
	gdb *gorm.DB
	db  *sql.DB
	cfg *config.Config
}

// NewAdminHandler returns a new AdminHandler.
func NewAdminHandler(gdb *gorm.DB, db *sql.DB, cfg *config.Config) *AdminHandler {
	return &AdminHandler{gdb: gdb, db: db, cfg: cfg}
}

// ─── helpers ──────────────────────────────────────────────────────────────────

// buildEmployeeFromUser converts a DB User record to the Employees[] map Flutter expects.
//
// Flutter filters the list with two hard requirements:
//   1. assignments must have at least one entry where department == "eGov"
//      and designation != null  (hasValidAssignment check)
//   2. user.userServiceUuid != null && user.uuid != null  (hasValidUser check)
//
// We satisfy both by injecting a synthetic assignment and including userServiceUuid.
func buildEmployeeFromUser(u dbpkg.User) map[string]interface{} {
	mobile := ""
	if u.MobileNumber != nil {
		mobile = *u.MobileNumber
	}
	emailVal := ""
	if u.EmailID != nil {
		emailVal = *u.EmailID
	}
	nameVal := ""
	if u.Name != nil {
		nameVal = *u.Name
	}

	// Synthetic assignment satisfying Flutter's filter:
	//   assignment.department == "eGov" && assignment.designation != null
	syntheticAssignment := map[string]interface{}{
		"id":                  u.UUID + "-assign",
		"position":            1,
		"designation":         "Field Officer",
		"department":          "eGov",
		"fromDate":            u.CreatedAt.UnixMilli(),
		"toDate":              nil,
		"govtOrderNumber":     nil,
		"tenantid":            u.TenantID,
		"reportingTo":         nil,
		"isHOD":               false,
		"isCurrentAssignment": true,
		"auditDetails":        nil,
	}

	return map[string]interface{}{
		"id":                  u.ID,
		"uuid":                u.UUID,
		"code":                mobile,
		"employeeStatus":      "EMPLOYED",
		"employeeType":        "PERMANENT",
		"tenantId":            u.TenantID,
		"isActive":            u.Active,
		"reActivateEmployee":  false,
		"jurisdictions":       []interface{}{},
		"assignments":         []interface{}{syntheticAssignment},
		"serviceHistory":      []interface{}{},
		"education":           []interface{}{},
		"tests":               []interface{}{},
		"documents":           []interface{}{},
		"deactivationDetails": []interface{}{},
		"reactivationDetails": []interface{}{},
		"user": map[string]interface{}{
			"id":              u.ID,
			"uuid":            u.UUID,
			"userServiceUuid": u.UUID, // Flutter checks: employee.user?.userServiceUuid != null
			"userName":        u.UserName,
			"name":            nameVal,
			"mobileNumber":    mobile,
			"emailId":         emailVal,
			"tenantId":        u.TenantID,
			"type":            u.Type,
			"active":          u.Active,
			"roles": []map[string]interface{}{
				{
					"name":     u.RoleName,
					"code":     u.RoleCode,
					"tenantId": u.TenantID,
				},
			},
		},
	}
}

// buildUserFromDB converts a DB User record to the UserRequest map the Flutter UserSearchResponse expects.
func buildUserFromDB(u dbpkg.User) map[string]interface{} {
	mobile := ""
	if u.MobileNumber != nil {
		mobile = *u.MobileNumber
	}
	emailVal := ""
	if u.EmailID != nil {
		emailVal = *u.EmailID
	}
	nameVal := ""
	if u.Name != nil {
		nameVal = *u.Name
	}
	cityVal := ""
	if u.City != nil {
		cityVal = *u.City
	}
	addrVal := ""
	if u.Address != nil {
		addrVal = *u.Address
	}
	postcodeVal := ""
	if u.Postcode != nil {
		postcodeVal = *u.Postcode
	}
	imageVal := ""
	if u.TenantImage != nil {
		imageVal = *u.TenantImage
	}

	return map[string]interface{}{
		"id":               u.ID,
		"uuid":             u.UUID,
		"userServiceUuid":  u.UUID,
		"userName":         u.UserName,
		"name":             nameVal,
		"mobileNumber":     mobile,
		"emailId":          emailVal,
		"type":             u.Type,
		"tenantId":         u.TenantID,
		"active":           u.Active,
		"permanentAddress": addrVal,
		"permanentCity":    cityVal,
		"permanentPinCode": postcodeVal,
		"photo":            imageVal,
		"roles": []map[string]interface{}{
			{
				"name":     u.RoleName,
				"code":     u.RoleCode,
				"tenantId": u.TenantID,
			},
		},
	}
}

// ─── SearchEmployees ──────────────────────────────────────────────────────────

// SearchEmployees handles POST /egov-hrms/employees/_search
//
// Called by the Flutter admin panel (GetAssigneesProvider) to list gig workers
// so the admin can pick one to assign an order to.
//
// Query params: tenantId, role (optional, defaults to HELPDESK_USER), active
// Body: { "RequestInfo": {...} }  (ignored for filtering; kept for compatibility)
// Response: { "Employees": [...] }
func (h *AdminHandler) SearchEmployees(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === SearchEmployees called ===")
	log.Printf("[admin] Method: %s, URL: %s", r.Method, r.URL.String())

	q := r.URL.Query()
	tenantID := q.Get("tenantId")
	// Flutter sends "roles" (not "role") — handle both for safety
	roleFilter := q.Get("roles")
	if roleFilter == "" {
		roleFilter = q.Get("role")
	}
	mobileFilter := q.Get("mobileNumber")
	nameFilter := q.Get("name")
	uuidFilter := q.Get("uuid")
	codesFilter := q.Get("codes") // Flutter also sends "codes" param sometimes

	log.Printf("[admin] SearchEmployees filters: tenantId=%q, roles=%q, codes=%q, mobile=%q, name=%q, uuid=%q",
		tenantID, roleFilter, codesFilter, mobileFilter, nameFilter, uuidFilter)
	log.Printf("[admin] SearchEmployees full query string: %s", r.URL.RawQuery)

	gormQ := h.gdb.Model(&dbpkg.User{})

	if tenantID != "" {
		gormQ = gormQ.Where("tenant_id = ?", tenantID)
	}
	if roleFilter != "" {
		log.Printf("[admin] SearchEmployees: filtering by role_code = %q", roleFilter)
		gormQ = gormQ.Where("role_code = ?", roleFilter)
	} else {
		// No role filter sent — default to HELPDESK_USER (gig workers)
		log.Printf("[admin] SearchEmployees: no role param, defaulting to HELPDESK_USER")
		gormQ = gormQ.Where("role_code = ?", "HELPDESK_USER")
	}
	if mobileFilter != "" {
		gormQ = gormQ.Where("mobile_number = ?", mobileFilter)
	}
	if nameFilter != "" {
		gormQ = gormQ.Where("name ILIKE ?", "%"+nameFilter+"%")
	}
	if uuidFilter != "" {
		gormQ = gormQ.Where("uuid = ?", uuidFilter)
	}

	var users []dbpkg.User
	if result := gormQ.Order("created_at DESC").Find(&users); result.Error != nil {
		log.Printf("[admin] SearchEmployees DB error: %v", result.Error)
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "DB_ERROR", "message": "Database error: " + result.Error.Error()},
			},
		})
		return
	}

	log.Printf("[admin] SearchEmployees found %d employees", len(users))

	employees := make([]map[string]interface{}, 0, len(users))
	for _, u := range users {
		employees = append(employees, buildEmployeeFromUser(u))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Employees": employees,
		"ResponseInfo": map[string]interface{}{
			"status": fmt.Sprintf("%d", http.StatusOK),
		},
	})
}

// ─── UserSearch ───────────────────────────────────────────────────────────────

// UserSearch handles POST /user/_search
//
// Called by HomeScreenController.getTenantApiFunction() to retrieve the current
// user's full profile (name, email, city, pincode, photo, etc.).
//
// Body: { "RequestInfo": {...}, "tenantId": "mz", "uuid": ["<uuid>"] }
// Query params: tenantId
// Response: { "user": [...] }
func (h *AdminHandler) UserSearch(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === UserSearch called ===")
	log.Printf("[admin] Method: %s, URL: %s", r.Method, r.URL.String())

	rawBody := readBodyForLogging(r)
	log.Printf("[admin] UserSearch raw body: %s", rawBody)

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		log.Printf("[admin] UserSearch JSON decode error: %v", err)
		writeJSON(w, http.StatusBadRequest, errResp("Invalid JSON: "+err.Error()))
		return
	}

	q := r.URL.Query()
	tenantID := q.Get("tenantId")
	if tenantID == "" {
		if v, ok := body["tenantId"].(string); ok {
			tenantID = v
		}
	}

	// Extract uuid list from body: "uuid": ["<uuid1>", "<uuid2>"]
	var uuids []string
	if rawUUIDs, ok := body["uuid"].([]interface{}); ok {
		for _, v := range rawUUIDs {
			if s, ok := v.(string); ok && s != "" {
				uuids = append(uuids, s)
			}
		}
	}

	// Also support single "uuid" string
	if singleUUID, ok := body["uuid"].(string); ok && singleUUID != "" {
		uuids = append(uuids, singleUUID)
	}

	mobileFilter := strVal(body["mobileNumber"])
	userNameFilter := strVal(body["userName"])

	log.Printf("[admin] UserSearch: tenantId=%q, uuids=%v, mobile=%q, userName=%q",
		tenantID, uuids, mobileFilter, userNameFilter)

	gormQ := h.gdb.Model(&dbpkg.User{})

	if tenantID != "" {
		gormQ = gormQ.Where("tenant_id = ?", tenantID)
	}
	if len(uuids) > 0 {
		gormQ = gormQ.Where("uuid IN ?", uuids)
	}
	if mobileFilter != "" {
		gormQ = gormQ.Where("mobile_number = ?", mobileFilter)
	}
	if userNameFilter != "" {
		gormQ = gormQ.Where("user_name = ?", userNameFilter)
	}

	var users []dbpkg.User
	if result := gormQ.Order("created_at DESC").Limit(100).Find(&users); result.Error != nil {
		log.Printf("[admin] UserSearch DB error: %v", result.Error)
		writeJSON(w, http.StatusInternalServerError, errResp("Database error: "+result.Error.Error()))
		return
	}

	log.Printf("[admin] UserSearch found %d users", len(users))

	userList := make([]map[string]interface{}, 0, len(users))
	for _, u := range users {
		userList = append(userList, buildUserFromDB(u))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"user": userList,
	})
}

// ─── UpdateEmployee ───────────────────────────────────────────────────────────

// UpdateEmployee handles POST /egov-hrms/employees/_update
//
// Admin can update a gig worker's name, mobile, email, active status.
//
// Body: {
//   "RequestInfo": {...},
//   "Employees": [{
//     "uuid": "<uuid>",        // required — identifies the record
//     "code": "<mobile>",      // optional new mobile
//     "isActive": true/false,
//     "user": {
//       "name": "...",
//       "mobileNumber": "...",
//       "emailId": "..."
//     }
//   }]
// }
// Response: { "Employees": [...] }
func (h *AdminHandler) UpdateEmployee(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === UpdateEmployee called ===")
	log.Printf("[admin] Method: %s, URL: %s", r.Method, r.URL.String())

	rawBody := readBodyForLogging(r)
	log.Printf("[admin] UpdateEmployee raw body: %s", rawBody)

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		log.Printf("[admin] UpdateEmployee JSON decode error: %v", err)
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "INVALID_REQUEST", "message": "Invalid JSON: " + err.Error()},
			},
		})
		return
	}

	employeesRaw, _ := body["Employees"].([]interface{})
	if len(employeesRaw) == 0 {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "INVALID_REQUEST", "message": "Employees array is empty"},
			},
		})
		return
	}

	updated := make([]map[string]interface{}, 0, len(employeesRaw))

	for i, raw := range employeesRaw {
		emp, _ := raw.(map[string]interface{})
		if emp == nil {
			log.Printf("[admin] UpdateEmployee: employee[%d] is not an object, skipping", i)
			continue
		}

		empUUID := strVal(emp["uuid"])
		empCode := strVal(emp["code"])

		log.Printf("[admin] UpdateEmployee: processing employee uuid=%q, code=%q", empUUID, empCode)

		// Look up existing user
		var u dbpkg.User
		result := h.gdb.Where("uuid = ?", empUUID).First(&u)
		if result.Error != nil && empCode != "" {
			result = h.gdb.Where("mobile_number = ? OR user_name = ?", empCode, empCode).First(&u)
		}
		if result.Error != nil {
			log.Printf("[admin] UpdateEmployee: user not found for uuid=%q code=%q: %v", empUUID, empCode, result.Error)
			writeJSON(w, http.StatusNotFound, map[string]interface{}{
				"Errors": []map[string]interface{}{
					{"code": "NOT_FOUND", "message": fmt.Sprintf("Employee not found: uuid=%s", empUUID)},
				},
			})
			return
		}

		log.Printf("[admin] UpdateEmployee: found user id=%d, uuid=%s, current active=%v", u.ID, u.UUID, u.Active)

		// Apply updates from emp.isActive
		if isActiveRaw, exists := emp["isActive"]; exists {
			if isActive, ok := isActiveRaw.(bool); ok {
				u.Active = isActive
				log.Printf("[admin] UpdateEmployee: setting active=%v", isActive)
			}
		}

		// Apply updates from emp.user
		userMap, _ := emp["user"].(map[string]interface{})
		if userMap != nil {
			if v := strVal(userMap["name"]); v != "" {
				u.Name = &v
				log.Printf("[admin] UpdateEmployee: setting name=%q", v)
			}
			if v := strVal(userMap["mobileNumber"]); v != "" {
				u.MobileNumber = &v
				u.UserName = v
				log.Printf("[admin] UpdateEmployee: setting mobileNumber=%q", v)
			}
			if v := strVal(userMap["emailId"]); v != "" {
				u.EmailID = &v
				log.Printf("[admin] UpdateEmployee: setting emailId=%q", v)
			}
			// Handle role update if provided
			if rolesRaw, ok := userMap["roles"].([]interface{}); ok && len(rolesRaw) > 0 {
				if roleMap, ok := rolesRaw[0].(map[string]interface{}); ok {
					if v := strVal(roleMap["code"]); v != "" {
						u.RoleCode = v
					}
					if v := strVal(roleMap["name"]); v != "" {
						u.RoleName = v
					}
				}
			}
		}

		u.UpdatedAt = time.Now()

		if res := h.gdb.Save(&u); res.Error != nil {
			log.Printf("[admin] UpdateEmployee: save error: %v", res.Error)
			writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
				"Errors": []map[string]interface{}{
					{"code": "DB_ERROR", "message": "Failed to update employee: " + res.Error.Error()},
				},
			})
			return
		}

		log.Printf("[admin] UpdateEmployee: saved user id=%d, new active=%v", u.ID, u.Active)
		updated = append(updated, buildEmployeeFromUser(u))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Employees": updated,
		"ResponseInfo": map[string]interface{}{
			"status": fmt.Sprintf("%d", http.StatusOK),
		},
	})
}

// ─── DeactivateEmployee ───────────────────────────────────────────────────────

// DeactivateEmployee handles POST /egov-hrms/employees/_deactivate
//
// Soft-deletes (deactivates) a gig worker by setting active = false.
//
// Body: { "RequestInfo": {...}, "Employees": [{ "uuid": "...", "isActive": false }] }
// Response: { "Employees": [...] }
func (h *AdminHandler) DeactivateEmployee(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === DeactivateEmployee called ===")

	rawBody := readBodyForLogging(r)
	log.Printf("[admin] DeactivateEmployee raw body: %s", rawBody)

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "INVALID_REQUEST", "message": "Invalid JSON: " + err.Error()},
			},
		})
		return
	}

	employeesRaw, _ := body["Employees"].([]interface{})
	if len(employeesRaw) == 0 {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "INVALID_REQUEST", "message": "Employees array is empty"},
			},
		})
		return
	}

	deactivated := make([]map[string]interface{}, 0)

	for _, raw := range employeesRaw {
		emp, _ := raw.(map[string]interface{})
		if emp == nil {
			continue
		}
		empUUID := strVal(emp["uuid"])
		empCode := strVal(emp["code"])

		var u dbpkg.User
		result := h.gdb.Where("uuid = ?", empUUID).First(&u)
		if result.Error != nil && empCode != "" {
			result = h.gdb.Where("mobile_number = ? OR user_name = ?", empCode, empCode).First(&u)
		}
		if result.Error != nil {
			log.Printf("[admin] DeactivateEmployee: user not found uuid=%q code=%q", empUUID, empCode)
			continue
		}

		u.Active = false
		u.UpdatedAt = time.Now()

		if res := h.gdb.Save(&u); res.Error != nil {
			log.Printf("[admin] DeactivateEmployee: save error for uuid=%q: %v", empUUID, res.Error)
			continue
		}

		log.Printf("[admin] DeactivateEmployee: deactivated user id=%d uuid=%s", u.ID, u.UUID)
		deactivated = append(deactivated, buildEmployeeFromUser(u))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Employees": deactivated,
		"ResponseInfo": map[string]interface{}{
			"status": fmt.Sprintf("%d", http.StatusOK),
		},
	})
}

// ─── CreateAdminUser ──────────────────────────────────────────────────────────

// CreateAdminUser handles POST /admin/create
//
// Creates a new admin (PGR_ADMIN) user. This endpoint should be called during
// initial setup. For security, callers must provide the setup secret.
//
// Body: {
//   "setupSecret": "<ADMIN_SETUP_SECRET>",  // must match env var or default
//   "mobile":    "9876543210",
//   "email":     "admin@example.com",       // optional
//   "name":      "Admin User",
//   "password":  "secret123",
//   "tenantId":  "mz"                       // optional, defaults to mz
// }
// Response: { "code": 200, "status": true, "message": "...", "uuid": "..." }
func (h *AdminHandler) CreateAdminUser(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === CreateAdminUser called ===")

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code": 400, "status": false, "message": "Invalid JSON: " + err.Error(),
		})
		return
	}

	// Validate setup secret
	setupSecret := strVal(body["setupSecret"])
	expectedSecret := h.cfg.AdminSetupSecret()
	if setupSecret != expectedSecret {
		log.Printf("[admin] CreateAdminUser: invalid setup secret (got %q)", setupSecret)
		writeJSON(w, http.StatusForbidden, map[string]interface{}{
			"code": 403, "status": false, "message": "Invalid setup secret",
		})
		return
	}

	mobile := strings.TrimSpace(strVal(body["mobile"]))
	email := strings.TrimSpace(strVal(body["email"]))
	name := strings.TrimSpace(strVal(body["name"]))
	password := strVal(body["password"])
	tenantID := strVal(body["tenantId"])

	if mobile == "" {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code": 400, "status": false, "message": "mobile is required",
		})
		return
	}
	if password == "" {
		password = mobile // fallback
	}
	if tenantID == "" {
		tenantID = "mz"
	}
	if name == "" {
		name = "Admin"
	}

	// Check if mobile already registered
	var existing dbpkg.User
	err := h.gdb.Where("mobile_number = ? OR email_id = ?", mobile, mobile).First(&existing).Error
	if err == nil {
		log.Printf("[admin] CreateAdminUser: mobile/email already registered id=%d", existing.ID)
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"code": 409, "status": false, "message": "Mobile or email already registered",
		})
		return
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("[admin] CreateAdminUser: bcrypt error: %v", err)
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code": 500, "status": false, "message": "Failed to hash password",
		})
		return
	}

	newUUID := uuid.New().String()

	u := &dbpkg.User{
		UUID:      newUUID,
		UserName:  mobile,
		TenantID:  tenantID,
		RoleCode:  "PGR_ADMIN",
		RoleName:  "PGR Admin",
		Type:      "EMPLOYEE",
		Active:    true,
		PasswordHash: string(hashed),
	}
	u.Name = &name
	u.MobileNumber = &mobile
	if email != "" {
		u.EmailID = &email
	}

	if res := h.gdb.Create(u); res.Error != nil {
		log.Printf("[admin] CreateAdminUser: insert error: %v", res.Error)
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code": 500, "status": false,
			"message": "Failed to create admin user: " + res.Error.Error(),
		})
		return
	}

	log.Printf("[admin] CreateAdminUser: created admin user id=%d uuid=%s mobile=%s", u.ID, u.UUID, mobile)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"code":    200,
		"status":  true,
		"message": "Admin user created. Login with mobile and password.",
		"uuid":    u.UUID,
		"id":      u.ID,
	})
}

// ─── ListAllOrders (admin) ────────────────────────────────────────────────────

// GetAdminOrders handles POST /admin/orders/_search
//
// Admin view of all orders without any mobile-number restriction.
// Supports the same filters as PGRHandler.SearchServiceRequests but adds
// applicationStatus filtering to quickly see pending/assigned/resolved orders.
//
// Query params: tenantId, applicationStatus, fromDate (ms), toDate (ms), limit, offset
// Response: { "ServiceWrappers": [...] }
func (h *AdminHandler) GetAdminOrders(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === GetAdminOrders called ===")
	log.Printf("[admin] URL: %s", r.URL.String())

	q := r.URL.Query()
	tenantID := q.Get("tenantId")
	appStatus := q.Get("applicationStatus")
	fromDateStr := q.Get("fromDate")
	toDateStr := q.Get("toDate")
	limitStr := q.Get("limit")
	offsetStr := q.Get("offset")

	log.Printf("[admin] GetAdminOrders: tenantId=%q, status=%q, fromDate=%q, toDate=%q",
		tenantID, appStatus, fromDateStr, toDateStr)

	limit := 500
	if v := parseInt(limitStr); v > 0 {
		limit = v
	}
	offset := 0
	if v := parseInt(offsetStr); v >= 0 {
		offset = v
	}

	gormQ := h.gdb.Model(&dbpkg.ServiceRequest{})

	if tenantID != "" {
		gormQ = gormQ.Where("tenant_id = ?", tenantID)
	}
	if appStatus != "" {
		gormQ = gormQ.Where("application_status = ?", appStatus)
	}
	if fromDateStr != "" {
		if ms := parseInt64(fromDateStr); ms > 0 {
			gormQ = gormQ.Where("audit_created_time >= ?", ms)
		}
	}
	if toDateStr != "" {
		if ms := parseInt64(toDateStr); ms > 0 {
			gormQ = gormQ.Where("audit_created_time <= ?", ms)
		}
	}

	var records []dbpkg.ServiceRequest
	if result := gormQ.Order("created_at DESC").Limit(limit).Offset(offset).Find(&records); result.Error != nil {
		log.Printf("[admin] GetAdminOrders DB error: %v", result.Error)
		writeJSON(w, http.StatusInternalServerError, errResp("failed to query orders: "+result.Error.Error()))
		return
	}

	log.Printf("[admin] GetAdminOrders: found %d records", len(records))

	wrappers := make([]interface{}, 0, len(records))
	for i := range records {
		wrappers = append(wrappers, buildServiceWrapper(&records[i]))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ServiceWrappers": wrappers,
	})
}

// ─── GetAdminDashboardStats ───────────────────────────────────────────────────

// GetAdminDashboardStats handles GET /admin/dashboard/stats
//
// Returns summary counts: total orders, pending, assigned, resolved; total gig workers.
func (h *AdminHandler) GetAdminDashboardStats(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === GetAdminDashboardStats called ===")

	type countRow struct {
		ApplicationStatus string
		Count             int64
	}

	// Order counts grouped by status
	var counts []countRow
	h.gdb.Model(&dbpkg.ServiceRequest{}).
		Select("application_status, count(*) as count").
		Group("application_status").
		Scan(&counts)

	statusMap := map[string]int64{}
	total := int64(0)
	for _, c := range counts {
		statusMap[c.ApplicationStatus] = c.Count
		total += c.Count
	}

	// Gig worker count
	var gigCount int64
	h.gdb.Model(&dbpkg.User{}).Where("role_code = ? AND active = ?", "HELPDESK_USER", true).Count(&gigCount)

	// Admin count
	var adminCount int64
	h.gdb.Model(&dbpkg.User{}).Where("role_code = ?", "PGR_ADMIN").Count(&adminCount)

	// User count
	var userCount int64
	h.gdb.Model(&dbpkg.User{}).Where("role_code = ?", "DISTRIBUTOR").Count(&userCount)

	log.Printf("[admin] GetAdminDashboardStats: total=%d, gigWorkers=%d, admins=%d, users=%d",
		total, gigCount, adminCount, userCount)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"totalOrders":      total,
		"pendingOrders":    statusMap["PENDING_ASSIGNMENT"],
		"assignedOrders":   statusMap["ASSIGNED"],
		"resolvedOrders":   statusMap["RESOLVED"],
		"statusBreakdown":  statusMap,
		"totalGigWorkers":  gigCount,
		"totalAdmins":      adminCount,
		"totalUsers":       userCount,
	})
}

// ─── GetGigWorkerOrders ───────────────────────────────────────────────────────

// GetGigWorkerOrders handles GET /admin/gig-workers/:uuid/orders
//
// Returns orders currently assigned to a specific gig worker.
// The uuid is taken from the "workerUuid" query param.
func (h *AdminHandler) GetGigWorkerOrders(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === GetGigWorkerOrders called ===")

	q := r.URL.Query()
	workerUUID := q.Get("workerUuid")
	if workerUUID == "" {
		writeJSON(w, http.StatusBadRequest, errResp("workerUuid is required"))
		return
	}

	log.Printf("[admin] GetGigWorkerOrders: workerUuid=%q", workerUUID)

	// Orders that have the worker's UUID in workflow_assignes JSON array
	var records []dbpkg.ServiceRequest
	if result := h.gdb.
		Where("workflow_assignes LIKE ?", "%"+workerUUID+"%").
		Order("created_at DESC").
		Find(&records); result.Error != nil {
		log.Printf("[admin] GetGigWorkerOrders DB error: %v", result.Error)
		writeJSON(w, http.StatusInternalServerError, errResp("failed to query orders: "+result.Error.Error()))
		return
	}

	log.Printf("[admin] GetGigWorkerOrders: found %d records for worker %s", len(records), workerUUID)

	wrappers := make([]interface{}, 0, len(records))
	for i := range records {
		wrappers = append(wrappers, buildServiceWrapper(&records[i]))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ServiceWrappers": wrappers,
	})
}

// ─── CreateHelpdeskUser ───────────────────────────────────────────────────────

// CreateHelpdeskUser handles POST /admin/helpdesk-users/_create
//
// Called from the admin profile "Add Users" screen to create a new gig worker
// (HELPDESK_USER role) without needing direct DB access.
//
// Body: {
//   "name":         "John Doe",
//   "mobileNumber": "9876543210",
//   "emailId":      "john@example.com",  // optional
//   "password":     "secret123",
//   "tenantId":     "mz"                 // optional, defaults to mz
// }
// Response: { "code": 200, "status": true, "message": "...", "uuid": "..." }
func (h *AdminHandler) CreateHelpdeskUser(w http.ResponseWriter, r *http.Request) {
	log.Println("[admin] === CreateHelpdeskUser called ===")

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code": 400, "status": false, "message": "Invalid JSON: " + err.Error(),
		})
		return
	}

	mobile := strings.TrimSpace(strVal(body["mobileNumber"]))
	name := strings.TrimSpace(strVal(body["name"]))
	email := strings.TrimSpace(strVal(body["emailId"]))
	password := strVal(body["password"])
	tenantID := strVal(body["tenantId"])

	if mobile == "" {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code": 400, "status": false, "message": "mobileNumber is required",
		})
		return
	}
	if name == "" {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code": 400, "status": false, "message": "name is required",
		})
		return
	}
	if password == "" {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code": 400, "status": false, "message": "password is required",
		})
		return
	}
	if tenantID == "" {
		tenantID = "mz"
	}

	// Check duplicate mobile
	var existing dbpkg.User
	if err := h.gdb.Where("mobile_number = ?", mobile).First(&existing).Error; err == nil {
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"code": 409, "status": false, "message": "Mobile number already registered",
		})
		return
	}

	// Check duplicate email if provided
	if email != "" {
		if err := h.gdb.Where("email_id = ?", email).First(&existing).Error; err == nil {
			writeJSON(w, http.StatusOK, map[string]interface{}{
				"code": 409, "status": false, "message": "Email already registered",
			})
			return
		}
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("[admin] CreateHelpdeskUser: bcrypt error: %v", err)
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code": 500, "status": false, "message": "Failed to hash password",
		})
		return
	}

	newUUID := uuid.New().String()
	u := &dbpkg.User{
		UUID:         newUUID,
		UserName:     mobile,
		TenantID:     tenantID,
		RoleCode:     "HELPDESK_USER",
		RoleName:     "Helpdesk User",
		Type:         "EMPLOYEE",
		Active:       true,
		PasswordHash: string(hashed),
	}
	u.Name = &name
	u.MobileNumber = &mobile
	if email != "" {
		u.EmailID = &email
	}

	if res := h.gdb.Create(u); res.Error != nil {
		log.Printf("[admin] CreateHelpdeskUser: insert error: %v", res.Error)
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code": 500, "status": false,
			"message": "Failed to create user: " + res.Error.Error(),
		})
		return
	}

	log.Printf("[admin] CreateHelpdeskUser: created helpdesk user id=%d uuid=%s mobile=%s", u.ID, u.UUID, mobile)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"code":    200,
		"status":  true,
		"message": "Helpdesk user created successfully. They can login with their mobile number.",
		"uuid":    u.UUID,
		"id":      u.ID,
	})
}

// ─── parseInt helpers ─────────────────────────────────────────────────────────

func parseInt(s string) int {
	if s == "" {
		return 0
	}
	var v int
	fmt.Sscanf(s, "%d", &v)
	return v
}

func parseInt64(s string) int64 {
	if s == "" {
		return 0
	}
	var v int64
	fmt.Sscanf(s, "%d", &v)
	return v
}
