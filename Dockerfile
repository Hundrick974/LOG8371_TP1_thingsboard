# syntax=docker/dockerfile:1.6
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copie le jar construit par Maven (présent dans application/target/)
COPY application/target/*-boot.jar /app/thingsboard.jar

EXPOSE 8080 7070 1883 8883 5683-5688/udp

ENTRYPOINT ["java","-jar","/app/thingsboard.jar"]
