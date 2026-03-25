package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"plotrol-backend/config"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// ─── Shared types ────────────────────────────────────────────────────────────

// User mirrors a row in the users table.
type User struct {
	ID           int
	UUID         string
	UserName     string
	Name         sql.NullString
	FirstName    sql.NullString
	LastName     sql.NullString
	MobileNumber sql.NullString
	EmailID      sql.NullString
	PasswordHash string
	Type         string
	TenantID     string
	RoleCode     string
	RoleName     string
	Active       bool
	Address      sql.NullString
	Suburb       sql.NullString
	City         sql.NullString
	StateName    sql.NullString
	Postcode     sql.NullString
	Latitude     sql.NullString
	Longitude    sql.NullString
	TenantImage  sql.NullString
}

// writeJSON writes a JSON response with the given status code.
func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// nullStr returns the string value or nil for a NullString.
func nullStr(ns sql.NullString) interface{} {
	if ns.Valid && ns.String != "" {
		return ns.String
	}
	return nil
}

// ─── Auth handler ────────────────────────────────────────────────────────────

// AuthHandler handles login and signup.
type AuthHandler struct {
	db  *sql.DB
	cfg *config.Config
}

// NewAuthHandler returns a new AuthHandler.
func NewAuthHandler(db *sql.DB, cfg *config.Config) *AuthHandler {
	return &AuthHandler{db: db, cfg: cfg}
}

// ─── Login ───────────────────────────────────────────────────────────────────

// Login handles POST /user/oauth/token
// Flutter sends: application/x-www-form-urlencoded
//   username=<mobile_or_email>&password=<pwd>&grant_type=password&...
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if err := r.ParseForm(); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"error":             "invalid_request",
			"error_description": "Cannot parse form body",
		})
		return
	}

	username := strings.TrimSpace(r.FormValue("username"))
	password := r.FormValue("password")

	if username == "" || password == "" {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"error":             "invalid_request",
			"error_description": "username and password are required",
		})
		return
	}

	// Find user by user_name, mobile_number, or email_id
	var u User
	err := h.db.QueryRow(`
		SELECT id, uuid, user_name, name, first_name, last_name,
		       mobile_number, email_id, password_hash, type, tenant_id,
		       role_code, role_name, active, address, suburb, city,
		       state_name, postcode, latitude, longitude, tenant_image
		FROM users
		WHERE user_name = $1 OR mobile_number = $2 OR email_id = $3
		LIMIT 1
	`, username, username, username).Scan(
		&u.ID, &u.UUID, &u.UserName, &u.Name,
		&u.FirstName, &u.LastName,
		&u.MobileNumber, &u.EmailID, &u.PasswordHash,
		&u.Type, &u.TenantID, &u.RoleCode, &u.RoleName,
		&u.Active, &u.Address, &u.Suburb, &u.City,
		&u.StateName, &u.Postcode, &u.Latitude, &u.Longitude,
		&u.TenantImage,
	)

	if err == sql.ErrNoRows {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"error":             "invalid_grant",
			"error_description": "Invalid username or password",
		})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"error":             "server_error",
			"error_description": "Database error",
		})
		return
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password)); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"error":             "invalid_grant",
			"error_description": "Invalid username or password",
		})
		return
	}

	// Generate tokens
	expiresIn := 86400
	accessToken, err := makeJWT(u.UUID, u.UserName, h.cfg.JWTSecret, expiresIn)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{"error": "server_error"})
		return
	}
	refreshToken, _ := makeJWT(u.UUID+"_refresh", u.UserName, h.cfg.JWTSecret, expiresIn*7)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"access_token":  accessToken,
		"token_type":    "bearer",
		"refresh_token": refreshToken,
		"expires_in":    expiresIn,
		"scope":         "read",
		"UserRequest": map[string]interface{}{
			"id":               u.ID,
			"uuid":             u.UUID,
			"userServiceUuid":  u.UUID,
			"userName":         u.UserName,
			"name":             nullStr(u.Name),
			"mobileNumber":     nullStr(u.MobileNumber),
			"emailId":          nullStr(u.EmailID),
			"type":             u.Type,
			"tenantId":         u.TenantID,
			"active":           u.Active,
			"permanentAddress": nullStr(u.Address),
			"permanentCity":    nullStr(u.City),
			"permanentPinCode": nullStr(u.Postcode),
			"photo":            nullStr(u.TenantImage),
			"roles": []map[string]interface{}{
				{
					"name":     u.RoleName,
					"code":     u.RoleCode,
					"tenantId": u.TenantID,
				},
			},
		},
	})
}

// ─── Signup / Create Tenant User ─────────────────────────────────────────────

// CreateAccountRequest mirrors Flutter's CreateAccountRequest JSON body.
type CreateAccountRequest struct {
	TenantName     string `json:"tenantname"`
	TenantType     string `json:"tenanttype"`
	FirstName      string `json:"firstname"`
	LastName       string `json:"lastname"`
	PrimaryEmail   string `json:"primaryemail"`
	PrimaryContact string `json:"primarycontact"` // mobile number
	Address        string `json:"address"`
	Suburb         string `json:"suburb"`
	State          string `json:"state"`
	City           string `json:"city"`
	Postcode       string `json:"postcode"`
	Latitude       string `json:"latitude"`
	Longitude      string `json:"longitude"`
	TenantImage    string `json:"tenantimage"`
	DeviceType     string `json:"devicetype"`
	AppLocationID  int    `json:"applocationid"`
}

// CreateTenantUser handles POST /api/v1/tenants/createtenantuser
func (h *AuthHandler) CreateTenantUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req CreateAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code":    400,
			"message": "Invalid JSON body",
			"status":  false,
		})
		return
	}

	req.PrimaryContact = strings.TrimSpace(req.PrimaryContact)
	req.PrimaryEmail = strings.TrimSpace(req.PrimaryEmail)

	if req.PrimaryContact == "" {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"code":    400,
			"message": "Primary contact (mobile number) is required",
			"status":  false,
		})
		return
	}

	// Check duplicate mobile — distinguish "row found" from a real DB error
	var existingID int
	err := h.db.QueryRow(
		"SELECT id FROM users WHERE mobile_number = $1 LIMIT 1",
		req.PrimaryContact,
	).Scan(&existingID)
	if err == nil {
		// A row was found → genuine duplicate
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"code":    409,
			"message": "Mobile number already registered. Please login.",
			"status":  false,
		})
		return
	} else if err != sql.ErrNoRows {
		// Unexpected DB error (not a "no rows" result)
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code":    500,
			"message": "Database error during duplicate check: " + err.Error(),
			"status":  false,
		})
		return
	}
	// err == sql.ErrNoRows → mobile not taken, proceed

	// Check duplicate email (only if provided)
	if req.PrimaryEmail != "" {
		err = h.db.QueryRow(
			"SELECT id FROM users WHERE email_id = $1 LIMIT 1",
			req.PrimaryEmail,
		).Scan(&existingID)
		if err == nil {
			writeJSON(w, http.StatusOK, map[string]interface{}{
				"code":    409,
				"message": "Email already registered. Please login.",
				"status":  false,
			})
			return
		} else if err != sql.ErrNoRows {
			writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
				"code":    500,
				"message": "Database error during email check: " + err.Error(),
				"status":  false,
			})
			return
		}
	}

	// Build full name
	fullName := strings.TrimSpace(req.FirstName + " " + req.LastName)
	if fullName == "" {
		fullName = req.PrimaryContact
	}

	// Default password = mobile number
	hashed, err := bcrypt.GenerateFromPassword([]byte(req.PrimaryContact), bcrypt.DefaultCost)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code":    500,
			"message": "Failed to process request",
			"status":  false,
		})
		return
	}

	userUUID := uuid.New().String()

	// Use nil for empty optional fields to avoid empty-string UNIQUE conflicts
	var emailParam interface{}
	if req.PrimaryEmail != "" {
		emailParam = req.PrimaryEmail
	}
	var imageParam interface{}
	if req.TenantImage != "" {
		imageParam = req.TenantImage
	}

	// PostgreSQL: use RETURNING id instead of LastInsertId()
	var newID int
	err = h.db.QueryRow(`
		INSERT INTO users (
			uuid, user_name, name, first_name, last_name,
			mobile_number, email_id, password_hash,
			type, tenant_id, role_code, role_name, active,
			address, suburb, city, state_name, postcode,
			latitude, longitude, tenant_image, device_type
		) VALUES (
			$1,  $2,  $3,  $4,  $5,
			$6,  $7,  $8,
			$9,  $10, $11, $12, $13,
			$14, $15, $16, $17, $18,
			$19, $20, $21, $22
		) RETURNING id
	`,
		userUUID,
		req.PrimaryContact, // user_name = mobile number
		fullName, req.FirstName, req.LastName,
		req.PrimaryContact, emailParam, string(hashed),
		"EMPLOYEE", "mz", "DISTRIBUTOR", "Distributor", true,
		req.Address, req.Suburb, req.City, req.State, req.Postcode,
		req.Latitude, req.Longitude, imageParam, req.DeviceType,
	).Scan(&newID)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]interface{}{
			"code":    500,
			"message": "Failed to create user: " + err.Error(),
			"status":  false,
		})
		return
	}

	// NOTE: primarycontact is intentionally omitted from details.
	// The Flutter controller shows "Tenant Already Exists" whenever
	// details.primarycontact == entered mobile. Omitting it keeps that
	// check false on success so only the "User Created Success" toast shows.
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"code":    200,
		"message": "Account created successfully. Your default password is your mobile number.",
		"status":  true,
		"details": map[string]interface{}{
			"tenantid":     newID,
			"tenantname":   req.TenantName,
			"tenanttype":   req.TenantType,
			"primaryemail": req.PrimaryEmail,
			"firstname":    req.FirstName,
			"lastname":     req.LastName,
			"address":      req.Address,
			"suburb":       req.Suburb,
			"city":         req.City,
			"state":        req.State,
			"postcode":     req.Postcode,
			"latitude":     req.Latitude,
			"longitude":    req.Longitude,
			"tenantimage":  req.TenantImage,
			"status":       "ACTIVE",
			"approved":     1,
		},
	})
}

// ─── JWT helper ──────────────────────────────────────────────────────────────

func makeJWT(subject, name, secret string, expiresIn int) (string, error) {
	claims := jwt.MapClaims{
		"sub":  subject,
		"name": name,
		"exp":  time.Now().Add(time.Duration(expiresIn) * time.Second).Unix(),
		"iat":  time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
}
