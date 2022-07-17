#!/bin/bash

#--Master-Option--#
wal_level = 'replica'
max_wal_senders = 5
wal_keep_segments = 32

hot_standby = 'on' 
hot_standby_feedback = 'on'

archive_mode = 'on'

max_wal_senders = 3
wal_compression = 'on' #Compression WAL

#--Optional-parameters--#
track_commit_timestamp = 'on'


#--Slave-Options--#
hot_standby = 'on'

wal_receiver_timeout = '300 sec'
