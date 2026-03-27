package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	dbpkg "plotrol-backend/db"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// rewriteFileURL replaces the host in an absolute stored URL with the host
// the client used to reach us. Relative paths (no scheme/host) are returned
// unchanged — the client will prepend its own configured host.
func rewriteFileURL(storedURL, requestHost string) string {
	if storedURL == "" || requestHost == "" {
		return storedURL
	}
	u, err := url.Parse(storedURL)
	if err != nil {
		log.Printf("[filestore] rewriteFileURL: cannot parse %q: %v", storedURL, err)
		return storedURL
	}
	// Relative path (no scheme or host) — let the client resolve it using its
	// own configured host. Returning it unchanged is the safe choice.
	if u.Scheme == "" || u.Host == "" {
		return storedURL
	}
	// Absolute URL: rewrite host to the current request host.
	if u.Host != requestHost {
		original := u.Host
		u.Host = requestHost
		log.Printf("[filestore] rewriteFileURL: %q -> %q (host %s -> %s)", storedURL, u.String(), original, requestHost)
	}
	return u.String()
}

// FileStoreHandler handles file upload and URL fetch.
type FileStoreHandler struct {
	gdb       *gorm.DB
	uploadDir string // local directory to store files
	baseURL   string // public base URL, e.g. http://localhost:8080
}

func NewFileStoreHandler(gdb *gorm.DB, uploadDir, baseURL string) *FileStoreHandler {
	return &FileStoreHandler{gdb: gdb, uploadDir: uploadDir, baseURL: baseURL}
}

// POST /filestore/v1/files
// Flutter sends: multipart form with fields file[], tenantId, module
// Headers: auth-token: <token>
// Response (201): {"files": [{fileStoreId, name, tenantId, id, url}]}
func (h *FileStoreHandler) UploadFiles(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 32 MB max in memory
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{{"code": "INVALID_REQUEST", "message": "Cannot parse multipart form: " + err.Error()}},
		})
		return
	}

	tenantId := r.FormValue("tenantId")
	module := r.FormValue("module")

	files := r.MultipartForm.File["file"]
	if len(files) == 0 {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{{"code": "INVALID_REQUEST", "message": "No files uploaded"}},
		})
		return
	}

	results := make([]map[string]interface{}, 0, len(files))

	for _, fh := range files {
		src, err := fh.Open()
		if err != nil {
			log.Printf("[filestore] UploadFiles: cannot open file %s: %v", fh.Filename, err)
			continue
		}
		fileData, err := io.ReadAll(src)
		src.Close()
		if err != nil {
			log.Printf("[filestore] UploadFiles: cannot read file %s: %v", fh.Filename, err)
			continue
		}

		// Generate a unique store ID and build the URL path
		storeId := uuid.New().String()
		ext := filepath.Ext(fh.Filename)
		if ext == "" {
			ext = ".bin"
		}
		storedName := storeId + ext

		// Store only the relative path — no IP or host is ever saved.
		// The client prepends its own configured host at fetch time.
		storedURL := "/files/" + storedName

		rec := dbpkg.FileStore{
			FileStoreId: storeId,
			Name:        fh.Filename,
			TenantID:    tenantId,
			Module:      module,
			FilePath:    storedName, // kept as reference only
			URL:         storedURL,
			FileData:    fileData,  // binary stored in DB
		}
		if err := h.gdb.Create(&rec).Error; err != nil {
			log.Printf("[filestore] UploadFiles: DB insert failed for %s: %v", fh.Filename, err)
			continue
		}
		log.Printf("[filestore] UploadFiles: saved %s (%d bytes) as id=%s", fh.Filename, len(fileData), storeId)

		// Return URL rewritten to current request host
		responseURL := rewriteFileURL(storedURL, r.Host)
		results = append(results, map[string]interface{}{
			"fileStoreId": storeId,
			"name":        fh.Filename,
			"tenantId":    tenantId,
			"id":          storeId,
			"url":         responseURL,
		})
	}

	if len(results) == 0 {
		writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"Errors": []map[string]interface{}{{"code": "UPLOAD_FAILED", "message": "No files could be saved"}},
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 — Flutter checks statusCode == 201
	json.NewEncoder(w).Encode(map[string]interface{}{"files": results})
}

// GET /filestore/v1/files/url?tenantId=mz&fileStoreIds=id1,id2
func (h *FileStoreHandler) GetFileURLs(w http.ResponseWriter, r *http.Request) {
	log.Println("[filestore] === GetFileURLs called ===")
	log.Printf("[filestore] RequestHost=%q URL=%s", r.Host, r.URL.String())

	rawIds := r.URL.Query().Get("fileStoreIds")
	if rawIds == "" {
		log.Println("[filestore] GetFileURLs: no fileStoreIds param, returning empty list")
		writeJSON(w, http.StatusOK, map[string]interface{}{"fileStoreIds": []interface{}{}})
		return
	}

	ids := strings.Split(rawIds, ",")
	log.Printf("[filestore] GetFileURLs: querying %d IDs: %v", len(ids), ids)

	var records []dbpkg.FileStore
	h.gdb.Where("file_store_id IN ?", ids).Find(&records)
	log.Printf("[filestore] GetFileURLs: found %d DB records for %d requested IDs", len(records), len(ids))

	list := make([]map[string]interface{}, 0, len(records))
	for _, rec := range records {
		// Rewrite the stored URL so the device can reach the file.
		// Stored URLs have "localhost" (from BASE_URL default); the device
		// (emulator or real phone) must use the actual host it connected to.
		rewritten := rewriteFileURL(rec.URL, r.Host)
		log.Printf("[filestore] GetFileURLs: id=%s storedURL=%q returnURL=%q", rec.FileStoreId, rec.URL, rewritten)
		list = append(list, map[string]interface{}{
			"fileStoreId": rec.FileStoreId,
			"name":        rec.Name,
			"tenantId":    rec.TenantID,
			"id":          rec.FileStoreId,
			"url":         rewritten,
		})
	}

	log.Printf("[filestore] GetFileURLs: returning %d file records", len(list))
	writeJSON(w, http.StatusOK, map[string]interface{}{"fileStoreIds": list})
}

// GET /files/:uuid.ext
// Serves file binary data stored in the database.
func (h *FileStoreHandler) ServeFile(w http.ResponseWriter, r *http.Request) {
	// Extract filename from path: /files/uuid.ext
	filename := filepath.Base(r.URL.Path)
	if filename == "" || filename == "." {
		http.NotFound(w, r)
		return
	}

	ext := filepath.Ext(filename)
	fileStoreId := strings.TrimSuffix(filename, ext)

	log.Printf("[filestore] ServeFile: id=%s ext=%s", fileStoreId, ext)

	var rec dbpkg.FileStore
	if err := h.gdb.Where("file_store_id = ?", fileStoreId).First(&rec).Error; err != nil {
		log.Printf("[filestore] ServeFile: id=%s not found in DB: %v", fileStoreId, err)
		http.NotFound(w, r)
		return
	}

	fileData := rec.FileData
	if len(fileData) == 0 {
		// Fallback: binary may not have been stored in DB yet (legacy uploads
		// written to disk before the DB-binary approach was introduced).
		diskPath := filepath.Join(h.uploadDir, rec.FilePath)
		data, err := os.ReadFile(diskPath)
		if err != nil {
			log.Printf("[filestore] ServeFile: id=%s — no binary in DB and disk read failed (%s): %v", fileStoreId, diskPath, err)
			http.Error(w, "file data not available", http.StatusNotFound)
			return
		}
		log.Printf("[filestore] ServeFile: id=%s — served from disk fallback (%s)", fileStoreId, diskPath)
		fileData = data
	}

	// Detect content type from extension, fallback to sniffing bytes
	contentType := mime.TypeByExtension(ext)
	if contentType == "" {
		contentType = http.DetectContentType(fileData)
	}

	log.Printf("[filestore] ServeFile: serving id=%s name=%s size=%d contentType=%s", fileStoreId, rec.Name, len(fileData), contentType)

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Length", fmt.Sprintf("%d", len(fileData)))
	w.Header().Set("Cache-Control", "public, max-age=86400")
	w.WriteHeader(http.StatusOK)
	w.Write(fileData)
}
