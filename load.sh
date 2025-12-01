# --- 主逻辑部分 ----

# 每次检查时，如果内存利用率低于目标，则增加内存负载
while true; do
    # 获取当前 CPU 和内存利用率
    read CURRENT_CPU_USAGE CURRENT_MEM_USAGE <<< $(get_current_usage)

    # 内存负载检查和调整
    if [ "$CURRENT_MEM_USAGE" -lt "$TARGET_MEM_PERCENT" ]; then
        echo "内存利用率低于目标 $TARGET_MEM_PERCENT%，增加内存负载..."
        # 计算需要分配的额外内存
        EXTRA_MEM_MB=$(echo "scale=0; ($TARGET_MEM_PERCENT - $CURRENT_MEM_USAGE) * $TOTAL_MEM_KB / 100 / 1024" | bc)

        # 增加更多的内存负载
        if command -v stress-ng &> /dev/null; then
            stress-ng --vm 1 --vm-bytes ${EXTRA_MEM_MB}M --vm-keep --timeout 7d & 
            MEM_PIDS+=($!)
            echo "已增加额外内存负载 (${EXTRA_MEM_MB}MB)"
        elif command -v python3 &> /dev/null; then
            python3 -c "
import time;
size = $EXTRA_MEM_MB * 1024 * 1024;
print(f'Python 正在分配 {size / 1024 / 1024} MB 内存...');
mem_hog = bytearray(size);
while True:
    time.sleep(60);
" & 
            MEM_PIDS+=($!)
            echo "已启动 Python 内存负载进程 (PID: $!)"
        fi
    fi

    # 继续执行 CPU 负载生成和调整等其他操作
    ...
    
    # 等待下一个检查间隔
    sleep $CHECK_INTERVAL
done
