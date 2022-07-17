for i in {0..10000..33} 10000;do i=0$i
    printf -v p %0.2f ${i::-2}.${i: -2}
    percentBar $p $((COLUMNS-9)) bar
    printf '\r|%s|%6.2f%%' "$bar" $p
    read -srt .002 _ && break    # console sleep avoiding fork
done

#|███████████████████████████████████████████████████████████████████████|100.00%

clear; for i in {0..10000..33} 10000;do i=0$i
     printf -v p %0.2f ${i::-2}.${i: -2}
     percentBar $p $((COLUMNS-7)) bar
     printf '\r\e[47;30m%s\e[0m%6.2f%%' "$bar" $p
     read -srt .002 _ && break
done

