package com.srivarini.csye6225.cloud.repository;

import com.srivarini.csye6225.cloud.model.HealthStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HealthStatusRepository extends JpaRepository<HealthStatus, Long> {
}
