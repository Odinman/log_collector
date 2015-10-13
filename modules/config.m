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

