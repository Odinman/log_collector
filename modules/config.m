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

$GLOBALS['timeZone']=empty($GLOBALS['OPTIONS']['setting']['time_zone'])?'Asia/Shanghai':$GLOBALS['OPTIONS']['setting']['time_zone'];
date_default_timezone_set($GLOBALS['timeZone']);

$GLOBALS['hostName']=@exec("/bin/hostname -s");

//waiting to transfer
$GLOBALS['waitingRoot']=empty($GLOBALS['OPTIONS']['setting']['waiting_root'])?'/services/waiting':$GLOBALS['OPTIONS']['setting']['waiting_root'];
_makeDir($GLOBALS['waitingRoot'],"0755",0,'d');

// waiting to process
$GLOBALS['processRoot']=empty($GLOBALS['OPTIONS']['setting']['process_root'])?'/services/LOGTEMP':$GLOBALS['OPTIONS']['setting']['process_root'];
$GLOBALS['maxLogs']=empty($GLOBALS['OPTIONS']['setting']['max_logs'])?10:$GLOBALS['OPTIONS']['setting']['max_logs'];

// log save
$GLOBALS['logSaveRoot']=empty($GLOBALS['OPTIONS']['setting']['log_save_root'])?'/services/QHLOGS':$GLOBALS['OPTIONS']['setting']['logSaveRoot'];
_makeDir($GLOBALS['logSavePath'],"0755",0,'d');
