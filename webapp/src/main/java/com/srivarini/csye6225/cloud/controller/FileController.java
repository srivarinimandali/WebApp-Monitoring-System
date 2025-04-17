package com.srivarini.csye6225.cloud.controller;

import com.srivarini.csye6225.cloud.model.FileMetadata;
import com.srivarini.csye6225.cloud.service.MetricsService;
import com.srivarini.csye6225.cloud.service.S3Service;
import com.timgroup.statsd.StatsDClient;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/v1/file")
public class FileController {

    @Autowired
    private S3Service s3Service;

    @Autowired
    private MetricsService metricsService;

    private static final Logger logger = LoggerFactory.getLogger(FileController.class);

    @PostMapping
    public ResponseEntity<Map<String, Object>> uploadFile(@RequestParam("file") MultipartFile file, @RequestParam Map<String, String> queryParams, HttpServletRequest request) {
        logger.info("Received POST /v1/file request to upload a file.");
        long startTime = System.currentTimeMillis();
        metricsService.increment("controller.file.post.count");
        try {
            // Reject request if any extra query parameters are provided
            if (!queryParams.isEmpty()) {
                logger.warn("Upload failed: Query parameters are not allowed.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }

            // Check if multiple files were submitted
            if (request.getParts().stream().filter(part -> "file".equals(part.getName())).count() > 1) {
                logger.warn("Upload failed: Multiple file parts detected.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }
            // Handle case when file is empty (400 Bad Request)
            if (file == null || file.isEmpty()) {
                logger.warn("Upload failed: No file provided or file is empty.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }

            // Process file upload
            FileMetadata metadata = s3Service.uploadFile(file);
            if (metadata == null) { // Ensure a valid response from S3 service
                logger.error("Upload failed: Metadata was null or ID was not assigned.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }
            if (metadata.getId() == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }
            logger.info("File '{}' uploaded successfully with ID {}", metadata.getFileName(), metadata.getId());

            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                    "file_name", metadata.getFileName(),
                    "id", metadata.getId(),
                    "url", metadata.getFileUrl(),
                    "upload_date", metadata.getUploadDate().toString()
            ));
        } catch (IOException e) {
            // Handle S3 upload failure (400 Bad Request)
            logger.error("Upload failed due to I/O error: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (Exception e) {
            // Catch any unexpected issues and return 400 instead of 500
            logger.error("Unexpected error occurred while uploading file.", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }finally {
            metricsService.timing("controller.file.post.timer", System.currentTimeMillis() - startTime);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getFileMetadata(@PathVariable UUID id, @RequestParam Map<String, String> queryParams, @RequestBody(required = false) String requestBody) {
        logger.info("Received GET /v1/file/{} request to retrieve file metadata.", id);
        long startTime = System.currentTimeMillis();
        metricsService.increment("controller.file.get.count");

        try {
            if (!queryParams.isEmpty()) {
                logger.warn("Metadata retrieval failed: Query parameters not allowed.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }
            // Reject request if there is a request body
            if (requestBody != null && !requestBody.isEmpty()) {
                logger.warn("Metadata retrieval failed: Request body should be empty.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }

            Optional<FileMetadata> fileMetadata = s3Service.getFileMetadata(id);

            if (fileMetadata.isPresent()) {
                FileMetadata metadata = fileMetadata.get();
                Map<String, Object> response = new HashMap<>();
                response.put("file_name", metadata.getFileName());
                response.put("id", metadata.getId().toString());
                response.put("url", metadata.getFileUrl());
                response.put("upload_date", metadata.getUploadDate().toString());
                logger.info("Metadata retrieval successful for file ID {}", id);
                return ResponseEntity.ok(response);
            } else {
                logger.warn("File with ID {} not found.", id);
                return ResponseEntity.notFound().build();
            }
        } finally {
                metricsService.timing("controller.file.get.timer", System.currentTimeMillis() - startTime);
            }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteFile(@PathVariable UUID id, @RequestParam Map<String, String> queryParams, @RequestBody(required = false) String requestBody) {
        logger.info("Received DELETE /v1/file/{} request.", id);
        long startTime = System.currentTimeMillis();
        metricsService.increment("controller.file.delete.count");

        try {
            // Reject request if any query parameters are provided
            if (!queryParams.isEmpty()) {
                logger.warn("Delete request rejected: Query parameters are not allowed.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }

            // Reject request if there is a request body
            if (requestBody != null && !requestBody.isEmpty()) {
                logger.warn("Delete request rejected: Request body should be empty.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }

            boolean deleted = s3Service.deleteFile(id);
            if (deleted) {
                logger.info("File with ID {} deleted successfully.", id);
                return ResponseEntity.noContent().build();
            } else {
                logger.warn("Delete failed: File with ID {} not found.", id);
                return ResponseEntity.notFound().build();
            }
        }finally {
                metricsService.timing("controller.file.delete.timer", System.currentTimeMillis() - startTime);
            }
    }

    @GetMapping
    public ResponseEntity<String> unsupportedGetRequest() {
        logger.warn("Received unsupported GET request at /v1/file.");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    @DeleteMapping
    public ResponseEntity<String> unsupportedDeleteRequest() {
        logger.warn("Received unsupported DELETE request at /v1/file.");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle OPTIONS requests
    @RequestMapping(method = RequestMethod.OPTIONS)
    public ResponseEntity<Void> handleOptions() {
        logger.warn("Received unsupported OPTIONS request.");
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle PATCH requests explicitly
    @RequestMapping(method = RequestMethod.PATCH)
    public ResponseEntity<Void> handlePatch() {
        logger.warn("Received unsupported PATCH request.");
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle PUT requests explicitly
    @PutMapping
    public ResponseEntity<Void> handlePut() {
        logger.warn("Received unsupported PUT request.");
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle HEAD requests explicitly
    @RequestMapping(method = RequestMethod.HEAD)
    public ResponseEntity<Void> handleHead() {
        logger.warn("Received unsupported HEAD request.");
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle OPTIONS requests explicitly for /v1/file/{id}
    @RequestMapping(value = "/{id}", method = RequestMethod.OPTIONS)
    public ResponseEntity<Void> handleOptions(@PathVariable UUID id) {
        logger.warn("Received unsupported OPTIONS request for file ID {}", id);
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle PATCH requests explicitly for /v1/file/{id}
    @RequestMapping(value = "/{id}", method = RequestMethod.PATCH)
    public ResponseEntity<Void> handlePatch(@PathVariable UUID id) {
        logger.warn("Received unsupported PATCH request for file ID {}", id);
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle PUT requests explicitly for /v1/file/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Void> handlePutWithoutId(@PathVariable UUID id) {
        logger.warn("Received unsupported PUT request for file ID {}", id);
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle POST requests explicitly for /v1/file/{id} (invalid route)
    @PostMapping("/{id}")
    public ResponseEntity<Void> handlePostWithId(@PathVariable UUID id) {
        logger.warn("Received unsupported POST request for file ID {}", id);
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

    // Handle HEAD requests explicitly for /v1/file/{id}
    @RequestMapping(value = "/{id}", method = RequestMethod.HEAD)
    public ResponseEntity<Void> handleHead(@PathVariable UUID id) {
        logger.warn("Received unsupported HEAD request for file ID {}", id);
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
    }

}
