package com.srivarini.csye6225.cloud.service;

import com.timgroup.statsd.NonBlockingStatsDClient;
import com.timgroup.statsd.StatsDClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class MetricsService {

    private final StatsDClient statsd;

    public MetricsService(
            @Value("${metrics.prefix}") String prefix,
            @Value("${metrics.host}") String host,
            @Value("${metrics.port}") int port) {
        this.statsd = new NonBlockingStatsDClient(prefix, host, port);
    }

    /**
     * Increment a counter metric
     *
     * @param metric The metric name to increment
     */
    public void increment(String metric) {
        statsd.incrementCounter(metric);
    }

    /**
     * Record execution time for a timed operation
     *
     * @param metric The metric name to record
     * @param duration Duration in milliseconds
     */
    public void timing(String metric, long duration) {
        statsd.recordExecutionTime(metric, duration);
    }

}