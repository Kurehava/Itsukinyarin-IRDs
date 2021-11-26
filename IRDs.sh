clear;liveflags=0;secflags=0;clfeflags=0;
#BILI_DIR="/home/nyarin/recordserver/BiliRecorder/"
#DDTV_DIR="/home/nyarin/recordserver/DDTV2/tmp"
#RECORD_DIR="/media/nyarin/Record-DISK/RecordFiles"
BILI_DIR="/home/oriki/recordserver/BiliRecorder/"
DDTV_DIR="/home/oriki/recordserver/DDTV2/tmp"
#RECORD_DIR="/media/oriki/GravityWall"
RECORD_DIR="/home/oriki/wqe"
function header(){
    #从第5行到屏幕底端的范围滚动显示
    echo -ne "\e[5r"
    echo -ne "\e[33m===========================================\n"
    echo -ne "Itsukinyarin Recording and Dumping System >\n"
    echo -ne "Powered by oriki ver.0.9.2                >\n"
    echo -ne "===========================================\e[96m\n"
    echo -ne "\e[5H"
}

function ProgressBar(){
    i=0
    str=""
    arr=("|" "/" "-" "\\")
    targetDIR="$1"
    filename="$2"
    metasize="$3"
    if [ "`ps -ef | grep -w '[m]v'| awk '{print $2}'`" != "" ];then
        while [ $i -ne 100 ];do
            if [ -d "$targetDIR$filename" ];then
                targsize="`du --max-depth=1 $targetDIR$filename | awk '{print $1}' 2>/dev/null`"
            elif [ -f "$targetDIR$filename" ];then
                targsize="`ls -l "$targetDIR$filename" | awk '{print $5}'`"
            else
                printf "\n\e[1;40;31m[erro]\e[0;0;96m : 目标文件不为文件夹也不为文件，很奇怪，我无法开启进度条显示。\n"
                break 2
            fi
            let statsize=$targsize*100/$metasize
            let chkdatas=$i+5
            let index=i%4
            sleep 0.1
            if [ "$statsize" -ge "$chkdatas" ];then
                let i+=5
                str+='='
            fi
            printf "\e[0;96;1m[%-20s][%d%%]%c\r" "$str" "$i" "${arr[$index]}"
        done
        printf "\n"
    else
        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 没有检测到MV命令进程，无法开启进度条显示。\n"
    fi
}

function statuschk(){
    if [ "$1" = "" ];then
        #0为未开播 1为直播中 2为轮播中
        roomlist=("3858888" "135001")
        if [ "$liveflags" = "0" ];then
            for list in ${roomlist[@]};do
                status="$(echo `curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=$list"` | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}')"
                taruid="$(echo `curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=$list"` | sed 's:,: :g' | awk '{print $6}' | sed 's/:/ /g' | awk '{print $2}')"
                titles="$(curl -s https://api.live.bilibili.com/room/v1/Room/get_status_info_by_uids -H "Content-Type: application/json" -d "{\"uids\": [$taruid]}" | sed 's:,:\n:g' | sed 's:{::g' | grep "title" | sed 's/:/ /g' | awk '{print $4}' | sed 's:"::g')"
                unames="$(curl -s https://api.live.bilibili.com/room/v1/Room/get_status_info_by_uids -H "Content-Type: application/json" -d "{\"uids\": [$taruid]}" | sed 's:,:\n:g' | sed 's:{::g' | grep "uname" | sed 's/:/ /g' | awk '{print $2}' | sed 's:"::g')"
                if [ "$status" = "1" ];then
                    liveflags=1;break
                fi
            done
        elif [ "$liveflags" = "1" ];then
            status="$(echo `curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=$list"` | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}')"
            if [ "$status" = "0" ];then
                liveflags=2
            fi
        fi
    fi
}

function infosys(){
    while :;do
        statuschk
        if [ "$clfeflags" = "0" ] && [ "$status" = "1" ];then
            case $liveflags in
                #\e[93m"$(date "+%Y-%m-%d %H:%M:%S")"\e[96m
                1) printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$unames" 已开播\n\e[1;40;32m[info]\e[0;0;96m : $titles\n";thifloder=$(date "+%m-%d-%H-%M");;
                0) printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$unames" 已下播\n\e[1;40;32m[info]\e[0;0;96m : $titles\n";secflags=1;;
                *) printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : statuschk 返回值不为[1]开播，[2]下播的、任意一个。\n";;
            esac
            clfeflags=1
        fi
        sleep 2s
        if [ "$secflags" = "1" ];then
            printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : 检测到[ $list-$unames ]已经下播，触发安全休眠系统，安全休眠10分钟后自动唤醒。\n"
            sleep 10m;statuschk;liveflags=0;secflags=0;clfeflags=0;
            if [ "$status" = "0" ];then
                break;
            else
                printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : 检测到[ $list-$unames ]复播，进入循环检测系统。\n"
            fi
        fi
    done
    printf "-------------------------------------------\n"
}

function testarea(){
    thifloder=$(date "+%m-%d-%H-%M")
    unames="伊月猫凛"
    list="3858888"
}

function occupychk(){
    SLEEPWAIT=0;ddtvwaitlist=[];biliwaitlist=[];
    if [ "`ls -l "/home/oriki/recordserver/DDTV2/tmp/bilibili_$unames"_"$list/" | grep .flv | grep "^-" | wc -l`" \> "0" ] || [ "`cd /home/oriki/recordserver/BiliRecorder/ && ls -d */ | grep "^$(date "+%Y")" | wc -l`" \> "0" ];then
        if [ $(date "+%H") \< "06" ];then
            savepath="$RECORD_DIR/$(date "+%Y")/$(date "+%Y-%m")-`expr $(date "+%d") - 1`/$(date "+%m")-`expr $(date "+%d") - 1`-daychangecover/"
        else
            savepath="$RECORD_DIR/$(date "+%Y")/$(date "+%Y-%m-%d")/$thifloder/"
        fi
        mkdir -p $savepath
    
        #DDTV
        cd "$DDTV_DIR/bilibili_$unames"_"$list/"
        for DDTV_FLV in *.flv;do
            #DDTV_FLV="`echo $DDTV_FLV | sed 's:\*:\\\*:g'`"
            DDTV_FLV="./$DDTV_FLV"
            if [ "$DDTV_FLV" = "*.flv" ];then
                printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : DDTV目录没有检测到FLV录制视频文件\n"
            else
                while :;do
                    if [[ "`lsof "$DDTV_FLV" 2>/dev/null | grep -v "PID" | awk '{print $2}'`" != "" ]] && [ "$SLEEPWAIT" -le "2" ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n"
                        sleep 10m
                        let SLEEPWAIT++
                    elif [ "$SLEEPWAIT" -gt "2" ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n"
                        ddtvwaitlist+=("$DDTV_DIR/bilibili_$unames"_"$list/$DDTV_FLV")
                        break
                    else
                        DDTV_FLV_VIS="`echo $DDTV_FLV | sed 's/ /[:space:]/g'`"
                        printf "\n\e[1;40;32m[info]\e[0;0;96m : DDTV-正在移动文件"$DDTV_FLV_VIS".\n"
                        metasize="`ls -l "$DDTV_FLV" | awk '{print $5}' 2>/dev/null`"
                        mv "$DDTV_FLV" "$savepath"&
                        ProgressBar "$savepath" "$DDTV_FLV" "$metasize"
                        break
                    fi
                done
            fi
        done
        unset SLEEPWAIT DDTV_FLV metasize

        #BilibiliRecord
        cd "$BILI_DIR"
        flag2bili=0
        for BILI_FOLDER in `ls -d */ | grep "^$(date "+%Y")"`;do
            cd "$BILI_DIR$BILI_FOLDER"
            flag2bili=1
            for BILI_FLV in *.flv;do
                #BILI_FLV="`echo $BILI_FLV | sed 's:\*:\\\*:g'`"
                while :;do
                    if [ "`lsof "$BILI_FLV" 2>/dev/null | grep -v "PID" | awk '{print $2}'`" != "" ] && [ "$SLEEPWAIT" \<\= "2"  ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n"
                        sleep 10m
                        let SLEEPWAIT++
                    elif [ "$SLEEPWAIT" \> "2" ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n"
                        biliwaitlist+=("$BILI_DIR$BILI_FOLDER")
                        break
                    else
                        BILI_FOLDER_VIS="`echo $BILI_FOLDER | sed 's/ /[:space:]/g'`"
                        printf "\n\e[1;40;32m[info]\e[0;0;96m : BILI-正在移动文件"$BILI_FOLDER_VIS".\n\n"
                        metasize="`du --max-depth=1 "$BILI_DIR$BILI_FOLDER" | awk '{print $1}' 2>/dev/null`"
                        mv "$BILI_DIR$BILI_FOLDER" "$savepath"&
                        ProgressBar "$savepath" "$BILI_FOLDER" "$metasize"
                        break
                    fi
                done
            done
        done
        if [ $flag2bili = 0 ];then
            printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : 录播姬目录没有检测到FLV录制视频文件\n"
        fi
        unset SLEEPWAIT BILI_FOLDER BILI_FLV flag2bili metasize

        #DDTV等待文件池
        if [ "${#ddtvwaitlist[*]}" \> "1" ];then
            for dwf in ${ddtvwaitlist[@]};do
                PID=`lsof "$dwf" 2>/dev/null | grep -v "PID" | awk '{print $2}'`
                if [ "$PID" = "" ];then
                    dwf_VIS="`echo ${dwf:57} | sed 's/ /[:space:]/g'`"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : DDTV池-正在移动文件池文件"$dwf_VIS"\n"
                    metasize="`ls -l "$dwf" | awk '{print $5}' 2>/dev/null`"
                    mv "$dwf" "$savepath"&
                    ProgressBar "$savepath" "${dwf:57}" "$metasize"
                    ddtvwaitlist=(${ddtvwaitlist[@]/$dwf})
                else
                    PIDw=`echo $PID | sed 's:^[[:digit:]]:[&]:g'`
                    PROCESS_NAME=`ps -ef | grep -w $PIDw | awk '{print $8,$9,$10}'`
                    `echo -e "【Warning】\n出现长时间文件被占用的情况，请求人工介入：\n被占用文件路径 : $dwf\n占用程序PID   : $PID\n占用程序名称   : $PROCESS_NAME" | mail -s "Warning::文件占用警报" orikiringi@gmail.com`
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : "$dwf"出现长时间文件占用现象，已邮件通知管理者。\n"
                fi
            done
        fi
        unset dwf PID metasize ddtvwaitlist PIDw PROCESS_NAME

        #BILI等待文件池
        if [ "${#biliwaitlist[*]}" \> "1" ];then
            for bwf in ${biliwaitlist[@]};do
                cd $bwf
                totalflv=`ls -l *.flv | grep "^-" | wc -l`
                for bwfn in *.flv;do
                    PID=`lsof $bwfn 2>/dev/null | grep -v "PID" | awk '{print $2}'`
                    if [ "$PID" = "" ];then
                        let totalflv--
                    fi
                done
                if [ "$totalflv" = "0" ];then
                    bwf_VIS="`echo ${bwf:38} | sed 's/ /[:space:]/g'`"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : BILI池-正在移动文件池文件"$bwf_VIS"\n"
                    metasize=`du --max-depth=1 "$bwf" | awk '{print $1}' 2>/dev/null`
                    mv "$bwf" "$savepath"&
                    ProgressBar "$savepath" "${bwf:38}" "$metasize"
                else
                    PIDw=`echo $PID | sed 's:^[[:digit:]]:[&]:g'`
                    PROCESS_NAME=`ps -ef | grep -w $PIDw | awk '{print $8,$9,$10}'`
                    `echo -e "【Warning】\n出现长时间文件被占用的情况，请求人工介入：\n被占用文件路径 : $bwf\n占用程序PID   : $PID\n占用程序名称   : $PROCESS_NAME" | mail -s "Warning::文件占用警报" orikiringi@gmail.com`
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : "$bwf"出现长时间文件占用现象，已邮件通知管理者。\n"
                fi
            done
        fi
        unset bwf totalflv metasize biliwaitlist PIDw PROCESS_NAME
    else
        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 检测到直播结束但是没有检测到任何的录播文件。\n"
        `echo -e "【Warning】\n检测到直播结束但是没有检测到任何的录播文件，请求人工介入。" | mail -s "Warning::文件疑似缺失警报" orikiringi@gmail.com`
    fi
    printf "\n\e[1;40;32m[info]\e[0;0;96m : 文件移动阶段结束，返回直播间监视。\n"
}

##main##
#echo "This is the mail body" | mail -s "1234" orikiringi@gmail.com
#echo -e "This is the mail body\n1234\n1234\n12321321\nqeqw" | mail -s "1234" orikiringi@gmail.com
#echo "\e[0;90;32m[info]\e[0;0;96m : "${uname[$allcount]}"已开播"
#echo "\e[0;90;32m[info]\e[0;0;96m : \""${titlelist[$allcount]}"\""
header
#show
#while :;do
#    infosys
#    occupychk
#done
testarea
occupychk
