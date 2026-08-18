FROM node:20-alpine

WORKDIR /app

# Copy package files first for caching
COPY package*.json ./
RUN npm ci --production

# Copy the rest of the source
COPY . .

# Create uploads directory
RUN mkdir -p uploads

EXPOSE 3000

CMD ["node", "index.js"]
