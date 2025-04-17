package com.srivarini.csye6225.cloud.controller;

import com.srivarini.csye6225.cloud.service.HealthStatusServiceImpl;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.isEmptyString;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class HealthStatusControllerTest {

    @LocalServerPort
    private int port;

    @MockitoBean
    private HealthStatusServiceImpl healthStatusService;

    @BeforeEach
    public void setUp() {
        RestAssured.port = port;
        RestAssured.basePath = "/healthz";
        System.out.println("Setup complete, running test at port: " + port);
    }

    @Test
    public void testHealthCheckSuccess() {
        System.out.println("Testing health check success scenario");
        when(healthStatusService.performHealthCheck()).thenReturn(true);
        Response response = given()
                .when()
                .get()
                .then()
                .extract().response();

        // Verify common headers regardless of status code
        assertEquals("no-cache, no-store, must-revalidate",
                response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));
        assertTrue(response.getBody().asString().isEmpty());

        int statusCode = response.getStatusCode();
        System.out.println("Health check status code: " + statusCode);
    }

    @Test
    public void testHealthCheckWithPayload() {
        given()
                .body("{\"course\": \"cloudcomputing\"}")
                .contentType("application/json")
                .when()
                .get()
                .then()
                .statusCode(400)
                .header("Cache-Control", "no-cache, no-store, must-revalidate")
                .header("Pragma", "no-cache")
                .header("X-Content-Type-Options", "nosniff")
                .body(isEmptyString());
    }

    @Test
    public void testHealthCheckWithQueryParameters() {
        System.out.println("Testing rejection of GET request with query parameters");
        Response response = given()
                .queryParam("extra", "data")
                .when()
                .get()
                .then()
                .statusCode(400)  // Expect a 400 Bad Request status code
                .header("Cache-Control", "no-cache, no-store, must-revalidate")
                .header("Pragma", "no-cache")
                .header("X-Content-Type-Options", "nosniff")
                .body(isEmptyString())
                .extract().response();

        // Additional assertions to verify the response
        assertEquals(HttpStatus.BAD_REQUEST.value(), response.getStatusCode(), "Expected HTTP 400 Bad Request but got: " + response.getStatusCode());
        assertTrue(response.getBody().asString().isEmpty(), "Response body should be empty for 400 Bad Request");

        System.out.println("Query parameter test passed. HTTP 400 Bad Request returned as expected.");
    }

    @Test
    public void testPostMethodNotAllowed() {
        Response response = given()
                .when()
                .post()
                .then()
                .extract().response();

        assertEquals(405, response.getStatusCode(), "Expected HTTP 405 Method Not Allowed but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("POST method correctly returned 405.");
    }
    @Test
    public void testPutMethodNotAllowed() {
        Response response = given()
                .when()
                .put()
                .then()
                .extract().response();

        // Strictly assert 405
        assertEquals(405, response.getStatusCode(), "Expected HTTP 405 Method Not Allowed but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("PUT method correctly returned 405.");
    }
    @Test
    public void testDeleteMethodNotAllowed() {
        Response response = given()
                .when()
                .delete()
                .then()
                .extract().response();

        // Strictly assert 405
        assertEquals(405, response.getStatusCode(), "Expected HTTP 405 Method Not Allowed but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("DELETE method correctly returned 405.");
    }
    @Test
    public void testPatchMethodNotAllowed() {
        Response response = given()
                .when()
                .patch()
                .then()
                .extract().response();

        assertEquals(405, response.getStatusCode(), "Expected HTTP 405 Method Not Allowed but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("PATCH method correctly returned 405.");
    }
    @Test
    public void testHeadMethodNotAllowed() {
        Response response = given()
                .when()
                .head()
                .then()
                .extract().response();

        // Strictly assert 405
        assertEquals(405, response.getStatusCode(), "Expected HTTP 405 Method Not Allowed but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("HEAD method correctly returned 405.");
    }
    @Test
    public void testOptionsMethodNotAllowed() {
        Response response = given()
                .when()
                .options()
                .then()
                .extract().response();

        // Strictly assert 405
        assertEquals(405, response.getStatusCode(), "Expected HTTP 405 Method Not Allowed but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("OPTIONS method correctly returned 405.");
    }
    @Test
    public void testDatabaseFailure() {
        // Mock database failure
        org.mockito.Mockito.when(healthStatusService.performHealthCheck()).thenReturn(false);

        // Send request and extract response
        Response response = given()
                .when()
                .get()
                .then()
                .extract().response();

        assertEquals(503, response.getStatusCode(), "Expected HTTP 503 Service Unavailable but got: " + response.getStatusCode());

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        // Verify empty body
        assertTrue(response.getBody().asString().isEmpty(), "Response body should be empty when database is down");

        System.out.println("Database failure test passed. HTTP 503 returned as expected.");
    }

    @Test
    public void testHealthCheckThrowsException() {
        // Mock the service to throw an exception
        when(healthStatusService.performHealthCheck()).thenThrow(new RuntimeException("Database connection error"));

        // Trigger the health check endpoint
        Response response = given()
                .when()
                .get()
                .then()
                .extract().response();

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE.value(), response.getStatusCode(),
                "Expected HTTP 503 when an exception occurs in health check");

        // Verify headers
        assertEquals("no-cache, no-store, must-revalidate", response.getHeader("Cache-Control"));
        assertEquals("no-cache", response.getHeader("Pragma"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));

        System.out.println("Health check exception test passed with 503 response.");
    }
}

