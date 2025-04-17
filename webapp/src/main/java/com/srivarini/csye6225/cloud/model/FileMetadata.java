package com.srivarini.csye6225.cloud.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "file_metadata")
public class FileMetadata {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String fileName;

    @Column(nullable = false)
    private String fileUrl;

    @Column(nullable = false)
    private LocalDateTime uploadDate;

    public FileMetadata() {}

    public FileMetadata(String fileName, String fileUrl, LocalDateTime uploadDate) {
        this.fileName = fileName;
        this.fileUrl = fileUrl;
        this.uploadDate = uploadDate;
    }

    public UUID getId() { return id; }
    public String getFileName() { return fileName; }
    public String getFileUrl() { return fileUrl; }
    public LocalDateTime getUploadDate() { return uploadDate; }

}