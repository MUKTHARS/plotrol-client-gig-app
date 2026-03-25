package config

import "os"

type Config struct {
	Port      string
	DBHost    string
	DBPort    string
	DBUser    string
	DBPass    string
	DBName    string
	JWTSecret string
}

func Load() *Config {
	return &Config{
		Port:      getEnv("PORT", "8080"),
		DBHost:    getEnv("DB_HOST", "localhost"),
		DBPort:    getEnv("DB_PORT", "3306"),
		DBUser:    getEnv("DB_USER", "root"),
		DBPass:    getEnv("DB_PASSWORD", ""),
		DBName:    getEnv("DB_NAME", "plotrol_new"),
		JWTSecret: getEnv("JWT_SECRET", "plotrol-jwt-secret-key-2024"),
	}
}

// BaseURL returns the public base URL for this server (used to build file URLs).
func (c *Config) BaseURL() string {
	if v := os.Getenv("BASE_URL"); v != "" {
		return v
	}
	return "http://localhost:" + c.Port
}

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}
