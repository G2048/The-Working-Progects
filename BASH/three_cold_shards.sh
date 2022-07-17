#!/bin/bash
# Example: three_cold_shards.sh -key [TABLESPACE]

if [[ -z $1 ]]; then exec $0 --help ; fi

function main() {
	
	_TABLESPACE="$1"
	_number_shards="$2"
	
	if [[ -z "$1" ]]; then _TABLESPACE="cold" ; fi
	if [[ -z "$2" ]]; then _number_shards="3" ; fi

	tree_shards=$(echo "SELECT relname FROM pg_class WHERE relkind='r' AND relname ~ 'agent_event_\d+' AND relname<(SELECT 'agent_event_' || replace( date_trunc('month', NOW())::date::text, '-', '_' ) ) ORDER BY 1 DESC LIMIT ${_number_shards}" | staffcop sql -t)


	for shard in $tree_shards; do
		printf "\nFreezing the $shard shard in $_TABLESPACE storage...\n"
		staffcop shard-freeze $shard $_TABLESPACE
	done
}


while [[ -n "$1" ]]; do
case $1 in
	
	"--show-tablespaces" | "-s") 

	t_spaces=$(echo "SELECT spcname FROM pg_tablespace WHERE spcname NOT IN ('pg_default', 'pg_global');" | staffcop sql -t)
	printf "The Current TableSpaces:\n\033[0;32m${t_spaces}\033[0m\n\n" 
	exit
	;;
	

	"--show-default" | "-d") 

	def_tablespace=$(echo "SELECT spcname FROM pg_tablespace WHERE spcname IN ('pg_default', 'pg_global');" | staffcop sql -t)
	printf "The Default TableSpaces:\n\033[0;32m${def_tablespace}\033[0m\n\n"
	exit
	;;

	
	"--freeze" | "-f")
	TABLESPACE="$2"
	;;


	"--antifreeze" | "-a")

	TABLESPACE="pg_default"
	;;

	"--number" | "-n")
	
	number_shards="$2"
	;;


	"--help" | "-h")

	show="-s, --show-tablespaces show current tablespaces"
	show_def="-d, --show-default show default tablespaces"
	show_antifreeze="-a, --antifreeze Antifreeze 3 Last Shards"
	show_help="-h, --help show this help"
	show_freeze="-f, --freeze Freeze 3 Last Shards"

	printf "Run: \n\t\033[0;32mthree_cold_shards.sh\033[0m \033[0;31m{command} TABLESPACE\033[0m\n\n"
	printf "Commands:\n${show}\n${show_def}\n${show_freeze}\n${show_antifreeze}\n${show_help}\n\n"
	exit
	;;

esac

shift

done

main "$TABLESPACE" "$number_shards"
#printf "\nShards for freezeing: $number_shards\n"
#printf "TABLESPACE: $TABLESPACE\n"
