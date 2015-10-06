<?php
/*
  +----------------------------------------------------------------------+
  | Name:reporter.m                                                      |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created:TIMESTAMP                              |
  +----------------------------------------------------------------------+
  | Last-Modified:TIMESTAMP                        |
  +----------------------------------------------------------------------+
*/

//当前时间
$GLOBALS['currentTime']=time();

try {
    $deal=0;
    while($deal<2880 && $GLOBALS['_daemon']['workerRun']) {
        _clearCache();      //清除缓存

        _info("[logPath: %s][Interval: %d][rotateDir: %s][rotateTyp: %s]",$GLOBALS['logPath'],$GLOBALS['lcInterval'],$GLOBALS['rotateDir'],$GLOBALS['rotateType']);
        $result=collectLogs($GLOBALS['logPath'],$GLOBALS['lcInterval'],$GLOBALS['rotateDir'],$GLOBALS['rotateType']);
        if ($result['count']>0) {
            _notice("[%s][file: %s][logs: %d][size: %f(KB)][per_log: %f(KB)][duration: %f(s)]", $result['file'],$result['read_file'],$result['count'], $result['KB'], $result['per'], $result['dura']);
            //transfer logs
            if (false!=($logTarball=_package($result['file'],$result['tarball'],$GLOBALS['archiveType']))) {
                _warn("[logs: %d][size: %f(KB)][per_log: %f(KB)][duration: %f(s)][%s][%s][done]", $result['count'], $result['KB'], $result['per'], $result['dura'],$result['read_file'],$logTarball);
                $logWaiting=$GLOBALS['transfer'][$GLOBALS['logTag']]['waiting'];
                _moveFiles((array)$logTarball,$logWaiting);
            } else {
                if (file_exists($result['file']) && 0>=filesize($result['file'])) {
                    @exec("{$GLOBALS['_sys']['rm']} -f {$result['file']}");
                }
                _warn("[logs: %d][size: %f(KB)][per_log: %f(KB)][duration: %f(s)][%s][%s][failed!]", $result['count'], $result['KB'], $result['per'], $result['dura'],$result['read_file'],$logTarball);
            }
        } else {
            _notice("[%s][no_log][duration: %f(s)]",$result['file'],$result['dura']);
        }
        $deal++;
        pcntl_signal_dispatch();
    }

} catch (Exception $e) {
    _error("[Caught Exception: %s]", $e->getMessage());
    sleep(5);
}

