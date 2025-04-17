package com.srivarini.csye6225.cloud.service;

import com.srivarini.csye6225.cloud.model.FileMetadata;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.Optional;
import java.util.UUID;

public interface S3Service {
    /**
     * Uploads a file to the configured AWS S3 bucket.
     * @param file MultipartFile object representing the file.
     * @return The URL of the uploaded file.
     * @throws IOException if file upload fails.
     */
    FileMetadata uploadFile(MultipartFile file) throws IOException;

    /**
     * Retrieves file metadata from the database.
     * @param id Unique identifier of the file.
     * @return Optional containing FileMetadata if found, otherwise empty.
     */
    Optional<FileMetadata> getFileMetadata(UUID id);

    /**
     * Deletes a file from the AWS S3 bucket and removes its metadata from the database.
     * @param id uuid of the file to delete.
     * @return True if deletion is successful, false if the file does not exist.
     */
    boolean deleteFile(UUID id);
}