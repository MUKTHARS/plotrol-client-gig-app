package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	dbpkg "plotrol-backend/db"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

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
	rawIds := r.URL.Query().Get("fileStoreIds")
	if rawIds == "" {
		writeJSON(w, http.StatusOK, map[string]interface{}{"fileStoreIds": []interface{}{}})
		return
	}

	ids := strings.Split(rawIds, ",")
	var records []dbpkg.FileStore
	h.gdb.Where("file_store_id IN ?", ids).Find(&records)

	list := make([]map[string]interface{}, 0, len(records))
	for _, rec := range records {
		list = append(list, map[string]interface{}{
			"fileStoreId": rec.FileStoreId,
			"name":        rec.Name,
			"tenantId":    rec.TenantID,
			"id":          rec.FileStoreId,
			"url":         rec.URL,
		})
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"fileStoreIds": list})
}
