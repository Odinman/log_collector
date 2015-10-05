<?php
/*
  +----------------------------------------------------------------------+
  | Name:
  | Comment:
  | Author: Odin
  | Created: 2015-04-13 01:39:13
  | Last-Modified: 2015-04-13 01:39:24
  +----------------------------------------------------------------------+
*/

$GLOBALS['logPath']=empty($GLOBALS['OPTIONS']['setting']['log_path'])?'/services/adlogs/access.log':$GLOBALS['OPTIONS']['setting']['log_path'];
$GLOBALS['rotateDir']=empty($GLOBALS['OPTIONS']['setting']['rotate_dir'])?'/services/adlogs':$GLOBALS['OPTIONS']['setting']['rotate_dir'];
$GLOBALS['rotateType']=empty($GLOBALS['OPTIONS']['setting']['rotate_type'])?'number':$GLOBALS['OPTIONS']['setting']['rotate_type'];
$GLOBALS['lcInterval']=empty($GLOBALS['OPTIONS']['setting']['lc_interval'])?30:(int)$GLOBALS['OPTIONS']['setting']['lc_interval'];

$GLOBALS['logSeparator']=empty($GLOBALS['OPTIONS']['setting']['log_separator'])?null:$GLOBALS['OPTIONS']['setting']['log_separator'];

$GLOBALS['maxSize']=empty($GLOBALS['OPTIONS']['setting']['max_size'])?128:(int)$GLOBALS['OPTIONS']['setting']['max_size'];    // MB
$GLOBALS['maxBytes']=$GLOBALS['maxSize']*1024*1024;

$GLOBALS['logTag']=empty($GLOBALS['OPTIONS']['setting']['log_tag'])?'ads':$GLOBALS['OPTIONS']['setting']['log_tag'];
$GLOBALS['enableBackup']=(isset($GLOBALS['OPTIONS']['setting']['enable_backup']) && strtolower($GLOBALS['OPTIONS']['setting']['enable_backup'])=="yes")?true:false;

$GLOBALS['hostName']=@exec("/bin/hostname");

// status file
$GLOBALS['readStatusFile']=empty($GLOBALS['OPTIONS']['setting']['read_status_file'])?$GLOBALS['_daemon']['_WORKERROOT_'].'/'._SUBPATH_RUN.'/dm_read.status':$GLOBALS['OPTIONS']['setting']['read_status_file'];

//sn,进程号
$log_sn=empty($GLOBALS['OPTIONS']['setting']['log_sn'])?'1':$GLOBALS['OPTIONS']['setting']['log_sn'];

//reporting config tag
$GLOBALS['reporting']['#'.$log_sn]=$GLOBALS['logTag'];    // 指定第一个进程处理

//waiting to transfer
$GLOBALS['waitingRoot']=empty($GLOBALS['OPTIONS']['setting']['waiting_root'])?'/services/waiting':$GLOBALS['OPTIONS']['setting']['waiting_root'];
_makeDir($GLOBALS['waitingRoot'],"0755",0,'d');

// transfer
$GLOBALS['transfer'][$GLOBALS['logTag']]=array(
    'waiting' => $GLOBALS['waitingRoot'].'/'.$GLOBALS['logTag'],
    'target' => empty($GLOBALS['OPTIONS']['transfer']['log_tardir'])?'/services/DMLOGS':$GLOBALS['OPTIONS']['transfer']['log_tardir'],
    'host' => empty($GLOBALS['OPTIONS']['transfer']['log_host'])?null:$GLOBALS['OPTIONS']['transfer']['log_host'],
    'port' => empty($GLOBALS['OPTIONS']['transfer']['log_port'])?'22':$GLOBALS['OPTIONS']['transfer']['log_port'],
    'user' => empty($GLOBALS['OPTIONS']['transfer']['log_user'])?'dmreporter':$GLOBALS['OPTIONS']['transfer']['log_user'],
);
_makeDir($GLOBALS['transfer'][$GLOBALS['logTag']]['waiting'],"0755",0,'d');
