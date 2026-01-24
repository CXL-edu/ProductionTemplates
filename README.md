# 容器模板

## 重新启动容器，更新配置和环境变量
docker compose down
docker compose up -d

docker ps   # 查看容器状态
docker exec -it PROJECT_NAME-claude-code /bin/bash  # 进入容器
docker compose logs -f  # 查看容器日志

