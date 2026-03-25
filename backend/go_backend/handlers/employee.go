package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"golang.org/x/crypto/bcrypt"

	"github.com/google/uuid"
)

// EmployeeHandler handles employee-related routes.
type EmployeeHandler struct {
	db *sql.DB
}

// NewEmployeeHandler returns a new EmployeeHandler.
func NewEmployeeHandler(db *sql.DB) *EmployeeHandler {
	return &EmployeeHandler{db: db}
}

// CreateEmployee handles POST /egov-hrms/employees/_create
//
// Flutter (requester_login_controller) sends:
//
//	{
//	  "RequestInfo": {...},
//	  "Employees": [{
//	    "code": "<mobile>",
//	    "tenantId": "mz",
//	    "employeeStatus": "EMPLOYED",
//	    "employeeType": "PERMANENT",
//	    "user": {
//	      "mobileNumber": "<mobile>",
//	      "name": "<name>",
//	      "password": "<password>",
//	      "userName": "<mobile>",
//	      "tenantId": "mz",
//	      "roles": [{"code":"DISTRIBUTOR","name":"Distributor","tenantId":"mz"}]
//	    },
//	    ...
//	  }]
//	}
//
// After this call, the controller immediately calls POST /user/oauth/token to login.
// So: create the user if new, or leave existing user as-is.
// Response must have Employees[0].code != null for the login step to proceed.
func (h *EmployeeHandler) CreateEmployee(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "INVALID_REQUEST", "message": "Invalid JSON body"},
			},
		})
		return
	}

	// Extract first employee from the Employees array
	employeesRaw, _ := body["Employees"].([]interface{})
	if len(employeesRaw) == 0 {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "INVALID_REQUEST", "message": "Employees array is empty"},
			},
		})
		return
	}

	emp, _ := employeesRaw[0].(map[string]interface{})
	userMap, _ := emp["user"].(map[string]interface{})

	mobile := strings.TrimSpace(strVal(userMap["mobileNumber"]))
	userName := strings.TrimSpace(strVal(userMap["userName"]))
	name := strings.TrimSpace(strVal(userMap["name"]))
	password := strVal(userMap["password"])
	tenantID := strVal(emp["tenantId"])
	empCode := strVal(emp["code"]) // usually the mobile number
	empStatus := strVal(emp["employeeStatus"])
	empType := strVal(emp["employeeType"])

	if mobile == "" {
		mobile = userName
	}
	if tenantID == "" {
		tenantID = "mz"
	}
	if empCode == "" {
		empCode = mobile
	}

	// Extract role from user.roles[0]
	roleCode := "DISTRIBUTOR"
	roleName := "Distributor"
	if rolesRaw, ok := userMap["roles"].([]interface{}); ok && len(rolesRaw) > 0 {
		if roleMap, ok := rolesRaw[0].(map[string]interface{}); ok {
			if v := strVal(roleMap["code"]); v != "" {
				roleCode = v
			}
			if v := strVal(roleMap["name"]); v != "" {
				roleName = v
			}
		}
	}

	// Check if user already exists by mobile
	var existingID int
	var existingUUID string
	checkErr := h.db.QueryRow(
		"SELECT id, uuid FROM users WHERE mobile_number = $1 OR user_name = $2 LIMIT 1",
		mobile, userName,
	).Scan(&existingID, &existingUUID)

	var userID int
	var userUUID string

	if checkErr == nil {
		// User already exists — use existing record; update password if provided
		userID = existingID
		userUUID = existingUUID
		if password != "" {
			hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
			if err == nil {
				h.db.Exec("UPDATE users SET password_hash = $1 WHERE id = $2", string(hashed), userID)
			}
		}
	} else if checkErr == sql.ErrNoRows {
		// New user — create
		if password == "" {
			password = mobile // fallback default
		}
		hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
				"Errors": []map[string]interface{}{{"code": "SERVER_ERROR", "message": "Failed to hash password"}},
			})
			return
		}

		newUUID := uuid.New().String()
		insertErr := h.db.QueryRow(`
			INSERT INTO users (
				uuid, user_name, name, mobile_number,
				password_hash, type, tenant_id, role_code, role_name, active
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
			RETURNING id, uuid
		`,
			newUUID, mobile, name, mobile,
			string(hashed), "EMPLOYEE", tenantID, roleCode, roleName, true,
		).Scan(&userID, &userUUID)

		if insertErr != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
				"Errors": []map[string]interface{}{
					{"code": "SERVER_ERROR", "message": "Failed to create employee: " + insertErr.Error()},
				},
			})
			return
		}
	} else {
		// Unexpected DB error
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"Errors": []map[string]interface{}{
				{"code": "DB_ERROR", "message": "Database error: " + checkErr.Error()},
			},
		})
		return
	}

	// Build response — mirrors the Employee model Flutter expects.
	// The controller checks: result?.employees.first.code != null
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"Employees": []map[string]interface{}{
			{
				"id":              userID,
				"uuid":            userUUID,
				"code":            empCode, // must be non-null for controller to proceed to login
				"employeeStatus":  empStatus,
				"employeeType":    empType,
				"tenantId":        tenantID,
				"isActive":        true,
				"reActivateEmployee": false,
				"jurisdictions":   []interface{}{},
				"assignments":     []interface{}{},
				"serviceHistory":  []interface{}{},
				"education":       []interface{}{},
				"tests":           []interface{}{},
				"documents":       []interface{}{},
				"deactivationDetails":  []interface{}{},
				"reactivationDetails":  []interface{}{},
				"user": map[string]interface{}{
					"id":           userID,
					"uuid":         userUUID,
					"userName":     mobile,
					"name":         name,
					"mobileNumber": mobile,
					"tenantId":     tenantID,
					"type":         "EMPLOYEE",
					"active":       true,
					"roles": []map[string]interface{}{
						{"name": roleName, "code": roleCode, "tenantId": tenantID},
					},
				},
			},
		},
		"ResponseInfo": map[string]interface{}{
			"status": fmt.Sprintf("%d", http.StatusOK),
		},
	})
}

// strVal safely extracts a string value from an interface{}.
func strVal(v interface{}) string {
	if v == nil {
		return ""
	}
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}
