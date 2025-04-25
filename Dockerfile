# Build stage for React frontend
FROM node:18 AS frontend-build
WORKDIR /app/frontend

# Copy package.json and package-lock.json files first to take advantage of Docker cache
COPY my-app/package*.json ./
RUN npm install -g npm@9.8.1 && npm install

# Copy the entire React app
COPY my-app/ ./
RUN npm run build

# Build stage for Python backend
FROM python:3.9-slim AS backend-build
WORKDIR /app/backend

# Install dependencies from requirements.txt
COPY BACKEND/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Install necessary utilities and download the model
RUN apt-get update && \
    apt-get install -y wget && \
    pip install gdown && \
    gdown https://drive.google.com/uc?id=1vuuDocQ6HaxRAuXo1s_ZdjQenPMHFbgl -O my_model3.h5 && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the backend app code
COPY BACKEND/app.py ./

# Final stage: Nginx for serving the app
FROM nginx:1.21-alpine

# Set working directory for app
WORKDIR /app

# Copy the React frontend build files to Nginx's directory
COPY --from=frontend-build /app/frontend/build /usr/share/nginx/html

# Copy the backend app code and dependencies from the backend build stage
COPY --from=backend-build /app/backend /app/backend

# Copy the backend dependencies from the backend build stage
COPY --from=backend-build /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=backend-build /usr/local/bin /usr/local/bin

# Copy nginx configuration
COPY my-app/nginx.conf /etc/nginx/conf.d/default.conf

# Set up permissions for nginx
RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/run /usr/share/nginx/html && \
    chmod -R 755 /var/cache/nginx /var/log/nginx /var/run /usr/share/nginx/html

# Remove default nginx user directive
RUN sed -i '/user  nginx;/d' /etc/nginx/nginx.conf

# Expose the port nginx will be listening on
EXPOSE 80

# Start both backend and nginx services (use entrypoint to run both)
CMD ["sh", "-c", "python /app/backend/app.py & nginx -g 'daemon off;'"]
