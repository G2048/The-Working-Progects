#!/usr/bin/python
#Copipast from https://github.com/amarao/blktop
import os
import time
import copy
import re
from collections import defaultdict


#static variables goes here
max_name_size = 8 #maximal found alias lenght for device name, defaulting to 8, can change later


class SlideList(list):
    def __init__ (self,  length):
        self.length=length

    def append(self, newvalue):
        if len(self)>=self.length:
            list.pop(self,0)
        list.append(self,newvalue)

    def avg(self):
        return sum(self)/len(self)

    def median(self):
        return sorted(self)[len(self)/2]


def readconfig(path):
    config=defaultdict(str)
    try:
        import ConfigParser
        cfg=ConfigParser.ConfigParser()
        cfg.read(path)
        try:
             config["ignore"]=cfg.get("blktop","ignore")
        except:
             pass
    except:
        print "unable to read config, running with defaults"
    return config

def get_sector_size(dev):
    try:
        f=file("/sys/block/"+dev+"/queue/logical_block_size", 'r')
        ss=int(f.readline())
    except ExceptionObject:
        #dirty hack for old kernels (like centos)
        print "Unable to get sector size for %s, assuming 512 bytes." % (dev,)
        ss=512   
    return ss

def get_stat(dev):
    '''
    return new stat values (absolute numbers) for specified device
    return values as dictionary or None if error occure

    format from linux Documentation/block/stat.txt:

    Name            units         description
    ----            -----         -----------
    read I/Os       requests      number of read I/Os processed
    read merges     requests      number of read I/Os merged with in-queue I/O
    read sectors    sectors       number of sectors read
    read ticks      milliseconds  total wait time for read requests
    write I/Os      requests      number of write I/Os processed
    write merges    requests      number of write I/Os merged with in-queue I/O
    write sectors   sectors       number of sectors written
    write ticks     milliseconds  total wait time for write requests
    in_flight       requests      number of I/Os currently in flight
    io_ticks        milliseconds  total time this block device has been active
    time_in_queue   milliseconds  total wait time for all requests

    return value is just dictionary of those values (11 items)
    '''
    retval={}
    f=open('/sys/block/'+dev+'/stat','r')
    split=f.readline().split()
    retval["read_ios"]      = int(split[0])
    retval["read_merges"]   = int(split[1])
    retval["read_sectors"]  = int(split[2])  #TODO add getdevsize for right IO in MB/s calculation
    retval["read_ticks"]    = int(split[3])
    retval["write_ios"]     = int(split[4])
    retval["write_merges"]  = int(split[5])
    retval["write_sectors"] = int(split[6])
    retval["write_ticks"]   = int(split[7])
    retval["in_flight"]     = int(split[8])
    retval["io_ticks"]      = int(split[9])
    retval["time_in_queue"] = int(split[10])

    return retval


def is_any_io(item):
    '''
        return True if print device data, return false if not
        will be full featured, right now it or filter empty, or show all
    '''
    return bool ( filter( lambda x: x>0, item.values() ) )


def get_alias(realname):
    '''return name of device mapper devices'''
    try:
        candidates=os.listdir('/dev/mapper')
        for i in candidates:
            probe=os.path.basename( os.path.realpath ( os.path.join('/dev/mapper', i) ) )
            if probe == realname:
                return os.path.basename(i)
    except:
        pass
    return realname

def is_ignored(name, ignore_list):
    return False

def devlist(config):
    '''
    scan devices in /sys/block according to config file
    if config is none, every device is scanned

    return dictionary of found devices or empty dict
    we add only keys 'sector size', 'id' and flag if device is md (no queue/latency)
    '''
    devs={}
    for dev in  os.listdir('/sys/block'):
        if is_ignored(dev,config['ignore']):
            continue
	if is_any_io(get_stat(dev)):#skip empty devices never has an IO
            devs[dev]={}
            devs[dev]['sector_size']=get_sector_size(dev) #(just for test) FIXME
            devs[dev]['id']='FIXME' #FIXME
            if 'md' in dev:
                devs[dev]['is_md']=True
            else:
                devs[dev]['is_md']=False
            devs[dev]['alias']=get_alias(dev)
    return devs

def safe_div (a,b):
    if not b:
       return 0
    return a/b

def calc_single_delta(new,old, sector_size):
    '''
    return 'delta' values between old and new
    format is same as get_stat, but contains delta, not absolute values
    (N.B. delta is absolute and does not divided for dt)
    in certain cases we return not delta, but actual value (f.e. in_flight)
    '''
    retval={}
    #real deltas
    for key in ('read_ios', 'read_merges', 'read_sectors', 'read_ticks', 'write_ios', 'write_merges', 'write_sectors', 'write_sectors', 'write_ticks', 'io_ticks', 'time_in_queue'):
        retval[key]=new[key]-old[key]
    #copy as is
    retval['in_flight']=new['in_flight']
    retval['read_sectors']*=sector_size
    retval['write_sectors']*=sector_size
    try:
        retval['avg read block size']=retval['read_sectors']/retval['read_ios']
    except:
        retval['avg read block size']=0
    try:
        retval['avg write block size']=retval['write_sectors']/retval['write_ios']
    except:
        retval['avg write block size']=0
    retval['latency']= safe_div(float(retval['read_ticks']+retval['write_ticks']+retval['time_in_queue']),retval['read_ios']+retval['write_ios']) 
    return retval

def calc_delta(old, new, devlist):
    '''
       return dict of deltas for two dict of dicts
    '''
    retval={}
    for key in old.iterkeys():
        retval[key]=calc_single_delta(new[key],old[key],devlist[key]["sector_size"])
    return retval

def scan_all(devlist):
    '''
        performs full scan for all devices in devlist
        return dict in format:
          key=devname
          values=dict of stat
    '''
    retval={}
    for dev in devlist.keys():
        retval[dev]=get_stat(dev)
    return retval

def tick(devlist, delay,window_size=60):
    '''
        yield new delta for all devices in devlist
    '''
    old=scan_all(devlist)
    while 1:
        time.sleep(delay)
        new=scan_all(devlist)
        yield (calc_delta (old,new,devlist))
	old=new

def get_top (delta):
    '''
       scan through all deltas and sort them
    '''
    return delta #FIX


def make_k (n,scale=1000, force_high=False):
    '''
        return human-like view
    '''
    if n < 10*scale and not force_high:
        return str(n)
    if  n < 100*scale*scale:
        return str(n/scale)+'k'
    return str(n/scale/scale)+'M'

def fix (l,scale=1000, force_high=False):
    '''
       create pagination and convert numeric values to ISO-based format (f.e. 1k 8M and so on)
    '''
    if type(l) == type(""):
	value=l[0:8]
    elif type(l) == type(0.0):
        value = make_k ( round(l,2),scale,force_high) 
    else:
	value = make_k(l)
    return  value.rjust(8, ' ')


def prepare_header(devlist):
    '''
       create header line (reset screen and inversion).
       see man console_codes for detail
       return touple of text line and size of the fist column
       size calculated as maximal device alias name (but no more than 32 chars)
    '''
    upper_fields=("","READ","|","","WRITE","|")
    lower_fields=('IOPS', 'bytes', 'req.size', 'IOPS',  'bytes', 'req.size', 'latency', 'queue', 'IO time (ms)')
    u=" "*max_name_size+'| '+" ".join([fix(a) for a in upper_fields])
    l="|".join(["Dev name".rjust(max_name_size,' ')]+[fix(a) for a in lower_fields])
    return '\x1bc\x1b[7m'+u+'\x1b[0m\n'+'\x1b[7m'+l+'\x1b[0m'

def get_color(value):
    '''
       return color code based on value
       colors from man console_codes
       ranges:
           below 400 - default
           [400-649] - blue
           [649-799] - cyan
           [800-899] - yellow
           over 900 - red
    '''
    color_array=((400,39),(650,34),(800,36),(900,33),(100500,31))
    for threshold,color in color_array:
        if value<threshold:
            return color


def get_bold(name):
    ''' return boldness status for composite devices
        right now we support:
        device mapper (lvm, flashcache, multipath)
        md (raid)
        drbd
        (feel free to add)
    '''
    signatures = ('md', 'dm', 'drbd')
    if 'sd' in name: #prevent 'sdm' marked as 'dm'
       return 0
    for s in signatures:
        if s in name:
            return 1 #console_codes 'bold'
    return 0 #console_codes 'normal'



def prepare_line(name,item,dev):
    '''
       return string for printing for 'item'
    '''
    color_esc="\x1b[%im" #see man console_codes
    color_esc2="\x1b[%i;%im"
    default_color=39 #default foreground color
    color = get_color(item['io_ticks'])
    bold = get_bold(name)
    f=[(dev['alias'].rjust(max_name_size, ' '))]
    if not dev['is_md']:
        f.append(fix(item['read_ios']))
        f.append(fix(item['read_sectors'],1024,force_high=True))
        f.append(fix(item['avg read block size'],1024))
        f.append(fix(item['write_ios']))
        f.append(fix(item['write_sectors'],1024,force_high=True))
        f.append(fix(item['avg write block size'],1024))
        f.append(fix(item['latency']))
        f.append(fix(item['in_flight']))
        f.append(fix(item['io_ticks']))
    else:
        f.append(fix(item['read_ios']))
        f.append(fix(item['read_sectors'],1024,force_high=True))
        f.append(fix(item['avg read block size'],1024))
        f.append(fix(item['write_ios']))
        f.append(fix(item['write_sectors'],1024,force_high=True))
        f.append(fix(item['avg write block size'],1024))
    out=' '.join(f)
    return (color_esc2%(bold,color)) + out + (color_esc%default_color)


def view(cur,devlist):
    '''
        Visualisation part: print (un)fancy list
    '''
    print prepare_header(devlist)
	
    for a in cur.iterkeys():
        print prepare_line(a,cur[a],devlist[a])
    return None

def main():
    '''
    Right now we don't accept any command line values and 
    don't use config file (initial proof of usability)
    We making 1s tick so we can use delta as ds/dt
    '''
    config=readconfig("/etc/blktop.conf")
    devs=devlist(config)
    global max_name_size
    max_name_size = min(32,max(8,max([len(devs[i]['alias']) for i in devs.iterkeys()]),8)) #goes static, name field is in [8,32] range
    for (cur) in tick(devs,1):
	view (cur,devs)

if __name__ == '__main__':
    main ()
