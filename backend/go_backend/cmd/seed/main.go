// cmd/seed/main.go
//
// Inserts test users (3 gig workers + 1 admin) into the plotrol_new DB.
// Run from the go_backend directory:
//
//   go run ./cmd/seed
//
// It is safe to run multiple times – existing rows (matched by mobile_number)
// are skipped so no duplicates are created.

package main

import (
	"fmt"
	"log"

	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"plotrol-backend/config"
	dbpkg "plotrol-backend/db"
)

// seedUser describes one user to insert.
type seedUser struct {
	Name     string
	Mobile   string
	Email    string
	Password string
	RoleCode string
	RoleName string
}

func main() {
	// Load .env
	if err := godotenv.Load(); err != nil {
		log.Println("[seed] no .env file – falling back to OS env vars")
	}

	cfg := config.Load()

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass, cfg.DBName,
	)
	gormDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("[seed] cannot connect to DB: %v", err)
	}
	log.Printf("[seed] Connected to %s:%s db=%s", cfg.DBHost, cfg.DBPort, cfg.DBName)

	// Run migrations so the users table exists
	if err := dbpkg.RunMigrationsGORM(gormDB); err != nil {
		log.Fatalf("[seed] migration error: %v", err)
	}

	users := []seedUser{
		// ── Admin ──────────────────────────────────────────────────────
		{
			Name:     "Admin User",
			Mobile:   "9000000000",
			Email:    "admin@plotrol.com",
			Password: "Admin@123",
			RoleCode: "PGR_ADMIN",
			RoleName: "PGR Admin",
		},
		// ── Gig workers ────────────────────────────────────────────────
		{
			Name:     "Arjun Singh",
			Mobile:   "9000000001",
			Email:    "arjun@plotrol.com",
			Password: "Worker@1",
			RoleCode: "HELPDESK_USER",
			RoleName: "Helpdesk User",
		},
		{
			Name:     "Priya Sharma",
			Mobile:   "9000000002",
			Email:    "priya@plotrol.com",
			Password: "Worker@2",
			RoleCode: "HELPDESK_USER",
			RoleName: "Helpdesk User",
		},
		{
			Name:     "Rahul Kumar",
			Mobile:   "9000000003",
			Email:    "rahul@plotrol.com",
			Password: "Worker@3",
			RoleCode: "HELPDESK_USER",
			RoleName: "Helpdesk User",
		},
	}

	for _, u := range users {
		insert(gormDB, u)
	}

	log.Println("[seed] Done.")
	printLoginTable(users)
}

func insert(gormDB *gorm.DB, u seedUser) {
	// Skip if mobile OR email already exists
	var existing dbpkg.User
	q := gormDB.Where("mobile_number = ?", u.Mobile)
	if u.Email != "" {
		q = gormDB.Where("mobile_number = ? OR email_id = ?", u.Mobile, u.Email)
	}
	err := q.First(&existing).Error
	if err == nil {
		log.Printf("[seed] SKIP  %-15s  mobile=%s  (already exists, id=%d)", u.Name, u.Mobile, existing.ID)
		return
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(u.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("[seed] ERROR hashing password for %s: %v", u.Name, err)
		return
	}

	newUUID := uuid.New().String()
	name := u.Name
	mobile := u.Mobile
	email := u.Email

	row := &dbpkg.User{
		UUID:         newUUID,
		UserName:     mobile,
		Name:         &name,
		MobileNumber: &mobile,
		PasswordHash: string(hashed),
		Type:         "EMPLOYEE",
		TenantID:     "mz",
		RoleCode:     u.RoleCode,
		RoleName:     u.RoleName,
		Active:       true,
	}
	if email != "" {
		row.EmailID = &email
	}

	if res := gormDB.Create(row); res.Error != nil {
		log.Printf("[seed] ERROR inserting %s: %v", u.Name, res.Error)
		return
	}

	log.Printf("[seed] OK    %-15s  mobile=%-12s  role=%-14s  id=%d  uuid=%s",
		u.Name, u.Mobile, u.RoleCode, row.ID, row.UUID)
}

func printLoginTable(users []seedUser) {
	fmt.Println()
	fmt.Println("┌─────────────────────────────────────────────────────────────────────┐")
	fmt.Println("│                      TEST CREDENTIALS                               │")
	fmt.Println("├──────────────────┬──────────────┬──────────┬───────────────────────┤")
	fmt.Println("│ Name             │ Mobile       │ Password │ Role                  │")
	fmt.Println("├──────────────────┼──────────────┼──────────┼───────────────────────┤")
	for _, u := range users {
		fmt.Printf("│ %-16s │ %-12s │ %-8s │ %-21s │\n",
			u.Name, u.Mobile, u.Password, u.RoleCode)
	}
	fmt.Println("└──────────────────┴──────────────┴──────────┴───────────────────────┘")
	fmt.Println()
	fmt.Println("Login endpoint:  POST http://localhost:8080/user/oauth/token")
	fmt.Println("Body (form):     username=9000000000&password=Admin@123&grant_type=password")
	fmt.Println()
}
