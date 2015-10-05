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

    $fileTag=$GLOBALS['_daemon']['sn'].substr(md5($GLOBALS['hostName']),0,6).date('_Y_m_d_H_i_s',time());

    $start=_microtimeFloat();

    $filename=$GLOBALS['logTag'].$fileTag;
    $rt['filename']=$filename;
    $rt['file']=$filename.'.log';
    $rt['tarball']=$filename.'.tbz2';
    _info("[%s][open: %s]",__FUNCTION__,$rt['file']);
    $fp=@fopen($rt['file'],'wb');
    do {
        // 获取上次读取的信息
        $lrs=getReadStatus($GLOBALS['readStatusFile']);
        _notice("[%s][file: %s][offset: %d][inode: %s]",__FUNCTION__,$logFile,$lrs['offset'],$lrs['inode']);

        // 获取日志
        if (false!=($logInfo=getLogInfo($logFile,$lrs['offset'],$lrs['inode'],$rotateDir,$rotateType))) {
            _notice("[%s][file: %s][offset: %d][inode: %s][find_log]",__FUNCTION__,$logInfo['file'],$logInfo['offset'],$logInfo['inode']);
            if ($logInfo['read'] && file_exists($logInfo['file']) && $fp0=@fopen($logInfo['file'],"rb")) {
                flock($fp0,LOCK_SH);
                fseek($fp0,$logInfo['offset']);
                while (!feof($fp0)) {
                    $content=trim(fgets($fp0,10240));
                    if(!empty($content)) {
                        if (!empty($GLOBALS['logSeparator'])) { //如果有分隔符,则取后面的
                            list(,$content)=explode($GLOBALS['logSeparator'],$content);
                        }
                        fputs($fp,$content."\n");
                        $rt['count']++;
                    }
                    $curOffset=ftell($fp0);
                    $readSize=$curOffset-$logInfo['offset'];
                    if ($rt['size']+$readSize>=$GLOBALS['maxBytes']) {
                        _notice("[%s][read_size: %d][reach_max: %d]",__FUNCTION__,$rt['size']+$readSize,$GLOBALS['maxBytes']);
                        break;
                    }
                }
                $rt['size']+=$readSize;
                fclose($fp0);
            }
        }

        //存储当前读取信息
        saveReadStatus($GLOBALS['readStatusFile'],$curOffset,$logInfo['inode']);

        //addition info
        $rt['KB']=round($rt['size']/1024,2);
        $rt['MB']=round($rt['size']/(1024*1024),2);
        if ($rt['count']>0) {   //平均每条大小
            $rt['per']=round($rt['KB']/$rt['count'],2);
        }
        _notice("[%s][cur_offset: %d][inode: %s][size: %s]",__FUNCTION__,$curOffset,$logInfo['inode'],$rt['MB']);

        $end=_microtimeFloat();
        $rt['dura']=round(($end-$start),3);

        //判断是否要退出
        if ($rt['MB']>=$GLOBALS['maxSize']) {
            _warn("[%s][over_size: %f][max_size: %f]",__FUNCTION__,$rt['MB'],$GLOBALS['maxSize']);
            break;
        }
        _notice("[%s][read: %d][size: %f][per: %f(KB)][dura: %f][continue]",__FUNCTION__,$rt['KB'],$rt['per'],$rt['dura']);
        usleep(30000);  // 30 ms
    } while($rt['dura']<$interval);

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

        $rt=array(
            'file' => $logFile,
            'inode'  => 0,
            'offset' => (int)$lastOff,
            'read' => false,  //默认不读取
        );

        //log inode 信息
        $logINode=fileinode($logFile);
        //日志文件信息
        $logSize=filesize($logFile);

        if (empty($lastINode)) {    //如果inode为空,就当作第一次读取
            $rt['inode']=$logINode;
            $rt['read']=$logSize>0?true:false;
            _notice("[%s][file: %s][inode: %s][offset:0][first_read]",__FUNCTION__,$rt['file'],$rt['inode']);
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
            for ($i=0;$i<=5;$i++) {  //最多找五个rotate文件
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
                        $rt['offset']=(int)$lastOff;
                    }
                    //终止循环
                    break;
                }

                //当前文件不匹配,如果之后的循环找不到,则从当前文件开始读
                $rt['file']=$oldLogFile;
                $rt['inode']=$oldINode;
            }
        }
    } while(false);

    return $rt;
}
/* }}} */

/* {{{ getReadStatus
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

