# -------- Stage 1: Build JAR with Maven --------
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /home/app

# Copy pom.xml and download dependencies (caching layer)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source code
COPY src ./src

# Build application JAR (skip tests for faster image builds)
RUN mvn clean package -DskipTests

# -------- Stage 2: Run JAR with Temurin JDK --------
FROM eclipse-temurin:21-jdk
WORKDIR /home/app

# Copy built JAR from build stage
COPY --from=build /home/app/target/*.jar app.jar

# Expose application port
EXPOSE 5000

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
