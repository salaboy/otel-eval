package com.salaboy.otelscore.traces;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.context.Context;
import jakarta.annotation.PostConstruct;
import org.springframework.boot.restclient.RestClientCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.support.ContextPropagatingTaskDecorator;
import reactor.core.publisher.Hooks;

@Configuration(proxyBeanMethods = false)
public class ContextPropagationConfiguration {

    @PostConstruct
    void enableReactorContextPropagation() {
        Hooks.enableAutomaticContextPropagation();  // bridges ThreadLocal → Reactor Context
    }

    @Bean
    ContextPropagatingTaskDecorator contextPropagatingTaskDecorator() {
        return new ContextPropagatingTaskDecorator();
    }

    @Bean
    RestClientCustomizer tracePropagationRestClientCustomizer(OpenTelemetry openTelemetry) {
        return builder -> builder.requestInterceptor((request, body, execution) -> {
            openTelemetry.getPropagators().getTextMapPropagator().inject(
                    Context.current(),
                    request.getHeaders(),
                    (headers, key, value) -> headers.set(key, value)
            );
            return execution.execute(request, body);
        });
    }

}
