#!/bin/bash

alloc_lic=$(staffcop drm list account | awk  'FNR>1 {print $1, $2}' | grep -i "yes" | awk '{print $1}')

for list in ${alloc_lic[@]}; 
do 
	prep_lic+=$(printf "\'%s\', " $list)
done

echo -n "SELECT DISTINCT acc.user_name, acc.guid, acc.full_name, aa.guid, ARRAY(SELECT aa.computer_name) FROM agent_event ae JOIN agent_account acc ON ae.account_id=acc.id JOIN agent_agent aa ON ae.agent_id=aa.id WHERE acc.guid IN ( ${prep_lic} '1') " | staffcop sql 

exist_lic=$(echo -n "SELECT DISTINCT acc.guid FROM agent_event ae JOIN agent_account acc ON ae.account_id=acc.id JOIN agent_agent aa ON ae.agent_id=aa.id WHERE acc.guid IN ( ${prep_lic} '1') " | staffcop sql -t)


for list_alloc in ${exist_lic};
do
	for list_exist in ${alloc_lic}; 
	do
		if [[ "$list_alloc" != "$list_exist" ]]; then
			
			ready_lic+=$(printf "%s \n" $list_alloc)
		fi
	done
done

for list in ${ready_lic};
do
	printf "%s\n"  $list
done
