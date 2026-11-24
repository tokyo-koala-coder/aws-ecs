package demo;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.sun.net.httpserver.HttpServer;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AppTest {
    private final HttpClient client = HttpClient.newHttpClient();
    private HttpServer server;

    @BeforeEach
    void startServer() throws Exception {
        server = App.start(0);
    }

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void servesGreeting() throws Exception {
        HttpResponse<String> response = get("/");
        assertEquals(200, response.statusCode());
        assertEquals("Hello from ECS Fargate\n", response.body());
    }

    @Test
    void servesHealth() throws Exception {
        HttpResponse<String> response = get("/health");
        assertEquals(200, response.statusCode());
        assertEquals("OK\n", response.body());
    }

    @Test
    void rejectsUnknownPath() throws Exception {
        assertEquals(404, get("/health/other").statusCode());
    }

    private HttpResponse<String> get(String path) throws Exception {
        URI uri = URI.create("http://127.0.0.1:" + server.getAddress().getPort() + path);
        return client.send(HttpRequest.newBuilder(uri).build(), HttpResponse.BodyHandlers.ofString());
    }
}
