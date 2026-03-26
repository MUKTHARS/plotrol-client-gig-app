package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	dbpkg "plotrol-backend/db"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// rewriteFileURL replaces the host in a stored URL with the host that the
// client actually used to reach us.  This is critical for Android emulators
// (host = 10.0.2.2) and real devices on Wi-Fi (host = LAN IP) because the
// backend is started with BASE_URL=http://localhost:8080 by default, so
// stored URLs contain "localhost" which is unreachable from any non-host OS.
func rewriteFileURL(storedURL, requestHost string) string {
	if storedURL == "" || requestHost == "" {
		return storedURL
	}
	u, err := url.Parse(storedURL)
	if err != nil {
		log.Printf("[filestore] rewriteFileURL: cannot parse %q: %v", storedURL, err)
		return storedURL
	}
	// Only rewrite when the stored URL points to localhost / 127.0.0.1
	h := strings.ToLower(u.Hostname())
	if h == "localhost" || h == "127.0.0.1" {
		original := u.Host
		u.Host = requestHost
		log.Printf("[filestore] rewriteFileURL: %q -> %q (host %s -> %s)", storedURL, u.String(), original, requestHost)
		return u.String()
	}
	return storedURL
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
		// Generate a unique store ID
		storeId := uuid.New().String()

		// Preserve original extension
		ext := filepath.Ext(fh.Filename)
		if ext == "" {
			ext = ".bin"
		}
		storedName := storeId + ext
		destPath := filepath.Join(h.uploadDir, storedName)

		src, err := fh.Open()
		if err != nil {
			continue
		}

		dst, err := os.Create(destPath)
		if err != nil {
			src.Close()
			continue
		}

		if _, err := io.Copy(dst, src); err != nil {
			src.Close()
			dst.Close()
			continue
		}
		src.Close()
		dst.Close()

		// Public URL: baseURL/files/<storedName>
		publicURL := fmt.Sprintf("%s/files/%s", strings.TrimRight(h.baseURL, "/"), storedName)

		rec := dbpkg.FileStore{
			FileStoreId: storeId,
			Name:        fh.Filename,
			TenantID:    tenantId,
			Module:      module,
			FilePath:    destPath,
			URL:         publicURL,
		}
		h.gdb.Create(&rec)

		results = append(results, map[string]interface{}{
			"fileStoreId": storeId,
			"name":        fh.Filename,
			"tenantId":    tenantId,
			"id":          storeId,
			"url":         publicURL,
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
