package com.srivarini.csye6225.cloud.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

@Configuration
public class S3Config {
    private static final Logger logger = LoggerFactory.getLogger(S3Config.class);

    @Value("${AWS_S3_BUCKET_NAME}")
    private String bucketName;

    @Value("${AWS_REGION}")
    private String region;

    @Bean
    public S3Client s3Client() {
        logger.info("Initializing S3 client for region '{}'", region);
        try {
            S3Client s3Client = S3Client.builder()
                    .region(Region.of(region))
                    .credentialsProvider(DefaultCredentialsProvider.create())
                    .build();

            logger.info("S3 client initialized successfully.");
            return s3Client;
        } catch (Exception e) {
            logger.error("Failed to initialize S3 client", e);
            throw new RuntimeException("Failed to initialize S3 client", e);
        }
    }

    public String getBucketName() {
        return bucketName;
    }
}
