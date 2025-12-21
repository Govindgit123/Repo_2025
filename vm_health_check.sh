#!/bin/bash

###############################################################################
# VM Health Check Script
# 
# This script analyzes the health of a virtual machine based on:
# - CPU utilization
# - Memory utilization
# - Disk space utilization
#
# Health Criteria:
# - HEALTHY: All three metrics are below 60% utilization
# - NOT HEALTHY: Any metric is at or above 60% utilization
###############################################################################

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Threshold for health check (60%)
THRESHOLD=60

echo "======================================"
echo "VM Health Check Analysis"
echo "======================================"
echo ""

# Initialize health status
is_healthy=true

###############################################################################
# 1. CPU Utilization Check
###############################################################################
echo "Checking CPU Utilization..."

# Get CPU usage using top command
# This calculates CPU usage over a 1-second interval
CPU_USAGE=$(top -bn2 -d 1 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | cut -d'%' -f1)

# If top command fails, try alternative method using mpstat
if [ -z "$CPU_USAGE" ]; then
    # Alternative: Calculate from /proc/stat
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)
    CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc)
fi

# Convert to integer for comparison (remove decimal part)
CPU_USAGE_INT=$(echo "$CPU_USAGE" | cut -d'.' -f1)

echo "  CPU Usage: ${CPU_USAGE}%"

if [ "$CPU_USAGE_INT" -ge "$THRESHOLD" ]; then
    echo -e "  Status: ${RED}NOT HEALTHY${NC} (>= ${THRESHOLD}%)"
    is_healthy=false
else
    echo -e "  Status: ${GREEN}HEALTHY${NC} (< ${THRESHOLD}%)"
fi
echo ""

###############################################################################
# 2. Memory Utilization Check
###############################################################################
echo "Checking Memory Utilization..."

# Get memory usage using free command
# Calculate percentage: (Used / Total) * 100
MEMORY_TOTAL=$(free | grep Mem | awk '{print $2}')
MEMORY_USED=$(free | grep Mem | awk '{print $3}')
MEMORY_USAGE=$(echo "scale=2; ($MEMORY_USED / $MEMORY_TOTAL) * 100" | bc)

# Convert to integer for comparison
MEMORY_USAGE_INT=$(echo "$MEMORY_USAGE" | cut -d'.' -f1)

echo "  Memory Usage: ${MEMORY_USAGE}%"

if [ "$MEMORY_USAGE_INT" -ge "$THRESHOLD" ]; then
    echo -e "  Status: ${RED}NOT HEALTHY${NC} (>= ${THRESHOLD}%)"
    is_healthy=false
else
    echo -e "  Status: ${GREEN}HEALTHY${NC} (< ${THRESHOLD}%)"
fi
echo ""

###############################################################################
# 3. Disk Space Utilization Check
###############################################################################
echo "Checking Disk Space Utilization..."

# Get disk usage for root partition
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1)

echo "  Disk Usage (root partition): ${DISK_USAGE}%"

if [ "$DISK_USAGE" -ge "$THRESHOLD" ]; then
    echo -e "  Status: ${RED}NOT HEALTHY${NC} (>= ${THRESHOLD}%)"
    is_healthy=false
else
    echo -e "  Status: ${GREEN}HEALTHY${NC} (< ${THRESHOLD}%)"
fi
echo ""

###############################################################################
# Overall Health Status
###############################################################################
echo "======================================"
echo "Overall Health Status"
echo "======================================"

if [ "$is_healthy" = true ]; then
    echo -e "${GREEN}✓ HEALTHY${NC}"
    echo "All metrics are below ${THRESHOLD}% utilization."
    exit 0
else
    echo -e "${RED}✗ NOT HEALTHY${NC}"
    echo "One or more metrics are at or above ${THRESHOLD}% utilization."
    exit 1
fi
