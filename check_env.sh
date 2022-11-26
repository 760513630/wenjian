#!/bin/bash
 
#linux 7的防火墙关闭操作
firewalld(){
systemctl status firewalld | grep "running" &>/dev/null
if [ $? -eq 0 ]
then
	echo -e "INFO: \033[31m 防火墙处于开启状态,需要进行关闭操作！ \033[0m" 
else
	echo -e "INFO: \033[32m 防火墙已经关闭！\033[0m"  
fi
}

#selinux检查函数
selinux(){
#判断当前的状态
result=`getenforce`
if [ $result = "Enforing" ]
then
	echo -e "INFO: \033[31m selinux是开启状态，需要关闭！\033[0m" 
else
    echo -e "INFO: \033[32m selinux是关闭状态。\033[0m"
fi
}
#检查NetworkManager是否关闭
NetworkManager(){
systemctl status NetworkManager | grep "running" &>/dev/null
if [ $? -eq 0 ]
then
        echo -e "INFO: \033[31m NetworkManager处于开启状态,需要进行关闭操作！\033[0m"
else
        echo -e "INFO: \033[32m NetworkManager已经关闭！\033[0m"
fi
}
#检查内存清理脚本是否配置
clean(){
crontab -l | grep "clean-cache.sh" &>/dev/null
if [ $? -eq 0 ]
then
        echo -e "INFO: \033[32m 内存清理脚本已添加，无需处理。\033[0m"
else
        echo -e "INFO: \033[31m 内存清理脚本未添加，请及时添加避免不必要的问题。\033[0m"
fi
}
#检查监控脚本是否配置
monitor(){
crontab -l | grep "edoc2-monitor.sh" &>/dev/null
if [ $? -eq 0 ]
then
        echo -e "INFO: \033[32m 监控脚本已添加，无需处理。\033[0m"
else
        echo -e "INFO: \033[31m 监控脚本未添加，请及时添加避免不必要的问题。\033[0m"
fi
}


#检查垃圾容器清理脚本是否配置
container(){
crontab -l | grep "clean-container.sh" &>/dev/null
if [ $? -eq 0 ]
then
        echo -e "INFO: \033[32m 垃圾容器清理脚本已添加，无需处理。\033[0m"
else
        echo -e "INFO: \033[31m 垃圾容器清理脚本未添加，请及时添加避免不必要的问题。\033[0m"
fi
}


#检查content清理脚本是否配置
content(){
crontab -l | grep "delete_content.sh" &>/dev/null
if [ $? -eq 0 ]
then
        echo -e "INFO: \033[32m 清理临时转档脚本已添加，无需处理。\033[0m"
else
        echo -e "INFO: \033[31m 清理临时转档脚本未添加，请及时添加避免不必要的问题。\033[0m"
fi
}

#检查清理压缩下载临时文件脚本是否配置
transport(){
crontab -l | grep "clean-transport.sh" &>/dev/null
if [ $? -eq 0 ]
then
        echo -e "INFO: \033[32m 清理压缩下载临时文件脚本已添加，无需处理。\033[0m"
else
        echo -e "INFO: \033[31m 清理压缩下载临时文件脚本未添加，请及时添加避免不必要的问题。\033[0m"
fi
}

#打印mysql镜像
function  mysqlimage() {
	local image=$(docker ps | grep mysql |grep -v haproxy| awk '{print $2}')
        if [ -n "$image" ]; then
	    echo -e "INFO: \033[31m 所使用的mysql镜像为：$image \033[0m"
        else
            echo -e "INFO: \033[31m 当前节点未运行mysql服务，请检查mysql镜像。\033[0m"
        fi
}

#打印haproxy镜像
function haproxyimage(){
       local image=$(docker ps | grep haproxy| awk '{print $2}')
       if [ -n "$image" ]; then
           echo -e "INFO: \033[31m 所使用的haproxy镜像为：$image \033[0m"
       else
           echo -e "INFO: \033[31m 当前节点未运行haproxy服务，请检查haproxy镜像。\033[0m"
       fi

}

function file_open() {
        is_comfig=$(sysctl -a 2>/dev/null | grep "fs.file-max" | wc -l)
        file_open_max=$(sysctl -a 2>/dev/null| grep "fs.file-max" | awk -F " " '{print $3}')
	if [ $is_comfig -eq 1 ] && [ $file_open_max -ge 655360 ] ;then
  		echo -e "INFO: \033[32m 系统文件最大打开数设置正确! \033[0m"
	else
		echo -e "INFO: \033[31m 检测不通过!请编辑/etc/sysctl.conf，替换为'fs.file-max = 1310720'后执行sysctl -p \033[0m"
	fi
}


function check_ceph(){
       command -v ceph &> /dev/null
       if [ $? -eq 0 ]; then
          stats=$(timeout 60 ceph -s | awk '/health/{print $NF}')
          if [ "$stats" != 'HEALTH_OK' ]; then
              echo -e "INFO: \033[31m ceph健康状态异常，请使用ceph -s确认。\033[0m"
          else
              echo -e "INFO: \033[32m ceph健康状态正常。\033[0m"
          fi
       fi

}


function ip_forward_check(){
       static_ip_forward=$(grep 'net.ipv4.ip_forward' /etc/sysctl.conf |grep -v '#'| awk -F'=' '{print $NF}')
       dynamic_ip_forward=$(sysctl -a 2>/dev/null | grep -w net.ipv4.ip_forward | awk '{print $NF}')
       
       if [ -n "$static_ip_forward" ]; then
             if [ "$static_ip_forward" -eq 1 ] && [ "$dynamic_ip_forward" -eq 1 ]; then
                   echo -e "INFO: \033[32m net.ipv4.ip_forward设置正常。\033[0m"
             else
                   echo -e "INFO: \033[31m 请检查/etc/sysctl.conf文件'net.ipv4.ip_forward=1'是否开启，开启后执行sysctl -p \033[0m"
             fi
       else
             if [ "$dynamic_ip_forward" -ne 1 ]; then
                   echo -e "INFO: \033[31m 请检查/etc/sysctl.conf文件'net.ipv4.ip_forward=1'是否开启，开启后执行sysctl -p \033[0m"
             else
                   echo -e "INFO: \033[32m net.ipv4.ip_forward设置正常。\033[0m"
             fi
       fi



}

function ntp_check(){
       ntpstas=$(timedatectl | awk '/NTP enabled:/{print $NF}')
       is_sync=$(timedatectl | awk '/NTP synchronized:/{print $NF}')
       if [[ $ntpstas == "yes" ]] && [[ $is_sync == "yes" ]]; then
           echo -e "INFO: \033[32m ntp时间同步正常。\033[0m"
       else
           echo -e "INFO: \033[31m 请检查是否配置ntp或chrony时间同步。\033[0m"
       fi

}
			
	

#服务器的操作系统的判断
edition=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
ed=`cat /etc/redhat-release` 
if [ "X$edition" == "X8"  ]
then
	echo -e "INFO: \033[33m 当前服务器操作系统版本是linux 8版本系统，具体版本：$ed \033[0m" 
	firewalld
	selinux
        NetworkManager
        clean
        monitor
        container
        content
        transport
        mysqlimage
        haproxyimage
        file_open
        check_ceph
        ntp_check
        ip_forward_check
elif [ "X$edition" == "X7"  ]
then
	echo -e "INFO: \033[33m 当前服务器操作系统版本是linux 7版本系统，具体版本：$ed \033[0m" 
	firewalld
	selinux
        NetworkManager
        clean
        monitor
        container
        content
        transport
        mysqlimage
        haproxyimage
        file_open
        check_ceph
        ntp_check
        ip_forward_check
fi
