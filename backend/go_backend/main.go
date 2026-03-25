package main

import (
	"log"
	"net/http"

	"plotrol-backend/config"
	"plotrol-backend/db"
	"plotrol-backend/handlers"

	"github.com/joho/godotenv"
)

func main() {
	// Load .env (ignore error if file not present – env vars may already be set)
	if err := godotenv.Load(); err != nil {
		log.Println("[warn] no .env file found; falling back to OS environment variables")
	}

	cfg := config.Load()

	// Connect to MySQL and create database if needed
	database, err := db.Connect(cfg)
	if err != nil {
		log.Fatalf("[FATAL] Database connection failed: %v\n\nMake sure MySQL is running on %s:%s",
			err, cfg.DBHost, cfg.DBPort)
	}
	defer database.Close()
	log.Printf("[ok] Connected to MySQL – database: %s", cfg.DBName)

	// Create tables if they don't exist
	if err := db.RunMigrations(database); err != nil {
		log.Fatalf("[FATAL] Migration failed: %v", err)
	}
	log.Println("[ok] Database migrations applied")

	// Register routes
	mux := http.NewServeMux()

	authHandler := handlers.NewAuthHandler(database, cfg)
	indHandler := handlers.NewIndividualHandler(database)
	empHandler := handlers.NewEmployeeHandler(database)

	// Auth
	mux.HandleFunc("/user/oauth/token", authHandler.Login)
	mux.HandleFunc("/api/v1/tenants/createtenantuser", authHandler.CreateTenantUser)

	// Employee (requester signup flow)
	mux.HandleFunc("/egov-hrms/employees/_create", empHandler.CreateEmployee)

	// Individual
	mux.HandleFunc("/individual/v1/_search", indHandler.SearchIndividuals)

	// Debug catch-all
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[debug] unhandled route: %s %s", r.Method, r.URL.Path)
		http.NotFound(w, r)
	})

	// Wrap with CORS
	handler := corsMiddleware(mux)

	addr := ":" + cfg.Port
	log.Printf("[ok] Plotrol backend running on http://localhost%s", addr)
	log.Println("     Android emulator access: http://10.0.2.2:" + cfg.Port)
	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalf("[FATAL] Server failed: %v", err)
	}
}

// corsMiddleware allows cross-origin requests (needed for Flutter dev/emulator).
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Access-Control-Allow-Origin")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
