#!/bin/bash

# Docker Swarm Installation Script
# This script installs Docker and configures the system for Docker Swarm
# Usage: curl -fsSL https://raw.githubusercontent.com/Incrisz/docker-swarm/main/install-docker.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "This script should not be run as root. Please run as a regular user with sudo privileges."
        log_info "The script will use sudo when necessary."
    fi
}

# Check system requirements
check_system() {
    log_info "Checking system requirements..."
    
    # Check if Ubuntu/Debian
    if ! command -v apt &> /dev/null; then
        log_error "This script is designed for Ubuntu/Debian systems with apt package manager."
        exit 1
    fi
    
    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        log_error "sudo is required but not installed."
        exit 1
    fi
    
    log_success "System requirements check passed."
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    sudo apt update
    log_success "System packages updated."
}

# Install dependencies
install_dependencies() {
    log_info "Installing required dependencies..."
    sudo apt install -y ca-certificates curl gnupg lsb-release
    log_success "Dependencies installed successfully."
}

# Add Docker's official GPG key
add_docker_gpg_key() {
    log_info "Adding Docker's official GPG key..."
    
    # Create directory for keyrings
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    
    # Download and add GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    log_success "Docker GPG key added successfully."
}

# Set up Docker repository
setup_docker_repository() {
    log_info "Setting up Docker repository..."
    
    echo \
        "deb [arch=$(dpkg --print-architecture) \
        signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    log_success "Docker repository configured successfully."
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    # Update package index
    sudo apt update
    
    # Install Docker packages
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log_success "Docker installed successfully."
}

# Configure Docker service
configure_docker_service() {
    log_info "Configuring Docker service..."
    
    # Enable Docker service
    sudo systemctl enable docker
    
    # Start Docker service
    sudo systemctl start docker
    
    # Check if Docker is running
    if sudo systemctl is-active docker &> /dev/null; then
        log_success "Docker service is running."
    else
        log_error "Failed to start Docker service."
        exit 1
    fi
}

# Configure firewall for Docker Swarm
configure_firewall() {
    log_info "Configuring firewall for Docker Swarm..."
    
    # Check if UFW is installed and active
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "Status: active"; then
            log_info "UFW is active. Opening required ports..."
            
            # Swarm management port (only required on manager)
            sudo ufw allow 2377/tcp
            log_info "Opened port 2377/tcp (Swarm management)"
            
            # Node communication (required on all)
            sudo ufw allow 7946/tcp
            sudo ufw allow 7946/udp
            log_info "Opened ports 7946/tcp and 7946/udp (Node communication)"
            
            # Overlay networking (required on all)
            sudo ufw allow 4789/udp
            log_info "Opened port 4789/udp (Overlay networking)"
            
            # Optional: allow SSH for remote access
            sudo ufw allow ssh
            log_info "Ensured SSH access is allowed"
            
            log_success "Firewall configured for Docker Swarm."
        else
            log_info "UFW is installed but not active. Skipping firewall configuration."
        fi
    else
        log_info "UFW not installed. Skipping firewall configuration."
        log_warning "Make sure the following ports are open: 2377/tcp, 7946/tcp, 7946/udp, 4789/udp"
    fi
}

# Add user to docker group
add_user_to_docker_group() {
    log_info "Adding current user to docker group..."
    
    # Add current user to docker group
    sudo usermod -aG docker "$USER"
    
    log_success "User added to docker group."
    log_warning "You may need to log out and back in, or run 'newgrp docker' to use Docker without sudo."
}

# Verify Docker installation
verify_installation() {
    log_info "Verifying Docker installation..."
    
    # Try to run docker command with sudo first
    if sudo docker --version &> /dev/null; then
        DOCKER_VERSION=$(sudo docker --version)
        log_success "Docker is installed: $DOCKER_VERSION"
    else
        log_error "Docker installation verification failed."
        exit 1
    fi
    
    # Test Docker with hello-world
    log_info "Testing Docker with hello-world container..."
    if sudo docker run --rm hello-world &> /dev/null; then
        log_success "Docker is working correctly."
    else
        log_warning "Docker hello-world test failed. Docker may still work for swarm operations."
    fi
}

# Display next steps
display_next_steps() {
    echo
    log_success "Docker installation completed successfully!"
    echo
    echo -e "${BLUE}=== NEXT STEPS FOR DOCKER SWARM SETUP ===${NC}"
    echo
    echo -e "${YELLOW}1. Initialize Docker Swarm (on manager node):${NC}"
    echo "   docker swarm init --advertise-addr <YOUR-MANAGER-IP>"
    echo
    echo -e "${YELLOW}2. Join worker nodes to swarm:${NC}"
    echo "   Use the join command provided by the swarm init output"
    echo "   Example: docker swarm join --token SWMTKN-1-xxx... <MANAGER-IP>:2377"
    echo
    echo -e "${YELLOW}3. Verify swarm setup:${NC}"
    echo "   docker node ls"
    echo
    echo -e "${YELLOW}4. Get join tokens anytime:${NC}"
    echo "   docker swarm join-token worker    # For worker nodes"
    echo "   docker swarm join-token manager   # For manager nodes"
    echo
    echo -e "${YELLOW}5. To use Docker without sudo:${NC}"
    echo "   newgrp docker   # Or log out and back in"
    echo
    echo -e "${BLUE}=== USEFUL COMMANDS ===${NC}"
    echo "   docker service create --name web --replicas 3 -p 8080:80 nginx"
    echo "   docker service ls"
    echo "   docker service scale web=5"
    echo "   docker stack deploy -c docker-compose.yml mystack"
    echo
    echo -e "${GREEN}For more information, check the README at:${NC}"
    echo "https://github.com/Incrisz/docker-swarm"
    echo
}

# Main installation function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Docker Swarm Installation Script    ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    check_root
    check_system
    update_system
    install_dependencies
    add_docker_gpg_key
    setup_docker_repository
    install_docker
    configure_docker_service
    configure_firewall
    add_user_to_docker_group
    verify_installation
    display_next_steps
}

# Run main function
main "$@"