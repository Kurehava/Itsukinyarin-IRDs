clear;liveflags=0;secflags=0;clfeflags=0;
biliroot="/home/nyarin/recordserver/BiliRecorder/"
ddtvroot="/home/nyarin/recordserver/DDTV2/tmp"
recordroot="/media/nyarin/Record-DISK/RecordFiles"
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
    i=0;
    str=""
    arr=("|" "/" "-" "\\")
    dir="$1"
    tar="$2"
    filename="$3"
    metasize="$4"
    #cp -r $dir$filename $tar 2>/dev/null&
    if [ "`ps -ef | grep -w '[c]p'| awk '{print $2}'`" != "" ];then
        while [ $i -ne 100 ]
        do
            #metasize="`du --max-depth=1 $dir$filename | awk '{print $1}' 2>/dev/null`"
            targsize="`du --max-depth=1 $tar$filename | awk '{print $1}' 2>/dev/null`"
            let statsize=$targsize*100/$metasize
            let chkdatas=$i+5
            let index=i%4
            sleep 0.1
            if [ $statsize -ge $chkdatas ];then
                let i+=5
                str+='='
            fi
            printf "\e[0;96;1m[%-20s][%d%%]%c\r" "$str" "$i" "${arr[$index]}"
        done
        printf "\n"
    else
        echo "CP has error skipping..."
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
                0) printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$unames" 已下播\n\e[1;40;32m[info]\e[0;0;96m : $titles\n";secflags=1;;
                *) printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : statuschk 返回值不为[1]开播，[2]下播的、任意一个。\n";;
            esac
            clfeflags=1
        fi
        sleep 2s
        if [ "$secflags" = "1" ];then
            printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : 检测到[ $list-$unames ]已经下播，触发安全休眠系统，安全休眠10分钟后自动唤醒。\n"
            sleep 10m;statuschk;liveflags=0;secflags=0;clfeflags=0;
            if [ "$status" = "0" ];then
                break;
            else
                printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : 检测到[ $list-$unames ]复播，进入循环检测系统。\n"
            fi
        fi
    done
    printf "-------------------------------------------\n"
}

function occupychk(){
    sleepplus=0;secfolder=$(date "+%Y-%m-%d");ddtvwaitlist=[];biliwaitlist=[];
    if [ $(date "+%H") \< "06" ];then
        savepath="$recordroot/$(date "+%Y")/$secfolder/$(date "+%m-%d")-daychangecover/"
    else
        savepath="$recordroot/$(date "+%Y")/$secfolder/$thifloder/"
    fi
    mkdir -p $savepath
    #DDTV
    cd "$ddtvroot/bilibili_$unames'_'$list/"
    
    for chklist in *.flv;do
        if [ "$chklist" = "*.flv" ];then
            printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : 没有检测到FLV录制视频文件\n"
        else
            while :;do
                if [ "`lsof $chklist | grep -v "PID" | awk '{print $2}'`" != "" ];then
                    printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n"
                    sleep 10m
                    let sleepplus++
                    if [ "$sleepplus" \>\= "2" ];then
                    printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : $chklist 持续被占用，本次将跳过此文件的移动。"
                        break
                    fi
                else
                    ProgressBar 
                    mv "$chklist" "$savepath"
                    break
                fi
            done
        fi
    done
    unset sleepplus
    #BilibiliRecord
    cd $biliroot
    for list in `ls -d */`;do
        if [ ${list:0:4} = $(date "+%Y") ];then
            cd $list;unset chklist;
            for chklist in *.flv;do
                while :;do
                    if [ "`lsof $chklist | grep -v "PID" | awk '{print $2}'`" != "" ] && [ "$sleepplus" \<\= "2"  ];then
                        printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n"
                        sleep 10m
                        let sleepplus++
                    elif [ "$sleepplus" \> "2" ];then
                        printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n"
                        biliwaitlist+=("$biliroot$list$chklist")
                        break
                    else
                        printf "\e[1;40;32m[info]\e[0;0;96m : >>>>>\n\e[1;40;32m[info]\e[0;0;96m : 正在移动文件"$list"\n"
                        metasize="`du --max-depth=1 "$biliroot$list" | awk '{print $1}' 2>/dev/null`"
                        mv "$biliroot$list" "$savepath"&
                        ProgressBar "$biliroot$list" "$savepath" "$chklist" "$matasize"
                        break
                    fi
                done
            done
        fi
    done
    unset sleepplus
}
##main##
#echo "\e[0;90;32m[info]\e[0;0;96m : "${uname[$allcount]}"已开播"
#echo "\e[0;90;32m[info]\e[0;0;96m : \""${titlelist[$allcount]}"\""
header
#show
while :;do
    infosys
    occupychk
done
