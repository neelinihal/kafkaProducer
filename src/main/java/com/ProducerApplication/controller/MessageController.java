package com.ProducerApplication.controller;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class MessageController {

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${KAFKA_TOPIC:test-topic}")
    private String topic;

    public MessageController(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @PostMapping("/send")
    public String send(@RequestParam String message) {
        kafkaTemplate.send(topic, message);
        return "Sent: " + message;
    }
}
