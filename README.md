# 容器模板

## 重新启动容器，更新配置和环境变量
docker compose down
docker compose up -d

docker ps   # 查看容器状态
docker exec -it PROJECT_NAME-claude-code /bin/bash  # 进入容器
docker compose logs -f  # 查看容器日志


## Claude Code 配置

claude mcp list

Claude Code 的全局（用户级）MCP 配置统一写在 ~/.claude.json

如果希望当前项目中使用其他 mcp，在项目根目录新建 .mcp.json 文件，内容如下：
{
  "mcpServers": [
    {
      "name": "mcp-server-name",
      "url": "http://localhost:3000"
    }
  ]
}
