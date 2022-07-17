#!/bin/bash 
#This is script created for assignment/revocatione"$choise" of license
#Example of running the script: bash ./script_for_licens.sh HWID.xlsx
#Press Ctrl+C to exist from script


#--This-is-function-perfoms-action-on-the-license--#
function LICENCE() {

	#_computers=($(grep -ioP "(((?<=,,)\S*(?=,,,))|(((?<={).*?(?=,))|((?<={).*?(?=,))|((?<=, ).*?((?=,)|(?=})))))(?=.*$choise)" ./newfile.csv ))
	_computers=($(grep -iP "$choice" ./newfile.csv  | awk -F, '{print $3}'))
	_accounts=($(grep -iP "$choice" ./newfile.csv  | awk -F, '{print $2}'))

	local num_computers=${#_computers[@]}
	local num_accounts=${#_accounts[@]}
	local index=0
	local i=1 #Variable for _config and _group

	while [[ $index -lt $num_computers ]]; do

		#printf "${_computers[$index]}\n"
		guid=$(printf "SELECT guid  FROM agent_account WHERE user_name ~* '%s'" "${_accounts[$index]}" | staffcop sql -t -A)
		hwid=$(printf "SELECT guid  FROM agent_agent WHERE computer_name ~* '%s'" "${_computers[$index]}" | staffcop sql -t -A)

		#printf "$hwid\n"
		staffcop drm $action1 agent $hwid >> /dev/null
		staffcop drm $action2 agent $hwid >> /dev/null
		staffcop drm $action2 account $guid >> /dev/null
		staffcop drm $action2 account $guid >> /dev/null

		#--Pull-the-config--#
		_config=($(grep -iP "$choice" ./newfile.csv  | awk -F\" NR==${i}'{print $4}'))

		#--Pull-the-label--#
		_groups=($(grep -iP "$choice" ./newfile.csv  | awk -F, NR==${i}'{print $4}'))

		#--Change-the-config--#
		printf "UPDATE agent_agent SET config_id=(SELECT id FROM agent_config WHERE name_ru ~* '%s') WHERE guid='%s'" "${_config}" "${hwid}" | staffcop sql -t -A

		#--Change-the-label(groups)--#
		printf "UPDATE agent_agent SET label='%s' WHERE guid='%s'" "${_groups}" "${hwid}" | staffcop sql -A -t
		
		#--Messages--#
		printf 'Licence is %s! for %s %s %s\n' "$action1" "$hwid" "${_computers[$index]}" "${_accounts[$index]}"
		printf 'The Config %s is changed!\n' "${_config}"
		printf 'The Group %s is changed!\n' "${_groups}"

		(( i++ ))
		(( index++ ))
	done

	#staffcop drm list agent
}


#--Choose-to-perfom-action-on-the-license--#
function main() {

	read -p "Do you want to Remove or Assign licens? (R/A) " -r _move
	case "$_move" in

		A|a)
		choice="вкл"
		action1="enable"
		action2="allocate"
		LICENCE
		;;

		R|r)
		choice="выкл"
		action1="disable"
		action2="release"
		LICENCE
		;;
	esac

	main $@
}



#--Check-file--#
if [[ -z "$1" ]]; then

	printf '\n\tPlease Enter the file name in current directory...\n\n'
	exit 1


elif [[ "$1" =~ [*xlsx] ]]; then

	read -p "Do You want create .txt file via Ssconvert or via Grep? (S/G?)" -r 
	named_file=$1

	if [[ "$REPLY" =~ ^[Ss*] ]]; then

		if [[ -x `command -v ssconvert` ]]; then

		ssconvert $named_file newfile.csv 2>/dev/null
		named_file="newfile.csv"
		main

		else

			read -p "Do You want to install ssconvert? (Yes/No?)" -r -t 30

			if [[ "$REPLY" =~ ^[Yy*] ]]; then
				sudo apt-get install gnumeric 
			else
				printf "Please install to ssconvert...\n"
			fi

			bash $0 $@
		fi

	#Не работает!!!!
	elif [[ "$REPLY" =~ ^[Gg*] ]]; then
		#Затычка! Если вдруг придумаю как парсить через греп - удалить строку
		bash $0 $@
	
		rm -rf ./tmp
		unzip "$named_file" -d ./tmp
		grep -iPo "(?<=<t>).*?(?=</t>)" ./tmp/xl/sharedStrings.xml > ./licence.txt
		named_file="licence.txt"
		main $named_file	
	fi
fi

