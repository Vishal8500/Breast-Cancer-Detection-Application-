# Build stage for React frontend
FROM node:18 AS frontend-build
WORKDIR /app/frontend
COPY my-app/package*.json ./
RUN npm install -g npm@9.8.1 && npm install
COPY my-app/ .
RUN npm run build

# Build stage for Python backend
FROM python:3.9-slim AS backend-build
WORKDIR /app/backend
COPY BACKEND/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN apt-get update && \
    apt-get install -y wget && \
    pip install gdown && \
    gdown https://drive.google.com/uc?id=1vuuDocQ6HaxRAuXo1s_ZdjQenPMHFbgl -O my_model3.h5 && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY BACKEND/app.py .

# Final stage
FROM nginx:1.21-alpine
WORKDIR /app

# Copy frontend build
COPY --from=frontend-build /app/frontend/build /usr/share/nginx/html

# Copy backend and its dependencies
COPY --from=backend-build /app/backend /app/backend
COPY --from=backend-build /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=backend-build /usr/local/bin /usr/local/bin

# Copy nginx configuration
COPY my-app/nginx.conf /etc/nginx/conf.d/default.conf

# Set up nginx permissions
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

# Remove default nginx user directive
RUN sed -i '/user  nginx;/d' /etc/nginx/nginx.conf

# Start both backend and nginx
CMD ["sh", "-c", "python /app/backend/app.py & nginx -g 'daemon off;'"]

EXPOSE 80