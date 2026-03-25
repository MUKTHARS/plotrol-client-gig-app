package main

import (
	"log"
	"net/http"

	"plotrol-backend/config"
	"plotrol-backend/db"
	"plotrol-backend/handlers"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env (ignore error if file not present – env vars may already be set)
	if err := godotenv.Load(); err != nil {
		log.Println("[warn] no .env file found; falling back to OS environment variables")
	}

	cfg := config.Load()

	// Connect via GORM (creates database if it doesn't exist)
	gormDB, err := db.ConnectGORM(cfg)
	if err != nil {
		log.Fatalf("[FATAL] Database connection failed: %v\n\nMake sure PostgreSQL is running on %s:%s",
			err, cfg.DBHost, cfg.DBPort)
	}

	// Get the underlying *sql.DB so existing handlers work without changes
	sqlDB, err := gormDB.DB()
	if err != nil {
		log.Fatalf("[FATAL] Failed to obtain sql.DB from GORM: %v", err)
	}
	defer sqlDB.Close()
	log.Printf("[ok] Connected to PostgreSQL via GORM – database: %s", cfg.DBName)

	// Run GORM AutoMigrate
	if err := db.RunMigrationsGORM(gormDB); err != nil {
		log.Fatalf("[FATAL] Migration failed: %v", err)
	}
	log.Println("[ok] GORM AutoMigrate applied")

	// Build handlers (unchanged – they receive *sql.DB as before)
	authHandler := handlers.NewAuthHandler(sqlDB, cfg)
	indHandler := handlers.NewIndividualHandler(sqlDB)
	empHandler := handlers.NewEmployeeHandler(sqlDB)

	// Gin router
	r := gin.Default()
	r.Use(corsMiddleware())

	// Auth
	r.POST("/user/oauth/token", gin.WrapF(authHandler.Login))
	r.POST("/api/v1/tenants/createtenantuser", gin.WrapF(authHandler.CreateTenantUser))

	// Employee (requester signup flow)
	r.POST("/egov-hrms/employees/_create", gin.WrapF(empHandler.CreateEmployee))

	// Individual
	r.POST("/individual/v1/_search", gin.WrapF(indHandler.SearchIndividuals))

	// Debug catch-all
	r.NoRoute(func(c *gin.Context) {
		log.Printf("[debug] unhandled route: %s %s", c.Request.Method, c.Request.URL.Path)
		c.Status(http.StatusNotFound)
	})

	addr := ":" + cfg.Port
	log.Printf("[ok] Plotrol backend running on http://localhost%s", addr)
	log.Println("     Android emulator access: http://10.0.2.2:" + cfg.Port)
	if err := r.Run(addr); err != nil {
		log.Fatalf("[FATAL] Server failed: %v", err)
	}
}

// corsMiddleware allows cross-origin requests (needed for Flutter dev/emulator).
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, Access-Control-Allow-Origin")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}
