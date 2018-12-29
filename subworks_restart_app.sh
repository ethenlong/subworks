#!/bin/bash
curDir=`pwd`
rm ./log.txt
function publishOne(){
	if [ -d "$2" ];then
	echo "删除原文件 $2"
	echo $2
	rm -rf $2
	fi

	git clone $1

	cd $2
	
	git checkout $4> ../log.txt 2>&1
	
	check=`cat ../log.txt | grep "error: pathspec"`
	if [ -n "$check" ];then
		echo "tag not match"
		exit 1
	fi

	# git checkout $4 >> ~/it/test/gitlog.txt 2>&1

	configfile=`find ./ -name disconf.properties`
	echo $configfile
	for config in ${configfile[@]}
	do
		conf_server_host=`cat $config | grep "conf_server_host"`
		app=`cat $config | grep "app\=" | grep -v "\#"`
		env=`cat $config | grep "env"`
		echo $config

		case $5 in
		qa)
			echo "部署切换环境"
		if [ -n "$conf_server_host" ];then
			sed  -i s/$conf_server_host/conf_server_host\=disconf.sh.fanlai.com/g $config
			echo `cat $config | grep "conf_server_host"`
		fi

		if [ -n "$app" ];then
					sed  -i s/$app/app\=$3/g $config
			echo `cat $config | grep "app"`
			fi

		if [ -n "$env" ];then
					sed -i s/$env/env\=qa/g $config
			echo `cat $config | grep "env"`
			fi
			;;
		rd)
			echo "部署测试环境"
		if [ -n "$conf_server_host" ];then
					sed  -i s/$conf_server_host/conf_server_host\=disconf.sh.fanlai.com/g $config
					echo `cat $config | grep "conf_server_host"`
			fi

			if [ -n "$app" ];then
					sed  -i s/$app/app\=$3/g $config
					echo `cat $config | grep "app"`
			fi

			if [ -n "$env" ];then
					sed -i 's/$env/env\=rd/g' $config
					echo `cat $config | grep "env"`
			fi
			;;
		online)
			echo "部署生产环境"
				if [ -n "$conf_server_host" ];then
					sed  -i s/$conf_server_host/conf_server_host\=disconf.sh.fanlai.com/g $config
					echo `cat $config | grep "conf_server_host"`
			fi

			if [ -n "$app" ];then
					sed  -i s/$app/app\=$3/g $config
					echo `cat $config | grep "app"`
			fi

			if [ -n "$env" ];then
					sed -i s/$env/env\=online/g $config
					echo `cat $config | grep "env"`
			fi
			;;
		esac
	done
	mvn clean package -Dmaven.test.skip=true
	
	tmpDir1=`find ./ -type d | grep target | grep -v target/ | grep impl`
	tmpDir2=`find ./ -type d | grep target | grep -v target/ | grep -v api`

	if [ -n "$tmpDir1" ];then
		targetDir=$tmpDir1		
	else 
		targetDir=$tmpDir2	
	fi
	cd $targetDir
	nameWar=`ls | grep .war`
	nameJar=`ls | grep jar | grep -v jar.`
	
	if [ -n "$nameWar" ];then
		target=$nameWar
	else
		target=$nameJar
	fi
	#targetName=$nameJar||$nameWar
	echo $target
	
	javaHome="/usr/java/jdk1.8.0_181/bin"
	echo $6
	case $5 in
	qa)
		if [ -n "$nameJar" ]
		then
			# ssh执行命令后会清空掉while读取的缓存，所以加-n参数，将返回输出丢掉，这样不会掉出while的循环
			ssh -p 3030 -n qingxin@$6 "[ -d /home/qingxin/release/$2/ ] && echo ok || mkdir -p /home/qingxin/release/$2/"
			pid=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep $nameJar" | grep -v "grep" | awk '{print $2}')
			######ssh -p 3030 -n fanlai@qa "ps -ef | grep old-soa" | grep -v "grep" | awk '{print $2}'
			if [ -n "$pid" ];then
				echo $pid
				ssh -p 3030 -n qingxin@$6 "kill -9 ${pid}"
				echo "$pid killed"
			fi
				
			
			# scp -P 3030 $target qingxin@$6:/home/qingxin/release/$2/
			port=`echo "$7" | grep 92`
			if [ -n "$port" ];then
				echo $7
				ssh -p 3030 -n qingxin@$6 "cd /home/qingxin/release/$2/ ;nohup java -jar $target --server.port=$port > /dev/null 2>&1 &"
			else
				ssh -p 3030 -n qingxin@$6 "cd /home/qingxin/release/$2/ ;nohup java -jar $target > /dev/null 2>&1 &"
			fi
			
			pid2=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep $nameJar" | grep -v "grep" | awk '{print $2}')
			if [ -n "$pid2" ];then
				echo "$target is started in PID $pid2"
			fi
			
		elif [ -n "$nameWar" ]
		then
			case $target in
				member-api.war)
					pid91=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-1" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid91" ];then
						echo $pid91
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid91}"
						echo "$pid91 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-1/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-1/bin/catalina.sh start"
					#ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-1/logs/catalina.out"
				;;
				mall-api.war)
					pid92=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-2" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid92" ];then
						echo $pid92
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid92}"
						echo "$pid92 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-2/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-2/bin/catalina.sh start"
					#ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-2/logs/catalina.out"
				;;
				device-api.war)
					pid93=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-3" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid93" ];then
						echo $pid93
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid93}"
						echo "$pid93 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-3/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-3/bin/catalina.sh start"
					#ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-3/logs/catalina.out"
					
				;;
				ws_manager.war)
					pid94=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-4" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid94" ];then
						echo $pid94
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid94}"
						echo "$pid94 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-4/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-4/bin/catalina.sh start"
					#ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-4/logs/catalina.out"
				;;
				sapp-api.war)
					pid95=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-5" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid95" ];then
						echo $pid95
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid95}"
						echo "$pid95 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-5/webapps/
					
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-5/bin/catalina.sh start"
					
					#ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-5/logs/catalina.out"
				;;
				
				
			esac
		fi	
		;;
	rd)
		if [ -n "$nameJar" ]
		then
			# ssh执行命令后会清空掉while读取的缓存，所以加-n参数，将返回输出丢掉，这样不会掉出while的循环
			ssh -p 3030 -n qingxin@$6 "[ -d /home/qingxin/release/$2/ ] && echo ok || mkdir -p /home/qingxin/release/$2/"
			pid=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep $nameJar" | grep -v "grep" | awk '{print $2}')
			######ssh -p 3030 -n fanlai@qa "ps -ef | grep old-soa" | grep -v "grep" | awk '{print $2}'
			if [ -n "$pid" ];then
				echo $pid
				ssh -p 3030 -n qingxin@$6 "kill -9 ${pid}"
				echo "$pid killed"
			fi
				
			
			# scp -P 3030 $target qingxin@$6:/home/qingxin/release/$2/
			port=`echo "$7" | grep 92`
			if [ -n "$port" ];then
				echo $7
				ssh -p 3030 -n qingxin@$6 "cd /home/qingxin/release/$2/ ;nohup java -jar $target --server.port=$port > /dev/null 2>&1 &"
			else
				ssh -p 3030 -n qingxin@$6 "cd /home/qingxin/release/$2/ ;nohup java -jar $target > /dev/null 2>&1 &"
			fi
			
			pid2=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep $nameJar" | grep -v "grep" | awk '{print $2}')
			if [ -n "$pid2" ];then
				echo "$target is started in PID $pid2"
			fi
			
		elif [ -n "$nameWar" ]
		then
			case $target in
				member-api.war)
					pid91=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-1" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid91" ];then
						echo $pid91
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid91}"
						echo "$pid91 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-1/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-1/bin/catalina.sh start"
					ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-1/logs/catalina.out"
				;;
				mall-api.war)
					pid92=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-2" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid92" ];then
						echo $pid92
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid92}"
						echo "$pid92 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-2/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-2/bin/catalina.sh start"
					ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-2/logs/catalina.out"
				;;
				device-api.war)
					pid93=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-3" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid93" ];then
						echo $pid93
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid93}"
						echo "$pid93 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-3/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-3/bin/catalina.sh start"
					ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-3/logs/catalina.out"
					
				;;
				ws_manager.war)
					pid94=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-4" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid94" ];then
						echo $pid94
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid94}"
						echo "$pid94 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-4/webapps/
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-4/bin/catalina.sh start"
					ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-4/logs/catalina.out"
				;;
				sapp-api.war)
					pid95=$(ssh -p 3030 -n qingxin@$6 "ps -ef | grep tomcat9-5" | grep -v "grep" | awk '{print $2}')
					if [ -n "$pid95" ];then
						echo $pid95
						ssh -p 3030 -n qingxin@$6 "kill -9 ${pid95}"
						echo "$pid95 killed"
					fi
					# scp -P 3030 $target qingxin@$6:/usr/local/tomcat9-5/webapps/
					
					ssh -p 3030 -n qingxin@$6 "sh /usr/local/tomcat9-5/bin/catalina.sh start"
					
					ssh -p 3030 -n qingxin@$6 "tail -f /usr/local/tomcat9-5/logs/catalina.out"
				;;
				
				
			esac
		fi	
		;;
	online)
		echo "online publish"
		scp -P 3030 $target pub@$6:~/publishOnline/
		;;
	
	esac



}


publishOne $1 $2 $3 $4 $5 $6 $7
# publishOne $gitUrl $projectName $appName $projecTtag $pulishEnv $publishIp $jarPort

