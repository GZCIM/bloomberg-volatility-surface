# Multi-stage build for React/Vite application
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Set production environment variables
ENV NODE_ENV=production
ENV VITE_BLOOMBERG_API_URL=http://bloomberg-gateway.internal.agreeablepond-1a74a92d.eastus.azurecontainerapps.io
ENV VITE_ENABLE_CACHE=true
ENV VITE_CACHE_TTL=900

# Build application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /api/ { \
        proxy_pass http://bloomberg-gateway.internal.agreeablepond-1a74a92d.eastus.azurecontainerapps.io; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]