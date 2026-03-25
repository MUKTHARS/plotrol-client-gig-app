package db

import (
	"database/sql"
	"fmt"

	"plotrol-backend/config"

	_ "github.com/lib/pq"
)

// Connect creates the database if needed and returns a connection.
func Connect(cfg *config.Config) (*sql.DB, error) {
	// Connect to the default "postgres" database first to create ours if needed
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

	// Create database only if it doesn't exist (PostgreSQL has no IF NOT EXISTS for CREATE DATABASE)
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

	// Connect to the target database
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass, cfg.DBName,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return db, nil
}

// RunMigrations creates tables if they don't exist.
func RunMigrations(db *sql.DB) error {
	_, err := db.Exec(`
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

	// Indexes (IF NOT EXISTS supported in PostgreSQL 9.5+)
	if _, err := db.Exec(`CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number)`); err != nil {
		return err
	}
	if _, err := db.Exec(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email_id)`); err != nil {
		return err
	}
	return nil
}
