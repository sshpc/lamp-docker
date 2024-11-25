#!/bin/bash
export LANG=en_US.UTF-8

#异常终止执行函数
trap _exit INT QUIT TERM
#初始化函数
initself() {
    selfversion='0.1'
    datevar=$(date +%Y-%m-%d_%H:%M:%S)
    #菜单名称(默认首页)
    menuname='首页'
    #父级函数名
    parentfun=''
    ipaddresses=''
    gateway=''
    nameservers=''
    port=''
    unport=''
    ips=''

    #字体颜色定义
    _red() {
        printf '\033[0;31;31m%b\033[0m' "$1"
        echo
    }
    _green() {
        printf '\033[0;31;32m%b\033[0m' "$1"
        echo
    }
    _yellow() {
        printf '\033[0;31;33m%b\033[0m' "$1"
        echo
    }
    _blue() {
        printf '\033[0;31;36m%b\033[0m' "$1"
        echo
    }
    #分割线
    next() {
        printf "%-50s\n" "-" | sed 's/\s/-/g'
    }

    #按任意键继续
    waitinput() {
        echo
        read -n1 -r -p "按任意键继续...(退出 Ctrl+C)"
    }
    #继续执行函数
    nextrun() {
        waitinput
        #环境变量调用上一次的次菜单
        ${FUNCNAME[3]}
    }

    #菜单头部
    menutop() {
        #clear
        echo
        _blue ">~~~~~~~~~~~~~~ docker LAMP 工具脚本 ~~~~~~~~~~~~<  v: $selfversion"
        echo
        _yellow "当前菜单: $menuname "
        echo
    }
    #菜单渲染
    menu() {
        menutop
        options=("$@")
        num_options=${#options[@]}
        # 计算数组中的字符最大长度
        max_len=0
        for ((i = 0; i < num_options; i++)); do
            # 获取当前字符串的长度
            str_len=${#options[i]}

            # 更新最大长度
            if ((str_len > max_len)); then
                max_len=$str_len
            fi
        done
        # 渲染菜单
        for ((i = 0; i < num_options; i += 4)); do
            printf "%s%*s  " "$((i / 2 + 1)): ${options[i]}" "$((max_len - ${#options[i]}))"
            if [[ "${options[i + 2]}" != "" ]]; then printf "$((i / 2 + 2)): ${options[i + 2]}"; fi
            echo
            echo
        done
        echo
        printf '\033[0;31;36m%b\033[0m' "q: 退出  "
        if [[ "$number" != "" ]]; then printf '\033[0;31;36m%b\033[0m' "b: 返回  0: 首页"; fi
        echo
        echo
        # 获取用户输入
        read -ep "请输入命令号: " number
        if [[ $number -ge 1 && $number -le $((num_options / 2)) ]]; then
            #找到函数名索引
            action_index=$((2 * (number - 1) + 1))
            #函数名赋值
            parentfun=${options[action_index]}
            #函数执行
            ${options[action_index]}

            #执行完后自动返回
            #nextrun
            waitinput
            main
        elif [[ $number == 0 ]]; then
            main
        elif [[ $number == 'b' ]]; then
            ${FUNCNAME[3]}
        elif [[ $number == 'q' ]]; then
            echo
            exit
        else
            echo
            _red '输入有误  回车返回首页'
            waitinput
            main
        fi

    }

    #异常终止函数
    _exit() {

        #...

        _red "\nThe script has been terminated.\n"

        exit 1
    }

    #检测命令是否存在
    _exists() {
        local cmd="$1"
        which $cmd >/dev/null 2>&1
        local rt=$?
        return ${rt}
    }

    #clear
}

lampstart() {
    docker-compose up -d

}

lampstop() {
    docker-compose down
}

composestart() {
    docker-compose start

}

composestop() {
    docker-compose stop
}

composeps() {
    echo
    echo "compose情况"
    echo
    docker-compose ps
    echo
    echo "容器情况"
    echo
    _green 'runing'
    docker ps
    _blue 'all'
    docker ps -a
}

catdockervolume() {
    echo
    echo "卷名              路径"
    for volume in $(docker volume ls -q); do
        _blue "$volume  $(docker volume inspect "$volume" --format '{{.Mountpoint}}')"
    done
}

restartcontainer() {

    # 获取所有正在运行的容器
    containers=$(docker ps --format 'table {{.ID}}\t{{.Names}}')

    # 打印容器列表并添加序号
    echo "当前正在运行的容器："
    echo "序号   容器ID         容器名称"
    i=1
    while read -r line; do
        if [[ $line != "CONTAINER ID"* ]]; then # 跳过标题行
            echo -e "$i\t$line"
            ((i++))
        fi
    done <<<"$containers"

    # 提示用户输入要重启的容器序号
    read -p "请输入要重启的容器序号（从 1 开始）： " index

    # 获取容器的 ID 列表
    container_ids=($(docker ps -q))

    # 检查输入的序号是否有效
    if [[ "$index" -gt 0 && "$index" -le "${#container_ids[@]}" ]]; then
        container_id=${container_ids[$((index - 1))]}

        # 重启容器
        _blue "正在重启容器：$index"
        docker restart "$container_id"
        _green "已重启"
    else
        echo "无效的序号，请输入有效的序号。"
    fi
}

catcomposelogs() {
    docker-compose logs
}

#维护
maintenancefun() {

    lampinstall() {
        docker-compose up -d --build 

        _blue '创建命名卷软连接'

        # 获取当前目录
        current_dir=$(pwd)
        # 列出所有卷并遍历
        for volume in $(docker volume ls -q); do
            # 获取卷的真实路径
            mountpoint=$(docker volume inspect "$volume" --format '{{.Mountpoint}}')

            # 在当前目录创建指向真实路径的符号链接
            ln -s "$mountpoint" "$current_dir/$volume"

            _green "Created symlink for volume '$volume' at '$current_dir/$volume' -> '$mountpoint'"
        done

    }

    dockerinstall() {
        apt install snap snapd
        snap install docker
    }

    dockervolumerm() {
        catdockervolume
        echo
        _red '确定全部删除吗?'
        waitinput
        _red "删除并移除软链接"
        for volume in $(docker volume ls -q); do
            docker volume rm $volume
            rm -r $volume
        done
    }

    menuname='首页/维护'
    options=("安装docker" dockerinstall "安装LAMP" lampinstall "开启" lampstart "终止" lampstop "删除所有命名卷" dockervolumerm)

    menu "${options[@]}"
}

#主函数
main() {
    echo
    menuname='首页'
    options=("启动" composestart "停止" composestop "查看状态" composeps "重启容器" restartcontainer "查看数据卷" catdockervolume "查看compose logs日志" catcomposelogs "安装&维护" maintenancefun)
    menu "${options[@]}"
}

#初始化
initself
main
