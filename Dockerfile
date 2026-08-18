FROM cirrusci/flutter:stable AS builder

WORKDIR /app

# Copy pubspec files first to cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the source and build the web release
COPY . ./
RUN flutter build web --release

FROM nginx:stable-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
