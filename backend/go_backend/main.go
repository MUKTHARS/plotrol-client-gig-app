package main

import (
	"log"
	"net/http"
	"os"

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

	// Run GORM AutoMigrate (creates all tables including new property tables)
	if err := db.RunMigrationsGORM(gormDB); err != nil {
		log.Fatalf("[FATAL] Migration failed: %v", err)
	}
	log.Println("[ok] GORM AutoMigrate applied")

	// Ensure uploads directory exists
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0o755); err != nil {
		log.Fatalf("[FATAL] Cannot create uploads dir: %v", err)
	}

	// ─── Handlers ─────────────────────────────────────────────────────────────
	// Existing handlers (unchanged – they receive *sql.DB as before)
	authHandler := handlers.NewAuthHandler(sqlDB, cfg)
	indHandler := handlers.NewIndividualHandler(sqlDB)
	empHandler := handlers.NewEmployeeHandler(sqlDB)

	// New property + filestore handlers (use *gorm.DB)
	propHandler := handlers.NewPropertyHandler(gormDB)
	fsHandler := handlers.NewFileStoreHandler(gormDB, uploadDir, cfg.BaseURL())
	pgrHandler := handlers.NewPGRHandler(gormDB)
	adminHandler := handlers.NewAdminHandler(gormDB, sqlDB, cfg)

	// ─── Gin router ───────────────────────────────────────────────────────────
	r := gin.Default()
	r.Use(corsMiddleware())

	// Serve files from database (binary data stored in file_data column)
	r.GET("/files/:filename", gin.WrapF(fsHandler.ServeFile))

	// Auth
	r.POST("/user/oauth/token", gin.WrapF(authHandler.Login))
	r.POST("/api/v1/tenants/createtenantuser", gin.WrapF(authHandler.CreateTenantUser))

	// Employee (requester signup flow)
	r.POST("/egov-hrms/employees/_create", gin.WrapF(empHandler.CreateEmployee))

	// Individual – search (existing) + create (new)
	r.POST("/individual/v1/_search", gin.WrapF(indHandler.SearchIndividuals))
	r.POST("/individual/v1/_create", gin.WrapF(propHandler.CreateIndividual))

	// Household
	r.POST("/household/v1/_create", gin.WrapF(propHandler.CreateHousehold))
	r.POST("/household/v1/_search", gin.WrapF(propHandler.SearchHouseholds))

	// Household member
	r.POST("/household/member/v1/_create", gin.WrapF(propHandler.CreateHouseholdMember))
	r.POST("/household/member/v1/_search", gin.WrapF(propHandler.SearchHouseholdMembers))

	// File store
	r.POST("/filestore/v1/files", gin.WrapF(fsHandler.UploadFiles))
	r.GET("/filestore/v1/files/url", gin.WrapF(fsHandler.GetFileURLs))

	// PGR service requests (orders)
	r.POST("/pgr-services/v2/request/_create", gin.WrapF(pgrHandler.CreateServiceRequest))
	r.POST("/pgr-services/v2/request/_search", gin.WrapF(pgrHandler.SearchServiceRequests))
	r.POST("/pgr-services/v2/request/_update", gin.WrapF(pgrHandler.UpdateServiceRequest))

	// Employee search & management (admin assigns gig workers)
	r.POST("/egov-hrms/employees/_search", gin.WrapF(adminHandler.SearchEmployees))
	r.POST("/egov-hrms/employees/_update", gin.WrapF(adminHandler.UpdateEmployee))
	r.POST("/egov-hrms/employees/_deactivate", gin.WrapF(adminHandler.DeactivateEmployee))

	// User profile search (used by HomeScreenController.getTenantApiFunction)
	r.POST("/user/_search", gin.WrapF(adminHandler.UserSearch))

	// Admin-only routes
	r.POST("/admin/create", gin.WrapF(adminHandler.CreateAdminUser))
	r.POST("/admin/helpdesk-users/_create", gin.WrapF(adminHandler.CreateHelpdeskUser))
	r.GET("/admin/dashboard/stats", gin.WrapF(adminHandler.GetAdminDashboardStats))
	r.POST("/admin/orders/_search", gin.WrapF(adminHandler.GetAdminOrders))
	r.GET("/admin/gig-workers/orders", gin.WrapF(adminHandler.GetGigWorkerOrders))

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
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, Access-Control-Allow-Origin, auth-token")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}
