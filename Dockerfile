version: '3.8'

services:
  app-staging:
    build:
      context: .
      args:
        PROFILE: staging
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=staging
      - DB_URL=jdbc:mysql://db-staging:3306/myapp
      - DB_USERNAME=staging_user
      - DB_PASSWORD=staging_pass
    depends_on:
      - db-staging

  app-production:
    build:
      context: .
      args:
        PROFILE: production
    ports:
      - "80:80"
    environment:
      - SPRING_PROFILES_ACTIVE=production
      - SERVER_PORT=80
      - DB_URL=jdbc:mysql://db-production:3306/myapp
      - DB_USERNAME=prod_user
      - DB_PASSWORD=prod_pass
    depends_on:
      - db-production

  db-staging:
    image: mysql:8.0
    environment:
      - MYSQL_DATABASE=myapp
      - MYSQL_USER=staging_user
      - MYSQL_PASSWORD=staging_pass
      - MYSQL_ROOT_PASSWORD=root_password
    ports:
      - "3306:3306"

  db-production:
    image: mysql:8.0
    environment:
      - MYSQL_DATABASE=myapp
      - MYSQL_USER=prod_user
      - MYSQL_PASSWORD=prod_pass
      - MYSQL_ROOT_PASSWORD=root_password
    ports:
      - "3307:3306"