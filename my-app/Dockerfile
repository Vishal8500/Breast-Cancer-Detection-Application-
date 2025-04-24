# Build stage
FROM node:18 AS build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with specific npm version
RUN npm install -g npm@9.8.1
RUN npm install

# Copy project files
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:1.21-alpine

# Copy built assets from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create required nginx directories and set permissions
RUN mkdir -p /var/cache/nginx \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/run \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /var/run \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chmod -R 755 /var/cache/nginx \
    && chmod -R 755 /var/log/nginx \
    && chmod -R 755 /var/run \
    && chmod -R 755 /usr/share/nginx/html

# Remove default nginx user directive since we're running as non-root
RUN sed -i '/user  nginx;/d' /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]