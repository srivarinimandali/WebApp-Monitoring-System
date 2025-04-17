package com.srivarini.csye6225.cloud.service;

import com.srivarini.csye6225.cloud.config.S3Config;
import com.srivarini.csye6225.cloud.model.FileMetadata;
import com.srivarini.csye6225.cloud.repository.FileMetadataRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class S3ServiceImpl implements S3Service {
    private static final Logger logger = LoggerFactory.getLogger(S3ServiceImpl.class);

    @Autowired
    private S3Config s3Config;

    @Autowired
    private S3Client s3Client;

    @Autowired
    private FileMetadataRepository fileMetadataRepository;
    @Autowired
    private MetricsService metricsService;

    @Override
    public FileMetadata uploadFile(MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String fileName = UUID.randomUUID().toString() + "-" + file.getOriginalFilename();
        String fileUrl = "https://" + s3Config.getBucketName() + ".s3.amazonaws.com/" + fileName;
        logger.info("Uploading file '{}' to S3 bucket '{}'", originalFilename, s3Config.getBucketName());
        long s3Start = System.currentTimeMillis();
        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(s3Config.getBucketName())
                    .key(fileName)
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromBytes(file.getBytes()));
        } catch (IOException e) {
            logger.error("Failed to read file bytes for '{}'", originalFilename, e);
            throw e;
        } catch (Exception e) {
            logger.error("Error occurred while uploading file '{}' to S3", originalFilename, e);
            throw new RuntimeException("S3 upload failed", e);
        } finally {
            metricsService.timing("service.s3.upload.timer", System.currentTimeMillis() - s3Start);
        }
        long dbStart = System.currentTimeMillis();
        try {
            // Save metadata (JPA assigns ID)
            FileMetadata metadata = new FileMetadata(fileName, fileUrl, LocalDateTime.now());
            FileMetadata savedMetadata = fileMetadataRepository.save(metadata); // Fetch the saved entity with ID
            logger.info("File '{}' uploaded successfully. S3 URL: {}", fileName, fileUrl);
            return savedMetadata;
        }finally {
            metricsService.timing("service.db.filemetadata.insert.timer", System.currentTimeMillis() - dbStart);
        }

    }

    @Override
    public Optional<FileMetadata> getFileMetadata(UUID id) {
        logger.info("Retrieving metadata for file ID: {}", id);
        return fileMetadataRepository.findById(id);
    }

    @Override
    public boolean deleteFile(UUID id) {
        logger.info("Attempting to delete file with ID: {}", id);
        Optional<FileMetadata> fileMetadata = fileMetadataRepository.findById(id);
        if (fileMetadata.isPresent())
        {
            String fileName = fileMetadata.get().getFileName();
            long s3Start = System.currentTimeMillis();

            try
            {
            DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                    .bucket(s3Config.getBucketName())
                    .key(fileMetadata.get().getFileName())
                    .build();
            s3Client.deleteObject(deleteObjectRequest);
            } catch (Exception e) {
                logger.error("Error occurred while deleting file '{}' from S3", fileName, e);
                return false;
            } finally {
                metricsService.timing("service.s3.delete.timer", System.currentTimeMillis() - s3Start);
            }
            long dbStart = System.currentTimeMillis();
            try {
            fileMetadataRepository.delete(fileMetadata.get());
            logger.info("Successfully deleted file '{}' from S3 and database.", fileName);

            return true;
            }finally {
                metricsService.timing("service.db.filemetadata.delete.timer", System.currentTimeMillis() - dbStart);
            }
        }
        else {
            logger.warn("File with ID {} not found in metadata repository.", id);
            return false;
        }
    }
}