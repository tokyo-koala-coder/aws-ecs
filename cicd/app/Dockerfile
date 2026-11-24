FROM docker.io/library/amazoncorretto:17-alpine-jdk
WORKDIR /app
COPY app.jar app.jar
USER 10001:10001
EXPOSE 8080

# Leave memory for JVM native allocations in the 512 MiB task.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=50.0", "-jar", "/app/app.jar"]
