package com.srivarini.csye6225.cloud.repository;

import com.srivarini.csye6225.cloud.model.FileMetadata;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface FileMetadataRepository extends JpaRepository<FileMetadata, UUID> {
    Optional<FileMetadata> findByFileName(String fileName);
}