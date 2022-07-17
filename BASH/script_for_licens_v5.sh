#!/bin/bash 
#This is script created for assignment/revocatione"$choice" of license
#Example of running the script: bash ./script_for_licens.sh HWID.xlsx
#Press Ctrl+C to exist from script

START_TIME=$(date +%s)

#--This-is-function-perfoms-action-on-the-license--#
function LICENCE() {

	_computers=($(awk -F, 'FNR > 1 {print $3}' ./newfile.csv))
	_accounts=($(awk -F, 'FNR > 1 {print $2}' ./newfile.csv))

	#--Pull-the-config--#
	_config=($(awk -F\" 'FNR > 1 {print $4}' ./newfile.csv))
	
	#--Pull-the-label--#
	_groups=($(awk -F, 'FNR > 1 {print $4}' ./newfile.csv))

	#--Choise-actions--#
	choice=($(awk -F, 'FNR > 1 {print $6}' ./newfile.csv))

	local num_computers=${#_computers[@]}
	local index=0

	while [[ $index -lt $num_computers ]]; do

		#printf "${_computers[$index]}\n"
		guid=$(printf "SELECT guid FROM agent_account WHERE user_name ~* '%s'" "${_accounts[$index]}" | staffcop sql )
		hwid=$(printf "SELECT guid FROM agent_agent WHERE computer_name ~* '%s'" "${_computers[$index]}" | staffcop sql )

		#printf "$hwid\n"
		#printf "${choice[$index]}\n"
		if [[ "${choice[$index]}" = 'вкл' ]]; then

			action1="enable"
			action2="allocate"

		elif [[ "${choice[$index]}" = 'выкл' ]]; then

			action1="disable"
			action2="release"
		fi

		staffcop drm $action1 agent $hwid >> /dev/null
		staffcop drm $action2 agent $hwid >> /dev/null
		staffcop drm $action2 account $guid >> /dev/null
		staffcop drm $action2 account $guid >> /dev/null


		#--Change-the-config--#
		printf "UPDATE agent_agent SET config_id=(SELECT id FROM agent_config WHERE name_ru='%s') WHERE guid='%s'" "${_config[$index]}" "${hwid}" | staffcop sql
		printf 'The Config %s is changed!\n' "${_config[$index]}"

		#--Change-the-label(groups)--#
		printf "UPDATE agent_agent SET label='%s' WHERE guid='%s'" "${_groups[$index]}" "${hwid}" | staffcop sql 
		printf 'The Group %s is changed!\n' "${_groups[$index]}"
		
		#--Messages--#
		printf 'Licence is %s! for %s %s %s\n\n' "$action1" "$hwid" "${_computers[$index]}" "${_accounts[$index]}"

		(( index++ ))
	done

	#staffcop drm list agent
}


#--Check-file--#
if [[ -z "$1" ]]; then

	printf '\n\tPlease Enter the file name in current directory...\n\n'
	exit 1


elif [[ "$1" =~ [*xlsx] ]]; then

	if [[ -x `command -v ssconvert` ]]; then

	ssconvert "$1" newfile.csv 2>/dev/null
	LICENCE

	else

		read -p "Do You want to install ssconvert? (Yes/No?)" -r -t 30

		if [[ "$REPLY" =~ ^[Yy*] ]]; then
			sudo apt-get install gnumeric 
		else
			printf "Please install to ssconvert...\n"
		fi

		bash $0 $@
	fi

fi

END_TIME=$(date +%s)

printf '\n\nTotal people: %s\n' "${#_computers[@]}"
printf 'Total Time Executing of script: %d sec\n\n' "$(( END_TIME - START_TIME ))"
