<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created: 2015-08-05 13:21:57                                         |
  +----------------------------------------------------------------------+
  | Last-Modified: 2015-10-05 17:31:45                                   |
  +----------------------------------------------------------------------+
*/

/* {{{ function collectLogs($logFile,$interval,$rotateDir,$rotateType,$maxSize)
 * 收集日志
 */
function collectLogs($logFile,$interval,$rotateDir,$rotateType,$maxSize) {
    $rt=[
        'dura'=>0,
    ];

    $start=_microtimeFloat();

    $filename=sprintf("%s_%s_%s",$GLOBALS['logTag'],date('Ymd_His_'.substr((string)microtime(), 2, 7).'_T',time()),$GLOBALS['hostName']);
    $rt['filename']=$filename;
    $rt['file']=$filename.'.log';
    $rt['tarball']=strtolower($GLOBALS['archiveType'])=='j'?$filename.'.tbz2':$filename.'.tgz';
    _info("[%s][open: %s]",__FUNCTION__,$rt['file']);
    $fp=@fopen($rt['file'],'wb');

    $continue=true;
    do {
        // 获取上次读取的信息
        $lrs=getReadStatus($GLOBALS['readStatusFile']);
        _info("[%s][file: %s][last_offset: %d][last_inode: %s]",__FUNCTION__,$logFile,$lrs['offset'],$lrs['inode']);
        $rt['last_offset']=$lrs['offset'];
        $rt['last_inode']=$lrs['inode'];

        // 获取日志
        $count=0;
        if (false!=($logInfo=getLogInfo($logFile,$lrs['offset'],$lrs['inode'],$rotateDir,$rotateType))) {
            if ($logInfo['read'] && file_exists($logInfo['file']) && $fp0=@fopen($logInfo['file'],"rb")) {
                $rt['read_file']=$logInfo['file'];
                _info("[%s][reading_file: %s][size: %d][offset: %d][inode: %s][with_new_log]",__FUNCTION__,$logInfo['file'],$logInfo['size'],$logInfo['offset'],$logInfo['inode']);
                flock($fp0,LOCK_SH);
                fseek($fp0,$logInfo['offset']);
                while (!feof($fp0)) {
                    $content=trim(fgets($fp0,10240));
                    if(!empty($content)) {
                        if (!empty($GLOBALS['logSeparator'])) { //如果有分隔符,则取后面的
                            list(,$content)=explode($GLOBALS['logSeparator'],$content);
                        }
                        fputs($fp,$content."\n");
                        $count++;
                    }
                    $curOffset=ftell($fp0);
                    $readSize=$curOffset-$logInfo['offset'];
                    if ($rt['size']+$readSize>=$GLOBALS['maxBytes']) {
                        _notice("[%s][%s][read_size: %d][reach_max: %d][completion: %s%%]",__FUNCTION__,$logInfo['file'],$rt['size']+$readSize,$GLOBALS['maxBytes'],round($readSize*100/($logInfo['size']-$logInfo['offset']),2));
                        break 1;
                    }
                }
                $rt['size']+=$readSize;
                $rt['count']+=$count;
                fclose($fp0);
            } else {
                $rt['file_size']=$logInfo['size'];
                $rt['file_inode']=$logInfo['inode'];
                _info("[%s][file: %s][offset: %d][filesize: %d][not_need_read]",__FUNCTION__,$logInfo['file'],$logInfo['offset'],$logInfo['size']);
            }
        } else {
            _warn("[%s][not_found_file]",__FUNCTION__);
            $curOffset=$logInfo['offset'];
        }

        if ($count>0) {
            //存储当前读取信息
            saveReadStatus($GLOBALS['readStatusFile'],$curOffset,$logInfo['inode']);

            //addition info
            $rt['KB']=round($rt['size']/1024,2);
            $rt['MB']=round($rt['size']/(1024*1024),2);
            if ($rt['count']>0) {   //平均每条大小
                $rt['per']=round($rt['KB']/$rt['count'],2);
            }
            _notice("[%s][read_file: %s][cur_offset: %d][inode: %s][size: %s(KB)][new_logs: %d]",__FUNCTION__,$logInfo['file'],$curOffset,$logInfo['inode'],$rt['KB'],$count);
        }

        $end=_microtimeFloat();
        $rt['dura']=round(($end-$start),3);

        //判断是否要退出
        if ($rt['MB']>=$GLOBALS['maxSize']) {
            _warn("[%s][%s][read_size: %f(MB)][max_size: %d(MB)][dura: %f(s)][exceed_max]",__FUNCTION__,$logInfo['file'],$rt['MB'],$GLOBALS['maxSize'],$rt['dura']);
            $continue=false;
        } else {
            _info("[%s][read: %d(KB)][size: %f(KB)][per: %f(KB)][dura: %f(s)][continue]",__FUNCTION__,$rt['KB'],round($logInfo['size']/1024,2),$rt['per'],$rt['dura']);
        }
        usleep(30000);  // 30 ms
        //sleep(10);  // 30 ms
    } while($rt['dura']<$interval && $continue);

    fclose($fp);

    return $rt;
}

/* }}} */

/* {{{ function getLogInfo($logFile,$lastOff,$lastINode,$rotateDir,$rotateType)
 * 获取需要读取日志文件的路径以及位置
 * 读取日志的类型为文本格式，rotate可支持多种类型
 */
function getLogInfo($logFile,$lastOff,$lastINode,$rotateDir,$rotateType) {
    $rt=false;

    do {
        if (!file_exists($logFile)) {
            _error("[%s][%s][NOT_FOUND]",__FUNCTION__,$logFile);
            break;
        }

        $lpi=pathinfo($logFile);
        $logFileName=$lpi['basename'];
        if (empty($rotateDir)) {
            $rotateDir=$lpi['dirname'];
        }

        clearstatcache();
        //log inode 信息
        $logINode=fileinode($logFile);
        //日志文件信息
        $logSize=filesize($logFile);

        $rt=array(
            'file' => $logFile,
            'inode'  => $logINode,
            'size' => $logSize,
            'offset' => (int)$lastOff,
            'read' => false,  //默认不读取
        );

        _info("[%s][inode: %s][last_inode: %s][logsize: %d][lastoff: %d]",__FUNCTION__,$logINode,$lastINode,$logSize,$lastOff);

        if (empty($lastINode)) {    //如果inode为空,就当作第一次读取
            $rt['inode']=$logINode;
            $rt['read']=$logSize>0?true:false;
            _info("[%s][file: %s][inode: %s][offset:0][first_read]",__FUNCTION__,$rt['file'],$rt['inode']);
            break;
        }

        if ($lastINode==$logINode) {    //inode相同,说明还是同一个文件
            $rt['inode']=$logINode;
            if ($lastOff>=$logSize) {   //无新内容,或者内容被删掉了?
                $rt['offset']=$logSize;
            } else {    //上一次读取之后,有了新内容
                $rt['read']=true;
            }
            break;
        } else {    //不是当前文件,需要之前的文件
            $rt['read']=true;  //如果没找到旧文件,则直接读取当前文件
            $rt['offset']=0;
            for ($i=0;$i<10;$i++) {  //最多找10个rotate文件
                switch ($rotateType) {
                case 'number':
                default:
                    $oldLogFile=$rotateDir.'/'.$logFileName.'.'.$i;
                    break;
                }
                if (!file_exists($oldLogFile)) {    //找不到文件了,终止
                    continue;
                }
                if (0>=($oldSize=filesize($oldLogFile))) { //没有内容,跳过
                    continue;
                }
                $oldINode=fileinode($oldLogFile);
                if ($oldINode==$lastINode) {    //找到文件
                    if ($lastOff<$oldSize) {    //有新内容,读
                        $rt['file']=$oldLogFile;
                        $rt['inode']=$oldINode;
                        $rt['size']=$oldSize;
                        $rt['offset']=(int)$lastOff;
                    }
                    //终止循环
                    break;
                }

                //当前文件不匹配,如果之后的循环找不到,则从当前文件开始读
                $rt['file']=$oldLogFile;
                $rt['inode']=$oldINode;
                $rt['size']=$oldSize;
            }
        }
    } while(false);

    return $rt;
}
/* }}} */

/* {{{ function getReadStatus($statusFile)
 */
function getReadStatus($statusFile) {
    $rt=false;

    if (file_exists($statusFile) && false!=($ss=trim(file_get_contents($statusFile)))) {
        $tmp=explode('|',$ss);
        $rt=[
            'ts'=>$tmp[0],
            'offset'=>$tmp[1],
            'inode'=>$tmp[2],
        ];
    }

    return $rt;
}
/* }}} */

/* {{{ function saveReadStatus($statusFile,$offset,$inode)
 *
 */
function saveReadStatus($statusFile,$offset,$inode) {
    $rt=false;

    try {
        $now=time();
        @exec("echo '{$now}|{$offset}|{$inode}' > $statusFile");
    } catch (Exception $e) {
        _error("Exception: %s", $e->getMessage());
    }

    return $rt;
}

/* }}} */

/* {{{ function getLogTS($tag,$content,$dts)
 *
 */
function getLogTS($tag,$content,$dts) {
    $rt=0;

    do {
        if (!isset($GLOBALS['OPTIONS'][$tag])) {    //如果没有专门的配置,直接用文件的修改时间
            break;
        }
        $logSetting=$GLOBALS['OPTIONS'][$tag];
        switch(strtolower($logSetting['log_format'])) { //日志格式
        case 'csv': //时间
            if (empty($logSetting['delimiter'])) {
                $logSetting['delimiter']=',';
            }
            if (isset($logSetting['ts_offset']) && false!=($cps=str_getcsv($content,$logSetting['delimiter']))) {  // csv要配置offset
                $tsStr=$cps[$logSetting['ts_offset']];
            }
            $rt=_getTS($tsStr,$logSetting['time_format']);
            break;
        case 'json':
            if (isset($logSetting['ts_key']) && false!=($jps=json_decode($content,true))) {  // csv要配置key
                $tsStr=$jps[$logSetting['ts_key']];
            }
            $rt=_getTS($tsStr,$logSetting['time_format']);
            break;
        default:
            $rt=$dts;
            break;
        }
    } while(false);

    if ($rt<=0) {
        $rt=$dts>0?$dts:time();
    }

    return $rt;
}

/* }}} */

/* {{{ function saveLogToFile($file,$content)
 *
 */
function saveLogToFile($file,$content) {
    $rt=false;

    do {
        if (isset($GLOBALS['_CACHE_']['_fhs_'][$file]) && is_resource($GLOBALS['_CACHE_']['_fhs_'][$file])) {
            fputs($GLOBALS['_CACHE_']['_fhs_'][$file],$content."\n");
            $rt=true;
            break;
        }
        _makeDir($file,"0755",0,'f');
        if ($fp=@fopen($file,"a+")) {
            fputs($fp,$content."\n");
            $GLOBALS['_CACHE_']['_fhs_'][$file]=$fp;
        }
        $rt=true;
    } while(false);

    return $rt;
}

/* }}} */

/* {{{ function saveFileToHDFS($file,$ts=0)
 *
 */
function saveFileToHDFS($logTag,$file,$ts=0) {
    $rt=false;

    if ($ts<=0) {
        $ts=time();
    }
    try {
        $hdfsDir=sprintf("%s/%s/%s",$GLOBALS['logSaveRoot'],$logTag,date('Ym/d',$ts));
        $hdfsFile=sprintf("%s",date('H.\l\o\g',$ts));
        $hdfsPath=sprintf("%s/%s",$hdfsDir,$hdfsFile);

        $ch=curl_init();
        //curl_setopt($ch, CURLOPT_URL, $GLOBALS['webHDFSURL']);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        if ($GLOBALS[_HDFS_][$hdfsDir]!==true) {    //建目录
            $opURL=sprintf("%s%s?op=MKDIRS&user.name=%s",$GLOBALS['webHDFSURL'],$hdfsDir,$GLOBALS['webHDFSUser']);
            curl_setopt($ch, CURLOPT_URL, $opURL);
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
            $result=curl_exec($ch);
            $info = curl_getinfo($ch);
            if ($info['http_code']!=200) { //失败
                throw new Exception(_info("[%s][%s][create_dir_failed: %s]",__FUNCTION__,$hdfsDir,$result));
            }
            $GLOBALS[_HDFS_][$hdfsDir]=true;
        }

        //查看文件是否存在
        $create=false;
        if ($GLOBALS[_HDFS_][$hdfsPath]!==true) {    //建目录
            $opURL=sprintf("%s%s?op=GETFILESTATUS&user.name=%s",$GLOBALS['webHDFSURL'],$hdfsPath,$GLOBALS['webHDFSUser']);
            curl_setopt($ch, CURLOPT_URL, $opURL);
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
            $result=curl_exec($ch);
            $info = curl_getinfo($ch);
            if ($info['http_code']!=200) { //不存在, 创建
                $create=true;
            }
        }

        if ($create===true) {
            $opURL=sprintf("%s%s?op=CREATE&user.name=%s",$GLOBALS['webHDFSURL'],$hdfsPath,$GLOBALS['webHDFSUser']);
            curl_setopt($ch, CURLOPT_URL, $opURL);
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
            curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents($file));
        } else {
            $opURL=sprintf("%s%s?op=APPEND&user.name=%s",$GLOBALS['webHDFSURL'],$hdfsPath,$GLOBALS['webHDFSUser']);
            curl_setopt($ch, CURLOPT_URL, $opURL);
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
            curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents($file));
        }
        $result=curl_exec($ch);
        $info = curl_getinfo($ch);
        if ($info['http_code']==200) { // 成功
            _notice("[%s][write_to: %s][sucessful]",__FUNCTION__,$hdfsPath);
        } else {
            _warn("[%s][write_to: %s][failed]",__FUNCTION__,$hdfsPath);
        }

    } catch (Exception $e) {
        _error("Exception: %s", $e->getMessage());
    }

    return $rt;
}

/* }}} */

