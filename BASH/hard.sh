#!/bin/bash

storage="archive2"
HEAD="DATABASES = {"
TEMPLATE="'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'staffcop',
        'USER': 'staffcop',
        'PASSWORD': 'xxx',
        'HOST': '',
        'PORT': '',
    }"

#printf "$TEMPLATE\n"
KEY=$(grep -iPo "(?<='PASSWORD':\s').*[^',]" /etc/staffcop/config)

TEMPLATE=$(printf "${TEMPLATE}\n" | sed -e "s:xxx:${KEY}:")


new_config=$(printf "${TEMPLATE}\n" | sed -e "s:default:$storage:; 2,3s:staffcop:$storage:")

#--FOR-DEBAGGING--#
#printf "" > new_config.txt
#printf "$HEAD\n" >> new_config.txt
#printf "${TEMPLATE[@]},\n" >> new_config.txt
#printf "$new_config\n" >> new_config.txt

CORE=$(grep -Pizo "((?=').*\s*}?,?)" new_config.txt | tr -d '\0')
#CORE=$(grep -Pizo "((?=').*\s*}?,?)(\s*,?\s*)" ready_config.txt)

printf "" > ready_config.txt
printf "$HEAD\n" >> ready_config.txt
printf "$CORE,\n" >> ready_config.txt
printf "$new_config\n}\n" >> ready_config.txt

