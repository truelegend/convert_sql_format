#!/bin/bash

# mysqldump -pmavenir --skip-opt --skip-triggers --skip-routines --skip-add-locks --skip-comments --no-create-info --complete-insert --compact mnode_cm_data > dump_only_data.sql

function usage
{
    echo -e "\e[1;33m usage:\e[0m\e[1;32m $0 origin.sql \e[0m \n \e[0m"

}

function convert_line
{
    str=`echo $1 | grep -oP "^INSERT INTO.*(?=\(.*VALUES)"`
    str1=`echo $1 | grep -oP "(?<=\().*(?=\) VALUES)"` 
    str2=`echo $1 | grep -oP "(?<=VALUES \().*(?=\))"` 
    
#    echo -e "str: $str \n"
#    echo -e "str1: $str1 \n"
#    echo -e "str2: $str2 \n"    


    OLD_IFS="$IFS"
    IFS=","
    str1_array=($str1)
    str2_array=($str2)

    str1_length=${#str1_array[@]}
    str2_length=${#str2_array[@]}
    if [ $str1_length -ne $str2_length ]
    then
       echo -e "$1 \n"
       #echo "$1"
       IFS="$OLD_IFS"
       exit
    fi
    i=0
    str=$str" set "
    while [ $i -lt $str1_length ]
    do
       #echo $str
       if [ $i -eq 0 ]
       then
           str=$str"${str1_array[i]}="${str2_array[i]}
       else
           str=$str",${str1_array[i]}="${str2_array[i]}
       fi
       let i++
    done
    IFS="$OLD_IFS"
    str=$str";"
    echo "$str"
#    return $str
}

if [[ $# -ne 1 ]]; then
  #statements
  usage
  echo "wrong paramter numbers, exit...."
  exit
fi

OUTPUT_SQL_FIL="output.sql"

cat /dev/null > $OUTPUT_SQL_FIL
cat /dev/null > tmp_output.sql

cat $1 | grep -vE '^INSERT INTO (`eventDefinition`|`causeCodeProto2Internal`|`causeCodeInternal2Proto`|`internalCauseCodeToAction`|`causeCodeProto`|`causeCodeInternal`|`actOnSipRspCode`|`tmmTableFilenameMap`|`activeAlarm`|`allowedDomainNames`|`allowedNetworkAccessTypes`|`LITargets`|`LITargetsOtherIdentities`|`SvcErr_InterCc_map`|`perfMonObjects`|`sipnorm_action`|`sipnorm_applyaction`|`sipnorm_ruleelement`|`sipnorm_ruleset`|`sipnorm_sub`|`tableInstance`|`oam_system_version`|`userInfo`|`trans_action_elem`|`trans_profile`|`trans_rule_elem`|`trans_rule_set`)' >> tmp_output.sql


echo -e "the output sql file's name is : $OUTPUT_SQL_FIL \n"
echo "in progress...."

#for line in `cat $1`

echo "USE mnode_cm_data;" >> $OUTPUT_SQL_FIL
echo "SET UNIQUE_CHECKS=0;" >> $OUTPUT_SQL_FIL
echo "SET FOREIGN_KEY_CHECKS=0;" >> $OUTPUT_SQL_FIL
echo "SET SQL_MODE='NO_AUTO_VALUE_ON_ZERO';" >> $OUTPUT_SQL_FIL


cat tmp_output.sql | while read line
do
#    echo $line
    if [[ $line =~ ^INSERT.*\;$ ]]
    then
        echo `convert_line "$line"` >> $OUTPUT_SQL_FIL
    else
        echo -e "this line is not correct: $line\n"
        echo "exit!"
        exit
    fi
done

echo "done!"
