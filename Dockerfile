FROM debian:12-slim

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install fortune-mod, cowsay, and netcat-openbsd
RUN apt-get update && apt-get install -y \
    fortune-mod \
    cowsay \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Add /usr/games to PATH so cowsay and fortune can be executed directly
ENV PATH="/usr/games:${PATH}"

# Set the working directory inside the container
WORKDIR /app

# Copy the wisecow.sh script
COPY wisecow.sh .

# Make the script executable
RUN chmod +x wisecow.sh

# Expose the application port
EXPOSE 4499

# Start the application
CMD ["./wisecow.sh"]
