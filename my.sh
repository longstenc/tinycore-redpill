#!/usr/bin/env bash

# my.sh (Batch Shell Script for rploader.sh)                 
# Made by Peter Suh

##### INCLUDES #########################################################################################################
source myfunc.h # my.sh / myv.sh common use 
########################################################################################################################

gitdomain="raw.githubusercontent.com"

mshellgz="my.sh.gz"
mshtarfile="https://raw.githubusercontent.com/PeterSuh-Q3/tinycore-redpill/master/my.sh.gz"

USER_CONFIG_FILE="/home/tc/user_config.json"

# ==============================================================================          
# Color Function                                                                          
# ==============================================================================          
function cecho () {                                                                                
#    if [ -n "$3" ]                                                                                                            
#    then                                                                                  
#        case "$3" in                                                                                 
#            black  | bk) bgcolor="40";;                                                              
#            red    |  r) bgcolor="41";;                                                              
#            green  |  g) bgcolor="42";;                                                                 
#            yellow |  y) bgcolor="43";;                                             
#            blue   |  b) bgcolor="44";;                                             
#            purple |  p) bgcolor="45";;                                                   
#            cyan   |  c) bgcolor="46";;                                             
#            gray   | gr) bgcolor="47";;                                             
#        esac                                                                        
#    else                                                                            
        bgcolor="0"                                                                 
#    fi                                                                              
    code="\033["                                                                    
    case "$1" in                                                                    
        black  | bk) color="${code}${bgcolor};30m";;                                
        red    |  r) color="${code}${bgcolor};31m";;                                
        green  |  g) color="${code}${bgcolor};32m";;                                
        yellow |  y) color="${code}${bgcolor};33m";;                                
        blue   |  b) color="${code}${bgcolor};34m";;                                
        purple |  p) color="${code}${bgcolor};35m";;                                
        cyan   |  c) color="${code}${bgcolor};36m";;                                
        gray   | gr) color="${code}${bgcolor};37m";;                                
    esac                                                                            
                                                                                                                                                                    
    text="$color$2${code}0m"                                                                                                                                        
    echo -e "$text"                                                                                                                                                 
}   

function st() {
echo -e "\e[35m$1\e[0m	\e[36m$2\e[0m	$3" >> /home/tc/buildstatus
echo -e "----------------------------------------------------------------------------" >> /home/tc/buildstatus
}

function checkmachine() {

    if grep -q ^flags.*\ hypervisor\  /proc/cpuinfo; then
        MACHINE="VIRTUAL"
        HYPERVISOR=$(dmesg | grep -i "Hypervisor detected" | awk '{print $5}')
        echo "Machine is $MACHINE Hypervisor=$HYPERVISOR"
    else
        MACHINE="NON-VIRTUAL"
    fi

}

function checkinternet() {

    echo -n "Checking Internet Access -> "
#    nslookup $gitdomain 2>&1 >/dev/null
    curl --insecure -L -s https://raw.githubusercontent.com/about.html -O 2>&1 >/dev/null

    if [ $? -eq 0 ]; then
        echo "OK"
    else
        cecho g "Error: No internet found, or $gitdomain is not accessible"
        
        gitdomain="giteas.duckdns.org"
        cecho p "Try to connect to $gitdomain......"
        nslookup $gitdomain 2>&1 >/dev/null
        if [ $? -eq 0 ]; then
            echo "OK"
        else
            cecho g "Error: No internet found, or $gitdomain is not accessible"
            exit 99
        fi
    fi

}

###############################################################################
# git clone redpill-load
function gitdownload() {

    git config --global http.sslVerify false   

    if [ -d "/home/tc/redpill-load" ]; then
        cecho y "Loader sources already downloaded, pulling latest !!!"
        cd /home/tc/redpill-load
        git pull
        if [ $? -ne 0 ]; then
           cd /home/tc    
           /home/tc/rploader.sh clean 
           git clone -b master "https://github.com/PeterSuh-Q3/redpill-load.git"
        fi   
        cd /home/tc
    else
        git clone -b master "https://github.com/PeterSuh-Q3/redpill-load.git"        
    fi

}

###############################################################################
# Write to json config file
function writeConfigKey() {

    block="$1"
    field="$2"
    value="$3"

    if [ -n "$1 " ] && [ -n "$2" ]; then
        jsonfile=$(jq ".$block+={\"$field\":\"$value\"}" $USER_CONFIG_FILE)
        echo $jsonfile | jq . >$USER_CONFIG_FILE
    else
        echo "No values to update"
    fi
}

function chkavail() {

    if [ $(df -h /mnt/${tcrppart} | grep mnt | awk '{print $4}' | grep G | wc -l) -gt 0 ]; then
        avail_str=$(df -h /mnt/${tcrppart} | grep mnt | awk '{print $4}' | sed -e 's/G//g' | cut -c 1-3)
        avail=$(echo "$avail_str 1000" | awk '{print $1 * $2}')
    else
        avail=$(df -h /mnt/${tcrppart} | grep mnt | awk '{print $4}' | sed -e 's/M//g' | cut -c 1-3)
    fi

    avail_num=$(($avail))
    
    echo "Avail space ${avail_num}M on /mnt/${tcrppart}"
}

checkinternet
gitdownload

if [ $gitdomain == "raw.githubusercontent.com" ]; then
    if [ $# -lt 1 ]; then
        getlatestmshell "ask"
    else
        if [ "$1" == "update" ]; then 
            getlatestmshell "noask"
            exit 0
        else
            getlatestmshell "noask"
        fi
    fi
fi

if [ $# -lt 1 ]; then
    showhelp 
    exit 99
fi

getvars "$1"

#echo "$TARGET_REVISION"                                                      
#echo "$MSHELL_ONLY_MODEL"                                                        
#echo "$TARGET_PLATFORM"                                            
#echo "$SYNOMODEL"                                      
#echo "$sha256"

postupdate="N"
userdts="N"
noconfig="N"
frmyv="N"
jot="N"

    while [[ "$#" > 0 ]] ; do

        case $1 in
        postupdate)
            postupdate="Y"
            ;;
            
        userdts)
            userdts="Y"
            ;;

        noconfig)
            noconfig="Y"
            ;;
         
        frmyv)
            frmyv="Y"
            ;;
            
        jot)
            jot="Y"
            ;;

        *)
            if [ $1 = "FS2500F" ]; then                                       
                echo                                                          
            elif [ $1 = "FS2500" ]; then                                      
                echo                                                          
            else                                                              
                if [ "$(echo $1 | sed 's/J//g')" != "$MODEL" ] && [ "$(echo $1 | sed 's/F//g')" != "$MODEL" ] && [ "$(echo $1 | sed 's/K//g')" != "$MODEL" ] && [ "$(echo $1 | sed 's/G//g')" != "$MODEL" ]; then
                    echo "Syntax error, not valid arguments or not enough options"
                    exit 0                                                        
                fi                                                                
            fi          
            ;;

        esac
        shift
    done

#echo $postupdate
#echo $userdts
#echo $noconfig
#echo $frmyv

echo

tcrppart="$(mount | grep -i optional | grep cde | awk -F / '{print $3}' | uniq | cut -c 1-3)3"

if [ $tcrppart == "mmc3" ]; then
    tcrppart="mmcblk0p3"
fi

echo
echo tcrppart is $tcrppart                                                  
echo

if [ ! -d "/mnt/${tcrppart}/auxfiles" ]; then
    cecho g "making directory  /mnt/${tcrppart}/auxfiles"  
    mkdir /mnt/${tcrppart}/auxfiles 
fi
if [ ! -h /home/tc/custom-module ]; then
    cecho y "making link /home/tc/custom-module"  
    sudo ln -s /mnt/${tcrppart}/auxfiles /home/tc/custom-module 
fi

local_cache="/mnt/${tcrppart}/auxfiles"

#if [ -d ${local_cache/extractor /} ] && [ -f ${local_cache}/extractor/scemd ]; then
#    echo "Found extractor locally cached"
#else
#    cecho g "making directory  /mnt/${tcrppart}/auxfiles/extractor"  
#    mkdir /mnt/${tcrppart}/auxfiles/extractor
#    sudo curl --insecure -L --progress-bar "https://$gitdomain/PeterSuh-Q3/tinycore-redpill/master/extractor.gz" --output /mnt/${tcrppart}/auxfiles/extractor/extractor.gz
#    sudo tar -zxvf /mnt/${tcrppart}/auxfiles/extractor/extractor.gz -C /mnt/${tcrppart}/auxfiles/extractor
#fi

echo
cecho y "TARGET_PLATFORM is $TARGET_PLATFORM"
cecho r "ORIGIN_PLATFORM is $ORIGIN_PLATFORM"
cecho c "TARGET_VERSION is $TARGET_VERSION"
cecho p "TARGET_REVISION is $TARGET_REVISION"
cecho y "SUVP is $SUVP"
cecho g "SYNOMODEL is $SYNOMODEL"  
cecho c "KERNEL VERSION is $KVER"  

st "buildstatus" "Building started" "Model :$MODEL-$TARGET_VERSION-$TARGET_REVISION"

#fullupgrade="Y"

cecho y "If fullupgrade is required, please handle it separately."

cecho g "Downloading Peter Suh's custom configuration files.................."

writeConfigKey "general" "kver" "${KVER}"

DMPM="$(jq -r -e '.general.devmod' $USER_CONFIG_FILE)"
if [ "${DMPM}" = "null" ]; then
    DMPM="DDSML"
    writeConfigKey "general" "devmod" "${DMPM}"
fi
cecho y "Device Module Processing Method is ${DMPM}"
if [ "${DMPM}" = "DDSML" ]; then
    jsonfile=$(jq 'del(.eudev)' /home/tc/redpill-load/bundled-exts.json) && echo $jsonfile | jq . > /home/tc/redpill-load/bundled-exts.json
elif [ "${DMPM}" = "EUDEV" ]; then
    jsonfile=$(jq 'del(.ddsml)' /home/tc/redpill-load/bundled-exts.json) && echo $jsonfile | jq . > /home/tc/redpill-load/bundled-exts.json
elif [ "${DMPM}" = "DDSML+EUDEV" ]; then
    cecho p "It uses both ddsml and eudev from /home/tc/redpill-load/bundled-exts.json file"
else
    cecho p "Device Module Processing Method is Undefined, Program Exit!!!!!!!!"
    exit 0
fi

curl -s --insecure -L --progress-bar "https://$gitdomain/PeterSuh-Q3/tinycore-redpill/master/custom_config.json" -O
curl -s --insecure -L --progress-bar "https://$gitdomain/PeterSuh-Q3/tinycore-redpill/master/rploader.sh" -O
#curl -s --insecure -L --progress-bar "https://$gitdomain/PeterSuh-Q3/rp-ext/master/rpext-index.json" -O

echo
if [ $jot == "N" ]; then    
cecho y "This is TCRP friend mode"
else    
cecho y "This is TCRP original jot mode"
fi

dtbfile=""     

if [ "${TARGET_PLATFORM}" = "v1000" ]; then
    dtbfile="ds1621p"
elif [ "${TARGET_PLATFORM}" = "geminilake" ]; then
    dtbfile="ds920p"
elif [ "${TARGET_PLATFORM}" = "dva1622" ]; then
    dtbfile="dva1622"
elif [ "${TARGET_PLATFORM}" = "ds2422p" ]; then
    dtbfile="ds2422p"
elif [ "${TARGET_PLATFORM}" = "ds1520p" ]; then
    dtbfile="ds1520p"
else
    echo "${TARGET_PLATFORM} does not require model.dtc patching "    
fi

if [ -f /home/tc/custom-module/${dtbfile}.dts ]; then
    sed -i "s/dtbpatch/redpill-dtb-static/g" custom_config.json
    sed -i "s/dtbpatch/redpill-dtb-static/g" custom_config_jun.json
fi

if [ $postupdate == "Y" ]; then
    cecho y "Postupdate in progress..."  
    sudo ./rploader.sh postupdate ${TARGET_PLATFORM}-7.1.1-${TARGET_REVISION}

    echo                                                                                                                                        
    cecho y "Backup in progress..."
    echo                                                                                                                                        
    echo "y"|./rploader.sh backup    
    exit 0
fi

if [ $userdts == "Y" ]; then
    
    cecho y "user-define dts file make in progress..."  
    echo
    
    cecho g "copy and paste user dts contents here, press any key to continue..."      
    read answer
    sudo vi /home/tc/custom-module/$dtbfile.dts

    cecho p "press any key to continue..."
    read answer

    echo                                                                                                                                        
    cecho y "Backup in progress..."
    echo                                                                                                                                        
    echo "y"|./rploader.sh backup    
    exit 0
fi

echo

if [ $noconfig == "Y" ]; then                            
    cecho r "SN Gen/Mac Gen/Vid/Pid/SataPortMap detection skipped!!"
    checkmachine
    if [ "$MACHINE" = "VIRTUAL" ]; then
        cecho p "Sataportmap,DiskIdxMap to blank for VIRTUAL MACHINE"
        json="$(jq --arg var "" '.extra_cmdline.SataPortMap = $var' user_config.json)" && echo -E "${json}" | jq . >user_config.json
        json="$(jq --arg var "" '.extra_cmdline.DiskIdxMap = $var' user_config.json)" && echo -E "${json}" | jq . >user_config.json        
        cat user_config.json
    fi
else 
    cecho c "Before changing user_config.json" 
    cat user_config.json
    echo "y"|./rploader.sh identifyusb

    if [ "$ORIGIN_PLATFORM" = "v1000" ]||[ "$ORIGIN_PLATFORM" = "r1000" ]||[ "$ORIGIN_PLATFORM" = "geminilake" ]; then
        cecho p "Device Tree based model does not need SataPortMap setting...."     
    else    
        ./rploader.sh satamap    
    fi    
    cecho y "After changing user_config.json"     
    cat user_config.json        
fi

echo
echo
DN_MODEL="$(echo $MODEL | sed 's/+/%2B/g')"
echo "DN_MODEL is $DN_MODEL"

cecho p "DSM PAT file pre-downloading in progress..."

URL="https://global.download.synology.com/download/DSM/release/${TARGET_VERSION}/${TARGET_REVISION}${SUVP}/DSM_${DN_MODEL}_${TARGET_REVISION}.pat"

cecho y "$URL"

patfile="/mnt/${tcrppart}/auxfiles/${SYNOMODEL}.pat"                                         
                                                                                             
if [ -f ${patfile} ]; then                                                               
    cecho r "Found locally cached pat file ${SYNOMODEL}.pat in /mnt/${tcrppart}/auxfiles"
    cecho b "Downloadng Skipped!!!"
st "download pat" "Found pat    " "Found ${SYNOMODEL}.pat"
else
    
    chkavail
    if [ $avail_num -le 390 ]; then
        echo "No adequate space on ${local_cache} to download file into cache folder, clean up PAT file now ....."
        rm -f ${local_cache}/*.pat
    fi
st "download pat" "Downloading pat  " "${SYNOMODEL}.pat"        
    STATUS=`curl --insecure -w "%{http_code}" -L "${URL}" -o ${patfile} --progress-bar`
    if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
       echo  "Check internet or cache disk space"
       exit 99
    fi

    os_sha256=$(sha256sum ${patfile} | awk '{print $1}')                                
    cecho y "Pat file  sha256sum is : $os_sha256"                                       

    verifyid="${sha256}"                                                                
    cecho p "verifyid  sha256sum is : $verifyid"                                        

    if [ "$os_sha256" == "$verifyid" ]; then                                            
        cecho y "pat file sha256sum is OK ! "                                           
    else                                                                                
        cecho y "os sha256 verify FAILED, check ${patfile}  "                           
        exit 99                                                                         
    fi

fi



echo
cecho g "Loader Building in progress..."
echo

if [ $frmyv == "Y" ]; then
    parmfrmyv="frmyv"
else
    parmfrmyv=""
fi

if [ "$TARGET_VERSION" == "7.2" ]; then
    TARGET_VERSION="7.2.0"
    if [ "$ORIGIN_PLATFORM" == "apollolake" ]||[ "$ORIGIN_PLATFORM" == "geminilake" ]; then
       jsonfile=$(jq 'del(.cgetty)' /home/tc/redpill-load/bundled-exts.json) && echo $jsonfile | jq . > /home/tc/redpill-load/bundled-exts.json
       sudo rm -rf /home/tc/redpill-load/custom/extensions/cgetty
    fi   
fi

if [ "$MODEL" == "SA6400" ]; then
    cecho g "Remove Exts for SA6400 test (cgetty,acpid,smb3-multi ) ..."
    jsonfile=$(jq 'del(.cgetty)' /home/tc/redpill-load/bundled-exts.json) && echo $jsonfile | jq . > /home/tc/redpill-load/bundled-exts.json
    sudo rm -rf /home/tc/redpill-load/custom/extensions/cgetty
fi

if [ $jot == "N" ]; then
    echo "n"|./rploader.sh build ${TARGET_PLATFORM}-${TARGET_VERSION}-${TARGET_REVISION} withfriend ${parmfrmyv}
else
    echo "n"|./rploader.sh build ${TARGET_PLATFORM}-${TARGET_VERSION}-${TARGET_REVISION} static ${parmfrmyv}
fi

if [ $? -ne 0 ]; then
    cecho r "An error occurred while building the loader!!! Clean the redpill-load directory!!! "
    ./rploader.sh clean
fi

if  [ -f /home/tc/custom-module/redpill.ko ]; then
    cecho y "Removing redpill.ko ..."
    rm -rf /home/tc/custom-module/redpill.ko
fi

echo                                                                                                                                                                           
cecho y "Backup in progress..."                                                                                                                                                
echo
                                                                                                                                                                           
rm -rf /home/tc/old                                                                                                                                                       
rm -rf /home/tc/oldpat.tar.gz
st "cleanbuild" "Cleaning build dir" "Build directory cleaned"
cecho r "Cleaning redpill-load/cache directory!"
rm -f /home/tc/redpill-load/cache/*

cecho y "Delete all PAT files except for the final created PAT file (including decryption PAT)!"
if [ $(ls /mnt/${tcrppart}/auxfiles/*.pat | grep -v ${SYNOMODEL}.pat | wc -l ) -gt 0 ]; then
find /mnt/${tcrppart}/auxfiles -name "*.pat" ! -name "${SYNOMODEL}.pat" -type f -delete
fi    

rm -f /home/tc/custom-module
st "backuploader" "Making changes persistent to the Loader Backup File" ""
echo "y"|./rploader.sh backup                                                                                                                                         
st "finishloader" "Loader build status" "Finished building the loader"
exit 0
