<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created:2012-08-30 14:11:32                              |
  +----------------------------------------------------------------------+
  | Last-Modified:2012-08-30 22:26:14                        |
  +----------------------------------------------------------------------+
*/

//当前时间
$GLOBALS['currentTime']=time();

try {
    /* {{{ 处理传送文件
     */

    //具体处理哪个目录由自身进程序列号以及配置决定
    $configTag=$GLOBALS['reporting']["#{$GLOBALS['_daemon']['sn']}"];

    $waitingDir=$GLOBALS['transfer'][$configTag]['waiting'];
    if (!is_dir($waitingDir)) {
        throw new Exception(_info("[dir_invalid: %s]",$waitingDir));
    } else {
        _info("[waitingDir:{$waitingDir}]");
    }

    if (false!=($waitingFiles=_findAllFiles($waitingDir,'tbz2',1,true,10))) {   //一次最多10个
        $backupDir=$waitingDir.'/transfered/'.date($GLOBALS['backupType'],$GLOBALS['currentTime']);
        _makeDir($backupDir,"0755",0,'d');
        foreach ($waitingFiles as $waitingFile) {
            $path=$GLOBALS['transfer'][$configTag]['target'];
            $host=$GLOBALS['transfer'][$configTag]['host'];
            $port=$GLOBALS['transfer'][$configTag]['port'];
            $user=$GLOBALS['transfer'][$configTag]['user'];
            if (true==_transferFile($waitingFile,$path,$host,$port,$user)) {
                _moveFiles((array)$waitingFile, $backupDir);
                _notice("[waitingFile: %s][to: %s]",$waitingFile,$backupDir);
            } else {
                _notice("[waitingFile: %s][transfer_failed]",$waitingFile);
            }
        }
        pcntl_signal_dispatch();
    }
    /* }}} */
    pcntl_signal_dispatch();

} catch (Exception $e) {
    _error("Caught Exception: %s", $e->getMessage());
    sleep(5);
}
