package com.salaboy.otelscore;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
        "spring.ai.anthropic.api-key=test-key",
        "management.opentelemetry.tracing.export.otlp.endpoint=http://test-endpoint",
        "management.opentelemetry.tracing.export.otlp.headers.Authorization=test-token",
        "management.opentelemetry.tracing.export.otlp.headers.Dash0-Dataset=test-dataset",
        "management.otlp.metrics.export.url=http://test-metrics-endpoint",
        "management.otlp.metrics.export.headers.Authorization=test-metrics-token",
        "management.otlp.metrics.export.headers.Dash0-Dataset=test-metrics-dataset",
        "management.opentelemetry.logging.export.otlp.endpoint=http://test-logging-endpoint",
        "management.opentelemetry.logging.export.headers.Authorization=test-logging-token",
        "management.opentelemetry.logging.export.headers.Dash0-Dataset=test-logging-dataset"


})
class OtelScoreApplicationTests {

    @Test
    void contextLoads() {
    }

}
