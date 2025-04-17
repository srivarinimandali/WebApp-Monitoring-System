package com.srivarini.csye6225.cloud.exception;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MultipartException;
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.io.IOException;
import java.sql.SQLException;

@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // Handle missing request parameters
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Void> handleMissingParameter(MissingServletRequestParameterException ex) {
        logger.warn("Missing request parameter: '{}'. Required type: {}", ex.getParameterName(), ex.getParameterType());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle file upload errors (invalid format, size issues)
    @ExceptionHandler(MultipartException.class)
    public ResponseEntity<Void> handleMultipartException(MultipartException ex) {
        logger.error("File upload failed due to multipart exception: {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle database errors (SQL issues)
    @ExceptionHandler({SQLException.class, DataAccessException.class})
    public ResponseEntity<Void> handleDatabaseExceptions(Exception ex) {
        logger.error("Database error occurred: {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle AWS S3 service errors
    @ExceptionHandler(S3Exception.class)
    public ResponseEntity<Void> handleS3Exception(S3Exception ex) {
        logger.error("AWS S3 error: {} - {}", ex.awsErrorDetails().errorCode(), ex.awsErrorDetails().errorMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle general AWS service exceptions
    @ExceptionHandler(AwsServiceException.class)
    public ResponseEntity<Void> handleAwsServiceException(AwsServiceException ex) {
        logger.error("AWS service exception: {} - {}", ex.awsErrorDetails().errorCode(), ex.awsErrorDetails().errorMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle AWS SDK client-side errors (e.g., network failures)
    @ExceptionHandler(SdkClientException.class)
    public ResponseEntity<Void> handleSdkClientException(SdkClientException ex) {
        logger.error("AWS SDK client error (likely a network or credentials issue): {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle invalid method arguments (e.g., incorrect UUID format in path variables)
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Void> handleMethodArgumentTypeMismatch(MethodArgumentTypeMismatchException ex) {
        logger.warn("Invalid argument received: parameter '{}', expected type '{}', value '{}'",
                ex.getName(), ex.getRequiredType(), ex.getValue(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle file-related I/O exceptions
    @ExceptionHandler(IOException.class)
    public ResponseEntity<Void> handleIOException(IOException ex) {
        logger.error("I/O error occurred while processing the request: {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Handle all uncaught runtime exceptions
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Void> handleRuntimeExceptions(RuntimeException ex) {
        logger.error("Unhandled runtime exception occurred: {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    // Catch-all handler for unexpected errors
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Void> handleAllExceptions(Exception ex) {
        logger.error("An unexpected error occurred while processing the request", ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }
}
