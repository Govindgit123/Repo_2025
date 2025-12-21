# VM Health Check Script

## Overview

The `vm_health_check.sh` script analyzes the health of a virtual machine by monitoring three critical system resources:
- **CPU Utilization**
- **Memory Utilization**
- **Disk Space Utilization**

## Health Criteria

The script uses a **60% threshold** for all metrics:

- **HEALTHY**: All three metrics (CPU, Memory, and Disk) are below 60% utilization
- **NOT HEALTHY**: Any one or more metrics are at or above 60% utilization

## Usage

### Basic Usage

```bash
./vm_health_check.sh
```

### Making the Script Executable

If the script is not already executable, run:

```bash
chmod +x vm_health_check.sh
```

## Output

The script provides a detailed report showing:
1. Individual status for each metric (CPU, Memory, Disk)
2. Current utilization percentage for each metric
3. Overall health status with color-coded output

### Example Output

```
======================================
VM Health Check Analysis
======================================

Checking CPU Utilization...
  CPU Usage: 0.2%
  Status: HEALTHY (< 60%)

Checking Memory Utilization...
  Memory Usage: 11.00%
  Status: HEALTHY (< 60%)

Checking Disk Space Utilization...
  Disk Usage (root partition): 78%
  Status: NOT HEALTHY (>= 60%)

======================================
Overall Health Status
======================================
✗ NOT HEALTHY
One or more metrics are at or above 60% utilization.
```

## Exit Codes

- **0**: VM is healthy (all metrics below 60%)
- **1**: VM is not healthy (one or more metrics at or above 60%)

## Requirements

The script uses standard Linux commands that are typically available on most systems:
- `top` - for CPU utilization
- `free` - for memory utilization
- `df` - for disk space utilization
- `bc` - for floating-point calculations

## Technical Details

### CPU Utilization
- Uses the `top` command to measure CPU usage
- Samples over a 1-second interval for accuracy

### Memory Utilization
- Uses the `free` command to get memory statistics
- Calculates percentage as: (Used Memory / Total Memory) × 100

### Disk Space Utilization
- Uses the `df` command to check disk usage
- Monitors the root partition (/)

## Customization

To change the health threshold, modify the `THRESHOLD` variable in the script:

```bash
# Change from 60% to your desired threshold
THRESHOLD=60
```

## Integration

This script can be integrated into:
- Cron jobs for periodic health monitoring
- Monitoring systems and alerting frameworks
- CI/CD pipelines for infrastructure validation
- Automated health check systems

### Example: Running as a Cron Job

To run the health check every hour:

```bash
0 * * * * /path/to/vm_health_check.sh >> /var/log/vm_health.log 2>&1
```
