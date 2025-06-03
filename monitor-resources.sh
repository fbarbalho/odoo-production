#!/bin/bash

echo "📊 Status CX22 - $(date)"
echo "========================"

echo "🔥 CPU:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' || echo "N/A"

echo "💾 Memory:"
free -h | grep Mem

echo "💿 Disk:"
df -h / | tail -1

echo "🐳 Containers:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "N/A"

echo "========================"
