package com.srivarini.csye6225.cloud.service;

import com.srivarini.csye6225.cloud.model.HealthStatus;
import com.srivarini.csye6225.cloud.repository.HealthStatusRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Service
public class HealthStatusServiceImpl implements HealthStatusService{

    @Autowired
    private DataSource dataSource;
    @Autowired
    private HealthStatusRepository healthStatusRepository;
    @Autowired
    private MetricsService metricsService;
    private static final Logger logger = LoggerFactory.getLogger(HealthStatusServiceImpl.class);

    // Validates the database connectivity and inserts a record into the health_status table.
    // Returns true if the database is healthy, false otherwise
    public boolean performHealthCheck() {
        try {
            if (!isDatabaseConnectionValid()) {
                logger.warn("Health check failed: Database connection invalid.");
                return false;
            }
            return insertHealthCheckRecord();
        } catch (Exception e) {
            logger.error("Error during health check operation", e);
            return false;
        }
    }

    // Validates the database connection by executing a simple query.
    // Returns true if the connection is valid, false otherwise
    private boolean isDatabaseConnectionValid() {
        long startTime = System.currentTimeMillis();

        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement("SELECT 1");
             ResultSet resultSet = statement.executeQuery()) {

            if (resultSet.next()) {
                logger.info("Database connection validated successfully.");
                return true;
            } else {
                logger.error("Database validation failed: SELECT 1 returned no rows.");
                return false;
            }
        } catch (SQLException e) {
            logger.error("Failed to validate database connection",e);
            return false;
        }finally {
            metricsService.timing("service.db.health.select.timer", System.currentTimeMillis() - startTime);
        }
    }

    // Inserts a health check record into the database.
    // Returns true if the record was inserted successfully, false otherwise
    private boolean insertHealthCheckRecord() {
        long startTime = System.currentTimeMillis();

        try {
            HealthStatus healthStatus = new HealthStatus();
            healthStatus.setDatetime(LocalDateTime.now(ZoneOffset.UTC));
            healthStatusRepository.save(healthStatus);

            logger.info("Health check record inserted successfully.");
            return true;
        } catch (Exception e) {
            logger.error("Failed to insert health check record", e);
            return false;
        }finally {
            metricsService.timing("service.db.health.insert.timer", System.currentTimeMillis() - startTime);
        }
    }
}
