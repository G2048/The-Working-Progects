#!/bin/bash

variable="one two three four five"

set -- $variable
# Значения позиционных параметров берутся из "$variable".

first_param=$1
second_param=$2
echo "первый параметр = $first_param"            # one
echo "второй параметр = $second_param"           # two
echo "остальные параметры = $remaining_params"

shift; shift        # сдвиг двух первых параметров.
remaining_params="$*"

echo
echo "первый параметр = $first_param"            # one
echo "второй параметр = $second_param"           # two
echo "остальные параметры = $remaining_params"   # three four five

echo; echo

# Снова.
set -- $variable
first_param=$1
second_param=$2
echo "первый параметр = $first_param"             # one
echo "второй параметр = $second_param"            # two
echo "остальные параметры = $remaining_params"

# ======================================================

set --
# Позиционные параметры сбрасываются, если не задано имя переменной.

first_param=$1
second_param=$2
echo "первый параметр = $first_param"            # (пустое значение)
echo "второй параметр = $second_param"           # (пустое значение)
echo "остальные параметры = $remaining_params"

exit 0
