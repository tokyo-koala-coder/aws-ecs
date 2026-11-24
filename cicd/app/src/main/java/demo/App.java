package demo;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public final class App {
    public static void main(String[] args) throws IOException {
        HttpServer server = start(8080);
        System.out.println("Demo HTTP server listening on port " + server.getAddress().getPort());
    }

    static HttpServer start(int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", App::handle);
        server.start();
        return server;
    }

    private static void handle(HttpExchange exchange) throws IOException {
        try (exchange) {
            String path = exchange.getRequestURI().getPath();
            String body = switch (path) {
                case "/" -> "Hello from ECS Fargate\n";

                // The ECS task definition probes this endpoint from inside the container.
                case "/health" -> "OK\n";
                default -> "Not found\n";
            };
            int status = path.equals("/") || path.equals("/health") ? 200 : 404;
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
            exchange.sendResponseHeaders(status, bytes.length);
            exchange.getResponseBody().write(bytes);
        }
    }
}
