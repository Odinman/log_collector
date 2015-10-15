<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
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

$confSn=$GLOBALS['_daemon']['sn'];
$confTag=sprintf("log%s",$confSn);

if (false!=($wConfig=$GLOBALS['OPTIONS'][$confTag])) {
    $GLOBALS['archiveType']=empty($wConfig['archive_type'])?'z':$wConfig['archive_type'];

    $GLOBALS['logPath']=empty($wConfig['log_path'])?'/services/qinhucloud/uc/logs/access.log':$wConfig['log_path'];
    $GLOBALS['rotateDir']=empty($wConfig['rotate_dir'])?null:$wConfig['rotate_dir'];
    if (empty($GLOBALS['rotateDir'])) {
        $rpf=pathinfo($GLOBALS['logPath']);
        $GLOBALS['rotateDir']=$rpf['dirname'];
    }
    $GLOBALS['rotateType']=empty($wConfig['rotate_type'])?'number':$wConfig['rotate_type'];
    $GLOBALS['lcInterval']=empty($wConfig['lc_interval'])?10:(int)$wConfig['lc_interval'];

    $GLOBALS['logTag']=empty($wConfig['log_tag'])?'common':$wConfig['log_tag'];
    $GLOBALS['enableBackup']=(isset($wConfig['enable_backup']) && strtolower($wConfig['enable_backup'])=="yes")?true:false;

    $GLOBALS['maxSize']=empty($wConfig['max_size'])?128:(int)$wConfig['max_size'];    // MB
    $GLOBALS['maxBytes']=$GLOBALS['maxSize']*1024*1024;

    $GLOBALS['logSeparator']=empty($wConfig['log_separator'])?null:$wConfig['log_separator'];   //分隔符

    //tmp file
    $GLOBALS['readTmpFile']=empty($wConfig['tmp_file'])?sprintf("tmp_%s",$GLOBALS['logTag']):$wConfig['tmp_file'];

    // status file
    $GLOBALS['readStatusFile']=empty($wConfig['status_file'])?sprintf("%s/%s/read_%s.status",$GLOBALS['_daemon']['_WORKERROOT_'],_SUBPATH_RUN,$GLOBALS['logTag']):$wConfig['status_file'];

    // transfer
    $GLOBALS['transfer'][$GLOBALS['logTag']]['waiting'] = $GLOBALS['waitingRoot'].'/'.$GLOBALS['logTag'];
    _makeDir($GLOBALS['transfer'][$GLOBALS['logTag']]['waiting'],"0755",0,'d');

    if (!empty($wConfig['log_tarinfo'])) {
        $ts=explode(',',$wConfig['log_tarinfo']);
        foreach($ts as $tis) {
            list($tdir,$tuser,$thost,$tport,$tkey)=explode(':',$tis);
            $GLOBALS['transfer'][$GLOBALS['logTag']]['tarinfo'][]=array(
                'target'=> $tdir,
                'user' =>  $tuser,
                'host' =>  $thost,
                'port' =>  $tport,
                'key'  => $GLOBALS['_daemon']['_WORKERROOT_'].'/'.$tkey,
            );
        }
    }
}
