package com.srivarini.csye6225.cloud.controller;

import com.srivarini.csye6225.cloud.service.HealthStatusServiceImpl;
import com.srivarini.csye6225.cloud.service.MetricsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/healthz")
public class HealthStatusController {

    private static final Logger logger = LoggerFactory.getLogger(HealthStatusController.class);

    @Autowired
    private HealthStatusServiceImpl service;
    @Autowired
    private MetricsService metricsService;
    // Validating the health of application.
    @GetMapping
    public ResponseEntity<Void> healthCheck(@RequestParam Map<String, String> allParams,
                                            @RequestBody(required = false) String payload) {
        long startTime = System.currentTimeMillis();
        metricsService.increment("controller.health.get.count");
        // Check for unwanted query parameters
        if (!allParams.isEmpty()) {
            logger.warn("Query parameters received in GET request, rejecting with 400 Bad Request");
            return ResponseEntity.badRequest()
                    .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                    .header("Pragma", "no-cache")
                    .header("X-Content-Type-Options", "nosniff")
                    .build();
        }
        if (payload != null && !payload.isEmpty()) {
            logger.warn("Payload received in GET request, rejecting with 400 Bad Request");
            return ResponseEntity.badRequest()
                    .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                    .header("Pragma", "no-cache")
                    .header("X-Content-Type-Options", "nosniff")
                    .build();
        }

        // returns 200 OK if success else 503 service unavailable
        try {
            boolean isHealthy = service.performHealthCheck();
            if (isHealthy) {
                logger.info("Health check successful");
                return ResponseEntity.ok()
                        .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                        .header("Pragma", "no-cache")
                        .header("X-Content-Type-Options", "nosniff")
                        .build();
            } else {
                logger.error("Health check failed due to database connectivity issue");
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                        .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                        .header("Pragma", "no-cache")
                        .header("X-Content-Type-Options", "nosniff")
                        .build();
            }
        }
        catch (Exception e) {
            logger.error("Unexpected error during health check", e);
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                    .header("Pragma", "no-cache")
                    .header("X-Content-Type-Options", "nosniff")
                    .build();
        }finally {
            metricsService.timing("controller.health.get.timer", System.currentTimeMillis() - startTime);
        }
    }

    // Handles Unsupported HTTP Methods
    // Returns 405 Method Not Allowed for non-GET methods.
    @RequestMapping(method = {
            RequestMethod.POST,
            RequestMethod.PUT,
            RequestMethod.DELETE,
            RequestMethod.PATCH,
            RequestMethod.HEAD,
            RequestMethod.OPTIONS
    })
    public ResponseEntity<Void> handleMethodNotAllowed() {
        logger.warn("Unsupported HTTP method received");
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
                .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                .header("Pragma", "no-cache")
                .header("X-Content-Type-Options", "nosniff")
                .build();
    }
}
