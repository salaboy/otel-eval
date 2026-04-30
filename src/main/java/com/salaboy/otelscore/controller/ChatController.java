package com.salaboy.otelscore.controller;

import com.salaboy.otelscore.model.ChatRequest;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.InMemoryChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatClient chatClient;

    private final InMemoryChatMemoryRepository memoryRepository = new InMemoryChatMemoryRepository();

    public ChatController(ChatClient chatClient) {
        this.chatClient = chatClient;
    }

    @PostMapping(produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> chat(@RequestBody ChatRequest request) {
        MessageChatMemoryAdvisor advisor = MessageChatMemoryAdvisor.builder(
                        MessageWindowChatMemory.builder()
                                .chatMemoryRepository(memoryRepository)
                                .build())
                .conversationId(request.conversationId())
                .build();

        StringBuilder userPrompt = new StringBuilder();
        userPrompt.append("The CNCF project to evaluate is: ")
                .append(request.projectName())
                .append(" (").append(request.projectUrl()).append(").\n");


        userPrompt.append("Check if a previous installation run exists at: ")
                .append("results/").append(request.projectName())
                .append(". Review the installation steps in ")
                .append("results/")
                .append(request.projectName())
                .append("/INSTALL-PLAN.md before proceeding.\n");


        userPrompt.append(request.message());

        return chatClient.prompt()
                .advisors(advisor)
                .system("The Kubernetes cluster to use for this evaluation is: " + request.clusterName())
                .user(userPrompt.toString())
                .stream()
                .content();
    }
}
