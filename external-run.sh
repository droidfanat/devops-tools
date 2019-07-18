#!/bin/bash


# docker-compose file on base 64 
DOCKER=dmVyc2lvbjogJzMuMycKCnNlcnZpY2VzOgogIHJ1bm5lcjoKICAgIGltYWdlOiB4ZG9vbTg4L2FydHJ1bm5lcjpsYXRlc3QKICAgIHJlc3RhcnQ6IGFsd2F5cwogICAgdm9sdW1lczoKICAgICAgLSAvZXRjL3Bhc3N3ZDovZXRjL3Bhc3N3ZDpybwogICAgICAtIC9ldGMvZ3JvdXA6L2V0Yy9ncm91cDpybwogICAgICAtIC4vY29uZmlnL2dpdGxhYi1ydW5uZXI6L2V0Yy9naXRsYWItcnVubmVyCiAgICAgIC0gJy92YXIvcnVuL2RvY2tlci5zb2NrOi92YXIvcnVuL2RvY2tlci5zb2NrJwogICAgZW52aXJvbm1lbnQ6IA==


if [ ! -d "config" ]; then
   mkdir "config"
fi



baner(){
printf "\033c"  
printf "\n\n"  

printf "\t\t%s\n" '  _____ _      _____     _____  _    _ _   _ _   _ ______ _____    _____  ________      __'
printf "\t\t%s\n" ' / ____| |    |_   _|   |  __ \| |  | | \ | | \ | |  ____|  __ \  |  __ \|  ____\ \    / /' 
printf "\t\t%s\n" '| |    | |      | |     | |__) | |  | |  \| |  \| | |__  | |__) | | |  | | |__   \ \  / /'
printf "\t\t%s\n" '| |    | |      | |     |  _  /| |  | | . ` | . ` |  __| |  _  /  | |  | |  __|   \ \/ /'
printf "\t\t%s\n" '| |____| |____ _| |_    | | \ \| |__| | |\  | |\  | |____| | \ \  | |__| | |____   \  /'
printf "\t\t%s\n" ' \_____|______|_____|   |_|  \_\\____/|_| \_|_| \_|______|_|  \_\ |_____/|______|   \/ '
printf "\t\t%s\n" ''
printf "\t\t%s\n" 'v0.1_dev' 

printf "\n\n\n\n\n\n\n\n"
} 



create(){
	echo "config/$(echo $NAME | base64)"
	if [ ! -d "config/$(echo $NAME | base64)" ]; then
           mkdir  "config/$(echo $NAME | base64)"
           mkdir  "config/$(echo $NAME | base64)/config"
           mkdir  "config/$(echo $NAME | base64)/config/gitlab-runner"
           echo "$DOCKER" | base64 -d > config/$(echo $NAME | base64)/docker-compose.yml
           echo -e "\n"'         - ENV_TOCKEN='$TOCKEN'' >> config/$(echo $NAME | base64)/docker-compose.yml
           echo -e '         - ENV_URL='$URL'' >> config/$(echo $NAME | base64)/docker-compose.yml
           echo -e '         - ENV_TAG=null ' >> config/$(echo $NAME | base64)/docker-compose.yml
           echo -e '         - ENV_NAME='$(hostname)'' >> config/$(echo $NAME | base64)/docker-compose.yml
	   cd config/$(echo $NAME | base64)
      export UID=$UID
      docker pull xdoom88/artrunner:latest
      docker-compose up -d
	   sleep 3
	   echo $(docker-compose exec -T runner sh -c '/setup.sh' )
      else
      echo runner on thos project ready. 
	fi	
}


down(){
   cd $1
   docker-compose down
   cd ../../
 
}

clean(){
rm -rf $1
}



#############################
# The command line cleanAll #
#############################


cleanAll() {
  local x;
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
      down "$e"
      clean "$e"
  done
}


#############################
# The command line add      #
#############################


add_external_gitlab(){
    echo "https://docs.gitlab.com/ee/ci/runners/ "
    read -p "Specify the following URL during the Runner setup:"
    URL=$REPLY
    read -p "Use the following registration token during setup:"
    TOCKEN=$REPLY
    NAME=$URL"_"$TOCKEN

   if [[ $TOCKEN == *null* ]]; then
       echo "Invalid token"
   else
       create
   fi
}



get_project_of_gitlab(){

  IFS=$'\n'
  num=1
  printf "\t%s\n" 'Read the manual to get the token. https://git.artjoker.ua/erik/cli-runner/blob/master/README_RU.md'
  printf "%s\t\t\t%s\t\t\t\t\t\t\t%s\n" "NUMBER"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'

  for var in $(curl --globoff --request GET --header "PRIVATE-TOKEN: $P_TOCKEN" -s "https://git.artjoker.ua/api/v4/projects?per_page=1000" | jq '(.[] | "\(.id):\(.name)")')
  do
       count=0
        for i in $(echo ${var//'"'/''} | tr ":" "\n")
        do
          a[$count]=$i
          (( ++count ))
        done
        list_index[$num]=${a[0]}
        printf "%i)\t\t\t%s\t\t\t\t\t\t\t%s\n" $num ${a[1]}
        (( ++num ))


  done


 if [ $num -gt 0 ]; then
     read -p "Set project number: "
       if [ $REPLY -le $num ] ; then 
           NAME=$(curl --globoff --request GET --header "PRIVATE-TOKEN: $P_TOCKEN" -s "https://git.artjoker.ua/api/v4/projects/${list_index[$REPLY]}/" | jq '(.name)')
           NAME=${NAME//'"'/''}
           TOCKEN=$(curl --globoff --request GET --header "PRIVATE-TOKEN: $P_TOCKEN" -s "https://git.artjoker.ua/api/v4/projects/${list_index[$REPLY]}/" | jq '(.runners_token)')
           TOCKEN=${TOCKEN//'"'/''}

           if [[ $TOCKEN == *null* ]]; then
             echo "Permission denied! You are not maintainer"
           else
            create
           fi
       fi
 fi


}


#############################
# The command line list     #
#############################


list(){
  local x;
  printf "%s\t\t\t\t\t\t\t%s\n"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
       
       cd $e
       

       if [[ $(docker-compose ps runner) == *'Up'* ]] ; then
          printf "%s\t\t\t\t\t\t\t\t%s\n"  "$(echo ${e//'config/'/""} | base64 --decode)" "UP"
       else
          printf "%s\t\t\t\t\t\t\t\t%s\n"  $(echo ${e//'config/'/""} | base64 --decode) "DOWN"  
       fi
       cd ../../
  done
}


#############################
# The command line stop     #
#############################

stop(){
  local x;
  local num=0
  local array
  printf "%s\t\t\t%s\t\t\t\t\t\t\t%s\n" "NUMBER"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
       cd $e       
       if [[ $(docker-compose ps runner) == *'Up'* ]] ; then
          (( ++num ))
          array[$num]=$e
          printf "%i)\t\t\t%s\t\t\t\t\t\t\t%s\n" $num $(echo ${e//'config/'/""} | base64 --decode) "UP"       
       fi
       cd ../../
  done

  if [ $num -gt 0 ]; then
     read -p "Set project number: "
       if [ $REPLY -le $num ] ; then
          printf "STOP \t\t\t%s\t\t\t\t\t\t\t%s\n" "$(echo ${array[$REPLY]//'config/'/""} | base64 --decode)" "EXECUTED"
          cd ${array[$REPLY]} 
          docker-compose down
          cd ../../
       fi
  fi
  
}

#############################
# The command line start    #
#############################

start(){
  local x;
  local num=0
  local array
  printf "%s\t\t\t%s\t\t\t\t\t\t\t%s\n" "NUMBER"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
       cd $e       
       if [[ $(docker-compose ps runner) != *'Up'* ]] ; then
          (( ++num ))
          array[$num]=$e
          printf "%i)\t\t\t%s\t\t\t\t\t\t\t%s\n" $num $(echo ${e//'config/'/""} | base64 --decode) "DOWN"       
       fi
       cd ../../
  done

  if [ $num -gt 0 ]; then
     read -p "Set project number: "
       if [ $REPLY -le $num ] ; then
          printf "START \t\t\t%s\t\t\t\t\t\t\t%s\n" "$(echo ${array[$REPLY]//'config/'/""} | base64 --decode)" "EXECUTED"
          cd ${array[$REPLY]} 
          docker pull xdoom88/artrunner:latest
          docker-compose up -d
          cd ../../
       fi
  fi
  
}


#############################
# The command line remove   #
#############################


remove(){
  local x;
  local num=0
  local array
  printf "%s\t\t\t%s\t\t\t\t\t\t\t%s\n" "NUMBER"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
          (( ++num ))
          array[$num]=$e
          printf "%i)\t\t\t%s\t\t\t\t\t\t\t%s\n" $num $(echo ${e//'config/'/""} | base64 --decode) "UP"       
  done

  if [ $num -gt 0 ]; then
     read -p "Set project number: "
       if [ $REPLY -le $num ] ; then
          printf "STOP \t\t\t%s\t\t\t\t\t\t\t%s\n" "$(echo ${array[$REPLY]//'config/'/""} | base64 --decode)" "EXECUTED"

          cd ${array[$REPLY]}
           if [[ $(docker-compose ps runner) == *'Up'* ]] ; then
               docker-compose down    
           fi
          cd ../../
        clean ${array[$REPLY]}     
       fi
  fi
  
}


#############################
# The command line startAll #
#############################


start_all(){
  local x;
  printf "%s\t\t\t\t\t\t\t%s\n"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
       
       cd $e
       

       if [[ $(docker-compose ps runner) != *'Up'* ]] ; then
          docker pull xdoom88/artrunner:latest
          docker-compose up -d  
          printf "%s\t\t\t\t\t\t\t%s\n"  $(echo ${e//'config/'/""} | base64 --decode) "UP"
       fi
       cd ../../
  done
}

############################
# The command line stopAll #
############################

stop_all(){
  local x;
  printf "%s\t\t\t\t\t\t\t%s\n"  "NAME" "STATUS"
  echo '------------------------------------------------------------------------------------'
  for e in "$1"/*; do
    x=${e##*/}
    if [ ! -d $e ]; then
    return 1 
    fi
       
       cd $e
       
       if [[ $(docker-compose ps runner) == *'Up'* ]] ; then
          docker-compose down 
          printf "%s\t\t\t\t\t\t\t%s\n"  $(echo ${e//'config/'/""} | base64 --decode) "DOWN"
       fi
       cd ../../
  done
}



#########################
# The command line help #
#########################
display_help() {
    printf "\t%s\n" '                                    HELP                                            '    
    printf "\t%s\n" '------------------------------------------------------------------------------------'
    printf "\t%s\n" 'On first start execute command ./run.sh --add and follow the instructions'


    printf "\n\t%s\n" "Usage: {--add|--stop|--start|--list --help}"
    printf "\t%s\n"
    printf "\t%s\n" "    2), or --add            "
    printf "\t%s\n" "    4), or --stop           "
    printf "\t%s\n" "    5), or --start          "
    printf "\t%s\n" "    3), or --list           "
    printf "\t%s\n" "    6), or --stopAll       "
    printf "\t%s\n" "    7), or --startAll      "
    printf "\t%s\n" "    8), or --remove         "
    printf "\t%s\n" "   -h, or --help           "


    echo
    # echo some stuff here for the -a or --add-options 

}

baner



display_help



read -p "Set comand: "

case $REPLY in
    1|--eraseAll)
    echo eraseAll runner 
    cleanAll "config"
    shift # past argument=value
    ;;
    2|--add)
    add_external_gitlab
    echo "add new runer"
    shift # past argument=value
    ;;
    3|--list)
    list "config"
    shift # past argument=value
    ;;
    4|--stop)
    stop "config"
    shift # past argument=value
    ;;
    5|--start)
    start "config"
    shift # past argument=value
    ;;
    6|--stopAll)
    stop_all "config"
    list "config"
    shift # past argument=value
    ;;
    7|--startAll)
    start_all "config"
    list "config"
    shift # past argument=value
    ;;
    8|--remove)
    remove "config"
    shift # past argument=value
    ;;
    h|--help)
    display_help
    shift # past argument with no value
    ;;
    *)
    display_help
          # unknown option
    ;;
esac

