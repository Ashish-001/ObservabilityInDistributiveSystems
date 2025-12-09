#!/bin/bash

# Script to stop locally running Spring Boot services
# This helps free up ports for Docker containers

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info "Stopping locally running Spring Boot services..."

# Find and kill Java processes on microservice ports
PORTS=(8080 8081 8082 9000)
KILLED=0

for port in "${PORTS[@]}"; do
    PIDS=$(lsof -ti :$port 2>/dev/null)
    if [ -n "$PIDS" ]; then
        for pid in $PIDS; do
            # Check if it's a Java process (Spring Boot) - don't kill Docker processes
            if ps -p $pid -o comm= 2>/dev/null | grep -qi "java"; then
                print_info "Stopping Java process on port $port (PID: $pid)..."
                kill $pid 2>/dev/null && KILLED=$((KILLED + 1))
            else
                print_warning "Skipping non-Java process on port $port (PID: $pid) - may be Docker"
            fi
        done
    fi
done

if [ $KILLED -gt 0 ]; then
    print_info "Waiting for processes to terminate..."
    sleep 3
    
    # Force kill if still running (only Java processes)
    for port in "${PORTS[@]}"; do
        PIDS=$(lsof -ti :$port 2>/dev/null)
        if [ -n "$PIDS" ]; then
            for pid in $PIDS; do
                # Only force kill Java processes
                if ps -p $pid -o comm= 2>/dev/null | grep -qi "java"; then
                    print_warning "Force killing Java process on port $port (PID: $pid)..."
                    kill -9 $pid 2>/dev/null
                fi
            done
        fi
    done
    
    print_success "Stopped $KILLED process(es)"
else
    print_info "No processes found on ports 8080, 8081, 8082, or 9000"
fi

# Also check for PID file from start scripts
if [ -f ".application.pids" ]; then
    print_info "Stopping services from PID file..."
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            pid=$(echo "$line" | cut -d: -f1)
            service=$(echo "$line" | cut -d: -f2)
            if kill -0 "$pid" 2>/dev/null; then
                print_info "Stopping $service (PID: $pid)..."
                kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
            fi
        fi
    done < .application.pids
    rm -f .application.pids
    print_success "Cleaned up PID file"
fi

# Verify ports are free
print_info "Checking if ports are free..."
ALL_FREE=true
for port in "${PORTS[@]}"; do
    if lsof -ti :$port > /dev/null 2>&1; then
        print_warning "Port $port is still in use"
        ALL_FREE=false
    fi
done

if [ "$ALL_FREE" = true ]; then
    print_success "All ports (8080, 8081, 8082, 9000) are now free!"
else
    print_warning "Some ports may still be in use. You may need to manually stop processes."
fi

