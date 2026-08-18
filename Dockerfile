FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa openjdk-11-jdk ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (stable)
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:$PATH"

WORKDIR /app

# Cache pub packages by copying only the pubspec files first
COPY pubspec.* /app/ 2>/dev/null || true
RUN flutter pub get || true

# Copy source and build web release
COPY . /app
RUN flutter build web --release || true

FROM nginx:stable-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
