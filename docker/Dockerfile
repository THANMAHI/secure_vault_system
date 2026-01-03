FROM node:22-alpine

WORKDIR /app

# Copy project files
COPY . .

# Make entrypoint executable
RUN chmod +x ./docker/entrypoint.sh

# Expose the blockchain port
EXPOSE 8545

ENTRYPOINT ["./docker/entrypoint.sh"]