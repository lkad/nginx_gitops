## 此为模板的定义工程。
将 Nginx 配置文件模板化并通过 GitOps 管理带来许多好处，尤其是在多服务器、多环境的部署中。以下是一些关键优势：
1. 配置一致性

模板化配置：

    使用模板引擎（如 Jinja2）创建标准化的 Nginx 配置文件，可以确保在不同环境和服务器上的配置文件保持一致。

2. 版本控制

Git 管理配置：

    将所有 Nginx 配置文件存储在 Git 仓库中，利用 Git 的版本控制功能，所有配置的修改都有记录。
    可以追踪每次更改的历史，便于审计和回滚到以前的版本。

3. 自动化和持续交付

CI/CD 集成：

    配置文件的更改可以触发 CI/CD 管道，从而自动化配置文件的验证、测试和部署。
    通过 GitOps 工具（如 tekton 或 jenkisn），可以实现配置的自动部署和同步。

4. 审计和合规性

变更管理：

    每次配置修改通过 Pull Request (PR) 流程进行审查和批准，确保配置更改的安全性和合规性。
    配置的每次更改都有详细的记录和审计日志，方便遵循合规要求。

5. 高可用性和灾难恢复

备份和恢复：

    Git 仓库本身就是一个配置备份，任何时间点的配置都可以从 Git 恢复。
    在发生配置错误或系统故障时，可以快速恢复到已知的良好配置状态。

6. 动态和灵活性

参数化配置：

    配置文件模板可以使用变量和参数，根据不同的环境（如开发、测试、生产）生成不同的配置文件。
    通过环境变量或配置文件注入方式，可以灵活地调整配置。

7. 可扩展性

多环境支持：

    支持多环境、多站点的配置管理，通过模板化和参数化，轻松扩展和管理多个 Nginx 实例。
    通过 GitOps 工具的多集群支持，轻松管理大规模分布式系统的 Nginx 配置。
## 模板的配置覆盖
配置分为base,overlays进行配置覆盖，将公用配置放在base中，uat,tst,pro环境不同的配置通过overlays进行合并,merge来管理，这样当配置从test->uat->pro进行devops中gitops方式的验证.    
使用
8. 配置模板化

模板化配置文件：

    使用模板引擎（如 Jinja2）创建标准化的 Nginx 配置文件，可以确保在不同环境和服务器上的配置文件保持一致。
    通过模板化，可以根据不同的环境（如开发、测试、生产）生成不同的配置文件，提高配置文件的灵活性和可维护性。

9. 配置覆盖

配置分为base,overlays进行配置覆盖：

    将公用配置放在base中，uat,tst,pro环境不同的配置通过overlays进行合并，merge来管理。
    这样当配置从test->uat->pro进行devops中gitops方式的验证时，可以确保配置的正确性和一致性。
    配置覆盖机制可以帮助团队更好地管理多环境配置，提高配置的可维护性和可扩展性。

10. 配置管理

    通过 GitOps 工具（如 tekton 或 jenkisn），可以实现配置的自动部署和同步。
    通过 GitOps 工具的多集群支持，轻松管理大规模分布式系统的 Nginx 配置。

11. 配置审计和合规性

    每次配置修改通过 Pull Request (PR) 流程进行审查和批准，确保配置更改的安全性和合规性。
    配置的每次更改都有详细的记录和审计日志，方便遵循合规要求。      
## 具体使用方法
1、安装ytt，按照[https://carvel.dev/ytt/docs/v0.50.x/install/](https://carvel.dev/ytt/docs/v0.50.x/install/)中的步骤进行安装。
2、配置hosts主机，需要参考ansible的inventory文件，将所有需要部署的机器ip和域名配置在hosts文件中。
3、配置nginx.conf的主配置文件，参考group_vars/pro/lktest.yml文件，进行配置，主要配置文件路径，备份，日志，进程数等配置。
4、配置overlay，在overlays目录中创建新的目录，如uat,tst,pro，在目录中创建config.http.yaml文件，文件内容为该环境的配置，如：
```
# 配置http服务
http:
  servers:
    - name: default
      host: "{{ env.HOST }}"
      port: 80
      ssl: false
      udp: false
      proxy_protocol: false
      fastopen: 12
      backlog: 511
      rcvbuf: 512
      sndbuf: 512
      resolver:
        address: []
        valid: 30s
        ipv6: false
        status_zone: backend_mem_zone
      resolver_timeout: 30s 
```
5、进行overlay的配置的差异配置，参考vars/instances/ad/pro/overlay.yaml 文件，进行配置，如：修改http地址和upstream配置，mapping配置等.            
```
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.all, expects="1+"
---
nginx_config_http_template:
#@overlay/match by=overlay.subset({"deployment_location": "/app/openresty/nginx/conf/servers/ad/ad.conf"})
- backup: false
  config: 
    upstreams: 
#!  #@overlay/match by=overlay.subset({"name": "ad-Server-gw"})
  #@overlay/match by="name"
    - name: ad-Server-gw
    #@overlay/replace
      servers: 
        - address: 111.111.111:88
    #@overlay/match by="name"
    - name: ad-Server_gray
    #@overlay/replace
      servers: 
        - address: 111.111.111:99
        - address: xxx.xxx.xxx:33
    map:
      mappings:
      #@overlay/match by="string"
      - string: $COOKIE_userName
        #@overlay/replace
        content: 
          - value: '~*test$'
            new_value: ad-Server_gray
          - value: '~*13922test$'
            new_value: 'ad-Server_gray'
          - value: default
            new_value: ad-Server_gray
    
    servers:
    #@overlay/match by=overlay.index(0)      
    - locations: 
      #@overlay/match by="location"
      - location : "/"
        proxy: 
          set_header: 
            #@overlay/match by=overlay.subset({"field": "Host"})
          - value: "adpro.xx.xxx"
      core: 
        #@overlay/replace
        listen:          
          - address: 0.0.0.0
            port: 80
        #@overlay/replace        
        server_name: 
          - adpro.xx.xxx 
          - 10.8.12.3


```
```
6、配置vars/instances/ad/pro/pro.http.sh文件，进行配置，如：    
```
ytt -f $(dirname $0)/../base/config.http.example.yaml -f $(dirname $0)/overlay.yaml 
```

7、执行以下命令进行部署：
ansible-playbook -i inventorys/inventory.ini deploy_nginx.yaml 进行部署
ansible-playbook -i inventorys/inventory.ini verify_config.yaml 进行行线上配置和实际git配置的一致性检查
