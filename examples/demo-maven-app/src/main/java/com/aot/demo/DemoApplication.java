package com.aot.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@RestController
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/")
    public Map<String, String> hello() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello from Demo Maven App!");
        response.put("status", "running");
        response.put("language", "Java");
        response.put("framework", "Spring Boot");
        return response;
    }

    @GetMapping("/api/status")
    public Map<String, Object> status() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", "demo-maven-app");
        response.put("version", "1.0.0");
        response.put("java_version", System.getProperty("java.version"));
        response.put("uptime", System.currentTimeMillis());
        return response;
    }
}
