package db

import (
	"database/sql"
	"fmt"
	"time"

	"plotrol-backend/config"

	_ "github.com/lib/pq"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// ─── GORM model ───────────────────────────────────────────────────────────────

// User is the GORM model that maps to the users table.
type User struct {
	ID           uint      `gorm:"primaryKey;autoIncrement"`
	UUID         string    `gorm:"type:varchar(36);not null;uniqueIndex"`
	UserName     string    `gorm:"column:user_name;type:varchar(200);not null;uniqueIndex"`
	Name         *string   `gorm:"type:varchar(200)"`
	FirstName    *string   `gorm:"column:first_name;type:varchar(100)"`
	LastName     *string   `gorm:"column:last_name;type:varchar(100)"`
	MobileNumber *string   `gorm:"column:mobile_number;type:varchar(30);uniqueIndex"`
	EmailID      *string   `gorm:"column:email_id;type:varchar(200);uniqueIndex"`
	PasswordHash string    `gorm:"column:password_hash;type:varchar(255);not null"`
	Type         string    `gorm:"type:varchar(50);not null;default:EMPLOYEE"`
	TenantID     string    `gorm:"column:tenant_id;type:varchar(50);not null;default:mz"`
	RoleCode     string    `gorm:"column:role_code;type:varchar(50);not null;default:DISTRIBUTOR"`
	RoleName     string    `gorm:"column:role_name;type:varchar(100);not null;default:Distributor"`
	Active       bool      `gorm:"not null;default:true"`
	Address      *string   `gorm:"type:text"`
	Suburb       *string   `gorm:"type:varchar(100)"`
	City         *string   `gorm:"type:varchar(100)"`
	StateName    *string   `gorm:"column:state_name;type:varchar(100)"`
	Postcode     *string   `gorm:"type:varchar(20)"`
	Latitude     *string   `gorm:"type:varchar(50)"`
	Longitude    *string   `gorm:"type:varchar(50)"`
	TenantImage  *string   `gorm:"column:tenant_image;type:text"`
	DeviceType   *string   `gorm:"column:device_type;type:varchar(50)"`
	CreatedAt    time.Time `gorm:"column:created_at;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt    time.Time `gorm:"column:updated_at;not null;default:CURRENT_TIMESTAMP"`
}

func (User) TableName() string { return "users" }

// ─── GORM connection ──────────────────────────────────────────────────────────

// ConnectGORM creates the database if needed and returns a *gorm.DB.
// The caller can obtain the underlying *sql.DB via gormDB.DB() for handlers
// that still use database/sql directly.
func ConnectGORM(cfg *config.Config) (*gorm.DB, error) {
	// First connect to the default "postgres" database to create ours if needed
	initDSN := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=postgres sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass,
	)
	initDB, err := sql.Open("postgres", initDSN)
	if err != nil {
		return nil, fmt.Errorf("open init connection: %w", err)
	}
	defer initDB.Close()

	if err := initDB.Ping(); err != nil {
		return nil, fmt.Errorf("ping PostgreSQL (is it running on %s:%s?): %w", cfg.DBHost, cfg.DBPort, err)
	}

	var exists int
	_ = initDB.QueryRow(
		"SELECT 1 FROM pg_database WHERE datname = $1", cfg.DBName,
	).Scan(&exists)
	if exists == 0 {
		if _, err := initDB.Exec(`CREATE DATABASE "` + cfg.DBName + `"`); err != nil {
			return nil, fmt.Errorf("create database: %w", err)
		}
	}

	// Open via GORM
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass, cfg.DBName,
	)
	gormDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("gorm open: %w", err)
	}
	return gormDB, nil
}

// RunMigrationsGORM auto-migrates the schema using GORM.
func RunMigrationsGORM(db *gorm.DB) error {
	if err := db.AutoMigrate(&User{}); err != nil {
		return fmt.Errorf("auto migrate: %w", err)
	}
	// Ensure indexes exist (GORM creates uniqueIndex tags, but add regular ones too)
	db.Exec(`CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number)`)
	db.Exec(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email_id)`)
	return nil
}

// ─── Legacy sql.DB connection (kept for reference) ───────────────────────────

// Connect creates the database if needed and returns a *sql.DB.
// Deprecated: prefer ConnectGORM; use gormDB.DB() to get the underlying *sql.DB.
func Connect(cfg *config.Config) (*sql.DB, error) {
	initDSN := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=postgres sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass,
	)
	initDB, err := sql.Open("postgres", initDSN)
	if err != nil {
		return nil, fmt.Errorf("open init connection: %w", err)
	}
	if err := initDB.Ping(); err != nil {
		initDB.Close()
		return nil, fmt.Errorf("ping PostgreSQL (is it running on %s:%s?): %w", cfg.DBHost, cfg.DBPort, err)
	}

	var exists int
	_ = initDB.QueryRow(
		"SELECT 1 FROM pg_database WHERE datname = $1", cfg.DBName,
	).Scan(&exists)
	if exists == 0 {
		if _, err := initDB.Exec(`CREATE DATABASE "` + cfg.DBName + `"`); err != nil {
			initDB.Close()
			return nil, fmt.Errorf("create database: %w", err)
		}
	}
	initDB.Close()

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass, cfg.DBName,
	)
	sqlDB, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}
	if err := sqlDB.Ping(); err != nil {
		sqlDB.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return sqlDB, nil
}

// RunMigrations creates tables via raw SQL (legacy).
func RunMigrations(sqlDB *sql.DB) error {
	_, err := sqlDB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id            SERIAL       PRIMARY KEY,
			uuid          VARCHAR(36)  NOT NULL UNIQUE,
			user_name     VARCHAR(200) NOT NULL UNIQUE,
			name          VARCHAR(200),
			first_name    VARCHAR(100),
			last_name     VARCHAR(100),
			mobile_number VARCHAR(30)  UNIQUE,
			email_id      VARCHAR(200) UNIQUE,
			password_hash VARCHAR(255) NOT NULL,
			type          VARCHAR(50)  NOT NULL DEFAULT 'EMPLOYEE',
			tenant_id     VARCHAR(50)  NOT NULL DEFAULT 'mz',
			role_code     VARCHAR(50)  NOT NULL DEFAULT 'DISTRIBUTOR',
			role_name     VARCHAR(100) NOT NULL DEFAULT 'Distributor',
			active        BOOLEAN      NOT NULL DEFAULT TRUE,
			address       TEXT,
			suburb        VARCHAR(100),
			city          VARCHAR(100),
			state_name    VARCHAR(100),
			postcode      VARCHAR(20),
			latitude      VARCHAR(50),
			longitude     VARCHAR(50),
			tenant_image  TEXT,
			device_type   VARCHAR(50),
			created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
			updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return err
	}
	if _, err := sqlDB.Exec(`CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number)`); err != nil {
		return err
	}
	if _, err := sqlDB.Exec(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email_id)`); err != nil {
		return err
	}
	return nil
}
