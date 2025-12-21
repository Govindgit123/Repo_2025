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
#
# Usage:
#   ./vm_health_check.sh           - Basic health check
#   ./vm_health_check.sh explain   - Health check with detailed explanation
###############################################################################

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Threshold for health check (60%)
THRESHOLD=60

# Check if explain mode is enabled
EXPLAIN_MODE=false
if [ "$1" = "explain" ]; then
    EXPLAIN_MODE=true
fi

echo "======================================"
echo "VM Health Check Analysis"
echo "======================================"
echo ""

# Initialize health status and explanation arrays
is_healthy=true
declare -a unhealthy_reasons
declare -a healthy_reasons

###############################################################################
# 1. CPU Utilization Check
###############################################################################
echo "Checking CPU Utilization..."

# Get CPU usage using top command
# This calculates CPU usage over a 1-second interval
CPU_USAGE=$(top -bn2 -d 1 | grep "Cpu(s)" | tail -1 | sed 's/,//g' | awk '{print $2}' | cut -d'%' -f1)

# If top command fails or returns empty, try alternative approach
if [ -z "$CPU_USAGE" ]; then
    # Alternative: Get idle CPU and calculate usage
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed 's/,//g' | awk '{print $8}' | cut -d'%' -f1)
    if [ -n "$CPU_IDLE" ]; then
        CPU_USAGE=$(awk "BEGIN {printf \"%.1f\", 100 - $CPU_IDLE}")
    else
        CPU_USAGE="0.0"
    fi
fi

# Convert to integer for comparison (remove decimal part)
CPU_USAGE_INT=$(echo "$CPU_USAGE" | cut -d'.' -f1)

echo "  CPU Usage: ${CPU_USAGE}%"

if [ "$CPU_USAGE_INT" -ge "$THRESHOLD" ]; then
    echo -e "  Status: ${RED}NOT HEALTHY${NC} (>= ${THRESHOLD}%)"
    is_healthy=false
    unhealthy_reasons+=("CPU utilization is at ${CPU_USAGE}%, which exceeds the ${THRESHOLD}% threshold. High CPU usage may indicate heavy processing, too many running processes, or a need for additional CPU resources.")
else
    echo -e "  Status: ${GREEN}HEALTHY${NC} (< ${THRESHOLD}%)"
    healthy_reasons+=("CPU utilization is at ${CPU_USAGE}%, which is within acceptable limits.")
fi
echo ""

###############################################################################
# 2. Memory Utilization Check
###############################################################################
echo "Checking Memory Utilization..."

# Get memory usage using free command (run once for efficiency)
# Calculate percentage: (Used / Total) * 100
MEMORY_INFO=$(free | grep Mem)
MEMORY_TOTAL=$(echo "$MEMORY_INFO" | awk '{print $2}')
MEMORY_USED=$(echo "$MEMORY_INFO" | awk '{print $3}')
# Use awk for calculation to avoid bc dependency
MEMORY_USAGE=$(awk "BEGIN {printf \"%.2f\", ($MEMORY_USED / $MEMORY_TOTAL) * 100}")

# Convert to integer for comparison
MEMORY_USAGE_INT=$(echo "$MEMORY_USAGE" | cut -d'.' -f1)

echo "  Memory Usage: ${MEMORY_USAGE}%"

if [ "$MEMORY_USAGE_INT" -ge "$THRESHOLD" ]; then
    echo -e "  Status: ${RED}NOT HEALTHY${NC} (>= ${THRESHOLD}%)"
    is_healthy=false
    unhealthy_reasons+=("Memory utilization is at ${MEMORY_USAGE}%, which exceeds the ${THRESHOLD}% threshold. High memory usage may cause system slowdowns, swapping, or application crashes. Consider freeing memory or adding more RAM.")
else
    echo -e "  Status: ${GREEN}HEALTHY${NC} (< ${THRESHOLD}%)"
    healthy_reasons+=("Memory utilization is at ${MEMORY_USAGE}%, which is within acceptable limits.")
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
    unhealthy_reasons+=("Disk space utilization is at ${DISK_USAGE}%, which exceeds the ${THRESHOLD}% threshold. Running out of disk space can prevent applications from running, cause data loss, or system instability. Clean up unnecessary files or expand disk capacity.")
else
    echo -e "  Status: ${GREEN}HEALTHY${NC} (< ${THRESHOLD}%)"
    healthy_reasons+=("Disk space utilization is at ${DISK_USAGE}%, which is within acceptable limits.")
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
    
    # Print explanation if explain mode is enabled
    if [ "$EXPLAIN_MODE" = true ]; then
        echo ""
        echo "Explanation:"
        echo "------------"
        echo "The virtual machine is operating in a healthy state. All monitored"
        echo "resources (CPU, Memory, and Disk) are below the ${THRESHOLD}% utilization threshold."
        echo ""
        for reason in "${healthy_reasons[@]}"; do
            echo "• $reason"
        done
    fi
    exit 0
else
    echo -e "${RED}✗ NOT HEALTHY${NC}"
    echo "One or more metrics are at or above ${THRESHOLD}% utilization."
    
    # Print explanation if explain mode is enabled
    if [ "$EXPLAIN_MODE" = true ]; then
        echo ""
        echo "Explanation:"
        echo "------------"
        echo "The virtual machine requires attention. The following issues were detected:"
        echo ""
        for reason in "${unhealthy_reasons[@]}"; do
            echo -e "${YELLOW}⚠${NC} $reason"
            echo ""
        done
        
        # Show healthy metrics if any
        if [ ${#healthy_reasons[@]} -gt 0 ]; then
            echo "Metrics within normal range:"
            for reason in "${healthy_reasons[@]}"; do
                echo "• $reason"
            done
        fi
        echo ""
        echo "Recommendations:"
        echo "----------------"
        if [ ${#unhealthy_reasons[@]} -eq 1 ]; then
            echo "• Address the issue identified above to restore system health."
        else
            echo "• Address the ${#unhealthy_reasons[@]} issues identified above to restore system health."
        fi
        echo "• Monitor the system regularly to prevent resource exhaustion."
        echo "• Consider scaling resources or optimizing workloads if issues persist."
    fi
    exit 1
fi
