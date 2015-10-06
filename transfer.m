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

    $logExt=strtolower($GLOBALS['archiveType'])=='j'?'tbz2':'tgz';
    if (false!=($waitingFiles=_findAllFiles($waitingDir,$logExt,1,true,10))) {   //一次最多10个
        if ($GLOBALS['enableBackup']==true) {
            $backupDir=$waitingDir.'/transfered/'.date($GLOBALS['backupType'],$GLOBALS['currentTime']);
            _makeDir($backupDir,"0755",0,'d');
        }
        foreach ($waitingFiles as $waitingFile) {
            // 随机一个key
            $tarInfo=$GLOBALS['transfer'][$configTag]['tarinfo'][array_rand($GLOBALS['transfer'][$configTag]['tarinfo'])];
            $path=$tarInfo['target'];
            $host=$tarInfo['host'];
            $port=$tarInfo['port'];
            $user=$tarInfo['user'];
            if (true==_transferFile($waitingFile,$path,$host,$port,$user)) {
                if ($GLOBALS['enableBackup']==true) {
                    _moveFiles((array)$waitingFile, $backupDir);
                    _notice("[waitingFile: %s][to: %s]",$waitingFile,$backupDir);
                }
            } else {
                _notice("[waitingFile: %s][path: %s][user: %s][host: %s][port: %s][transfer_failed]",$waitingFile,$path,$user,$host,$port);
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
