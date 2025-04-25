# ---------- Stage 1: Build React frontend ----------
FROM node:18 AS frontend-build
WORKDIR /app/frontend

# Install dependencies first
COPY my-app/package*.json ./
RUN npm install -g npm@9.8.1 && npm install

# Copy full React app and build it
COPY my-app/ ./
RUN npm run build

# ---------- Stage 2: Build Python Flask backend ----------
FROM python:3.9-slim AS backend-build
WORKDIR /app/backend

# Install Python dependencies
COPY BACKEND/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Download model using gdown
RUN apt-get update && \
    apt-get install -y wget && \
    pip install gdown && \
    gdown https://drive.google.com/uc?id=1vuuDocQ6HaxRAuXo1s_ZdjQenPMHFbgl -O my_model3.h5 && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Flask app
COPY BACKEND/app.py ./

# ---------- Stage 3: Final image with both Nginx and Flask ----------
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy frontend build output from Stage 1
COPY --from=frontend-build /app/frontend/build /usr/share/nginx/html

# Copy backend app from Stage 2
COPY --from=backend-build /app/backend /app/backend

# Install Nginx and supervisor to manage both services
RUN apt-get update && \
    apt-get install -y nginx supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy custom Nginx config
COPY my-app/nginx.conf /etc/nginx/conf.d/default.conf

# Supervisor config to run both Flask and Nginx
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 80

# Run both services using supervisor
CMD ["/usr/bin/supervisord"]