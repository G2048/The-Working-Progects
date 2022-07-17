#!/bin/bash
# This is script checking and counting to exist of a files in the DB
# Key "--full_data" executed ALL data into DB from /upload/

START_TIME=$(date +%s)
#--Initialization-a-variables--#
count=0
count_of_success=0
count_of_failure=0

# 1.1 Input is currentState($1) and totalState($2)
function ProgressBar {

        let _progress=(${1}*100/${2}*100)/100
        let _done=(${_progress}*4)/10
        let _left=40-$_done
        # Build progressbar string lengths
        _fill=$(printf "%${_done}s")
        _empty=$(printf "%${_left}s")

        printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%% (${1} / ${2} files)"
}


#--Counting-the-files-into-file-storage--#
printf "\nCounting the files on upload....\n"
REAL_EXISTENCE_FILE=(`find /var/lib/staffcop/upload/filedata/by_date/* -type f`)
REAL_EXISTENCE_FILE_SIZE=${#REAL_EXISTENCE_FILE[@]}

#--Deleting-data-from-file-storage--#
function DELETING_DATA() {

        read -p "You Want To Trancate The Files? Yes/No? " -r -t 30
        if [[ $REPLY =~ ^[Yy*] ]]; then
                _count=0
                array_of_existen=(`cat Exists_files.txt | sort`)
                size_array_of_existen=${#array_of_existen[@]}
                printf "" > `pwd`/Orphaned_files.txt

                for line_from_real_upload in ${REAL_EXISTENCE_FILE[@]} ; do

                        while [[ $_count -lt $size_array_of_existen ]] ; do

                                line_from_file="/var/lib/staffcop/upload/${array_of_existen[@]:$_count:1}"

                                if [[ "$line_from_real_upload" != $line_from_file ]]; then

                                        #printf "\n$line_from_file\n"
                                        printf "/var/lib/staffcop/upload/$line_from_file\n" >> `pwd`/Orphaned_files.txt
                                        #sudo cp -a "/var/lib/staffcop/upload/${line_from_real_upload}" ~/backup_upload && sudo rm -f "/var/lib/staffcop/upload/${line_from_real_upload}" && printf "Data is deleted!\n"
                                fi

                                (( _count++ ))
                                ProgressBar $_count $REAL_EXISTENCE_FILE_SIZE
                        done
                done
        else
                exit 0
        fi
        printf "\n"
}

#--IF-Exists_files.txt-is-exist-move-on-yo-deletion--#
if [[ -e $(pwd)/Exists_files.txt ]]
then
        read -p "Exists_files.txt Is Exist! You want to delete data? (Yes/No?) " -r -t 30
        if [[ "$REPLY" =~ ^[Yy*] ]]
        then
                DELETING_DATA
        fi
fi


#--Taking-data--#
if [[ "$1" == "--full_data" ]]
then
        string_for_array="SELECT data FROM agent_attachedfile"
else
        string_for_array="SELECT att.data
                 FROM agent_event ae
                    JOIN agent_eventtype aet
                        ON ae.event_type_id=aet.id
                    JOIN agent_attachedfile att
                        ON ae.attached_file_id=att.id
                    JOIN agent_account acc
                       ON acc.id=ae.account_id
                    JOIN agent_agent aa
                        ON ae.agent_id=aa.id ORDER BY 1;"
fi

#--Filling-the-array--#
printf "Filling the array...\n"
array=(`echo "$string_for_array" | staffcop sql | awk '/filedata/{print}'`)

#--Size-of-array--#
size_of_array=${#array[@]}

#--Devastation-of-files-with-data--#
printf "Cleaning file\n"
printf "" > $(pwd)/Exists_files.txt
printf "" > $(pwd)/None-existent_files.txt

#--Data-comparison--#
printf "Data comparison\n"
while [[ $count -lt $size_of_array ]]
do

   if [[ -e "/var/lib/staffcop/upload/${array[@]:${count}:1}" ]] #|| [[ -e "${array[@]:${count}:1}" ]]
    then
        printf "${array[@]:${count}:1}\n" >> $(pwd)/Exists_files.txt
        (( count_of_success++ ))

    else
        printf "${array[@]:${count}:1}\n" >> $(pwd)/None-existent_files.txt
        (( count_of_failure++ ))
    fi

    (( count++ ))
    ProgressBar $count $size_of_array

done

#--Checking-the-existence-of-files-with-data--#
if [[ -e $(pwd)/Exists_files.txt ]] && [[ -e $(pwd)/None-existent_files.txt ]]
then
    printf '\n%s and %s is Created!' "Exists_files.txt", "None-existent_files.txt"
else
    printf '\n%s and %s is not Created...' "Exists_files.txt", "None-existent_files.txt"
fi

END_TIME=$(date +%s)
#--Printing-the-results--#
printf "\n\nTotal Files: ${size_of_array}\n"
printf "Total Existent Files: ${count_of_success}\n"
printf "Total Non-existent files: ${count_of_failure}\n"
printf 'Total The Real Existent Files: %d\n' "$REAL_EXISTENCE_FILE_SIZE"
printf 'Total Orphaned Files: %d\n' "$(( REAL_EXISTENCE_FILE_SIZE - count_of_success ))" #Если получены отрицательные значения, то это значит что есть лишние записи в БД
printf 'Total Time Executing of script: %d sec\n\n' "$(( END_TIME - START_TIME ))"
DELETING_DATA

