#!/bin/bash

cd /workspace/qanything_local || exit

nohup python3 -u qanything_kernel/qanything_server/sanic_api.py --mode "local" > /workspace/qanything_local/logs/debug_logs/sanic_api.log 2>&1 &

# 监听后端服务启动
backend_start_time=$(date +%s)

while ! grep -q "Starting worker" /workspace/qanything_local/logs/debug_logs/sanic_api.log; do
    echo "Waiting for the backend service to start..."
    echo "等待启动后端服务"
    sleep 1

    # 获取当前时间并计算经过的时间
    current_time=$(date +%s)
    elapsed_time=$((current_time - backend_start_time))

    # 检查是否超时
    if [ $elapsed_time -ge 120 ]; then
        echo "启动后端服务超时，请检查日志文件 /workspace/qanything_local/logs/debug_logs/sanic_api.log 获取更多信息。"
        exit 1
    fi
    sleep 5
done

echo "The qanything backend service is ready! (4/8)"
echo "qanything后端服务已就绪! (4/8)"

# 转到 front_end 目录
cd /workspace/qanything_local/front_end || exit
# 如果node_modules不存在，就创建一个符号链接
if [ ! -d "node_modules" ]; then
    ln -s /root/node_modules node_modules
fi
echo "Dependencies related to npm are obtained. (5/8)"

env_file="/workspace/qanything_local/front_end/.env.production"
user_ip=$USER_IP
# 读取env_file的第一行
current_host=$(grep VITE_APP_API_HOST "$env_file")
user_host="VITE_APP_API_HOST=http://$user_ip:8777"
# 检查current_host与user_host是否相同
if [ "$current_host" != "$user_host" ]; then
    # 使用 sed 命令更新 VITE_APP_API_HOST 的值
    sed -i "s|VITE_APP_API_HOST=.*|$user_host|" "$env_file"
    echo "The file $env_file has been updated with the following configuration:"
    grep "VITE_APP_API_HOST" "$env_file"

    echo ".env.production 文件已更新，需重新构建前端项目。"
    # 构建前端项目
    echo "Waiting for [npm run build](6/8)"
    timeout 180 npm run build
    if [ $? -eq 0 ]; then
        echo "[npm run build] build successfully(6/8)"
    elif [ $? -eq 124 ]; then
        echo "npm run build 编译超时(180秒)，请查看上面的输出。"
        exit 1
    else
        echo "Failed to build the front end."
        exit 1
    fi
elif [ -d "dist" ]; then
    echo "The front_end/dist folder already exists, no need to build the front end again.(6/8)"
else
    echo "Waiting for [npm run build](6/8)"
    timeout 180 npm run build
    if [ $? -eq 0 ]; then
        echo "[npm run build] build successfully(6/8)"
    elif [ $? -eq 124 ]; then
        echo "npm run build 编译超时(180秒)，请查看上面的输出。"
        exit 1
    else
        echo "Failed to build the front end."
        exit 1
    fi
fi

# 启动前端页面服务
nohup npm run serve 1>/workspace/qanything_local/logs/debug_logs/npm_server.log 2>&1 &

# 监听前端页面服务
tail -f /workspace/qanything_local/logs/debug_logs/npm_server.log &

front_end_start_time=$(date +%s)

while ! grep -q "Local:" /workspace/qanything_local/logs/debug_logs/npm_server.log; do
    echo "Waiting for the front-end service to start..."
    echo "等待启动前端服务"

    # 获取当前时间并计算经过的时间
    current_time=$(date +%s)
    elapsed_time=$((current_time - front_end_start_time))

    # 检查是否超时
    if [ $elapsed_time -ge 120 ]; then
        echo "启动前端服务超时，请尝试手动删除front_end/dist文件夹，再重新启动run.sh，或检查日志文件 /workspace/qanything_local/logs/debug_logs/npm_server.log 获取更多信息。"
        exit 1
    fi
    sleep 5
done
echo "The front-end service is ready!...(7/8)"
echo "前端服务已就绪!...(7/8)"
