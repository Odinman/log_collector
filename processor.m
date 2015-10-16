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
    _clearCache();      //清除缓存
    $tmpFile="tmp{$GLOBALS['_daemon']['sn']}.log";
    $tarDir=$GLOBALS['processRoot'];
    if (!is_dir($tarDir)) {
        throw new Exception(_info("[%s not exists]",$tarDir));
    } else {
        _info("[%s][scan_it]",$tarDir);
    }

    if (false!=($logFiles=_findAllFiles($tarDir,'',1,true,$GLOBALS['maxLogs']))) {
        $fileCount=0;
        $totalFile=count($logFiles);
        $importStart=_microtimeFloat();
        foreach ($logFiles as $fkey=>$logFile) {
            $fileStart=_microtimeFloat();
            $fileCount++;
            $fileTS=filemtime($logFile);
            $logCount=0;
            //这些file应该已经经过验证了
            $logInfo=pathinfo($logFile);
            $logName="{$logInfo['filename']}.log";
            list($logTag)=explode('_',$logName);
            //根据后缀决定解压方式
            if ($logInfo['extension']=='tbz2') {
                $command="{$GLOBALS['_sys']['bzcat']} $logFile | {$GLOBALS['_sys']['tar']} xOf - $logName > {$tmpFile} 2>/dev/null";
            } else {
                $command="{$GLOBALS['_sys']['gzcat']} $logFile | {$GLOBALS['_sys']['tar']} xOf - $logName > {$tmpFile} 2>/dev/null";
            }
            @exec($command,$arrlines,$stat);
            if ($stat==0 && $tmpFp=@fopen($tmpFile,"rb")) {    //解压成功并且读取成功
                _info("[%s][begin]",$logFile);
                while(!feof($tmpFp)) {
                    $content=trim(fgets($tmpFp,10240));
                    if (!empty($content) && 0<($ts=getLogTS($logTag,$content,$fileTS))) {
                        $logCount++;
                        $saveFile=sprintf("%s/%s/%s",$GLOBALS['logSaveRoot'],$logTag,date('Ym/d/H.\l\o\g',$ts));
                        _info("[count: %s][%s][save_file: %s]",$logCount,$ts,$saveFile);
                        _makeDir($saveFile,"0755",0,'f');
                        saveLogToFile($saveFile,$content);
                    }
                    unset($content);
                }

                fclose($tmpFp);

                @exec("{$GLOBALS['_sys']['rm']} -f {$logFile}");
            }

            $fileEnd=_microtimeFloat();
            $fileDura=round(($fileEnd-$fileStart),3);
            $importDura=round(($fileEnd-$importStart),3);
            _warn("[%s][%s][dura: %s][%s/%s][import_dura: %s]",$logName,$logCount,$fileDura,$fileCount,$totalFile,$importDura);
        }
        _notice("[deal_log_files: %s]",$fileCount);
        pcntl_signal_dispatch();
    } else {
        _info("[nothing_to_do]");
    }

    pcntl_signal_dispatch();

} catch (Exception $e) {
    _error("[Caught Exception: %s]", $e->getMessage());
    sleep(5);
}

