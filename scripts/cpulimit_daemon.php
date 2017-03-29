#!/usr/bin/env php
<?php
$MAXCPU=80;
$LIMIT=50;
$UNLIMIT=30;
$INTERVAL=5;
$LIMITKEEP=12;

# Values:
# 1 candidate for limit
# 0 candidate for free
# 2 limited

$status=array();

//log function
function eve_log ( $msg ) {
	error_log ( '['.date("F j, Y H:i:s").']'." ".$msg , 3 , "/opt/unetlab/data/Logs/cpulimit.log" ) ;
}

while ( true ) {
	// First check if process still exists///
	foreach ( $status as $key => $value ) {
		if ( posix_getpgid($key) == false ) {
			//Clean entry
			unset ($status[$key]);
		}
	}
	$o=explode("\n",shell_exec("ps axw -o pid,cmd | grep smp | grep qemu-system | grep -v \"sh \" | grep -v \"wrapper\" | sed -e 's,/opt.*\\(smp [0-9]*\\).*,\\1,g' -e 's/smp//' | grep -v grep | sed -e 's/\\.[0-9]*//' -e 's/^ *//' -e 's/  */ /g'"));
	$tpids=explode("\n",preg_replace("/  */"," ",shell_exec("top -b -n 1 -w 512 | grep qemu-system | sed -e 's/^ *//'")));
	array_pop($tpids);
	foreach ( $tpids as $tpid ) {
			$buf=explode(" ",$tpid, 2 );
			$buf2=explode(" ",$buf[1] );
			$cpid[$buf[0]]=preg_replace("/\..*/","",$buf2[7]);
	}
	array_pop($o);
	foreach ( $o as $pidsmp ) {
		$buf=explode(" ",$pidsmp);
		$pid=$buf[0];
		$smp=$buf[1];
		$cpu=$cpid[$pid];
		$max=$smp*$MAXCPU;
		if ( $cpu > $max ) {
			 if ( isset($status[$pid]) && $status[$pid] == 0 && $cpu > $UNLIMIT*$smp ) {
				//cpulimit active but cpu to high
				eve_log ("limit already active biut cpu high pid: ".$pid." smp:".$smp." max: ".$max." usage: ".$cpu."\n" );
				$status[$pid] = $LIMITKEEP  ;
			 } elseif ( !isset($status[$pid]) ) {
				// new process to limit
				eve_log ( " candidate  for limit pid: ".$pid." smp:".$smp." max: ".$max." usage: ".$cpu."\n" );
				$status[$pid] = $LIMITKEEP + 1 ;
			 } elseif ( $status[$pid] == ( $LIMITKEEP + 1 ) ) {
				// twice over limit ... neeed to limit now !!!
				eve_log ( "limit now pid: ".$pid." smp:".$smp." max: ".$max." usage: ".$cpu."\n") ;	
				$rc=exec("nohup cpulimit -q -p ".$pid." -l ".$LIMIT*$smp." -b > /dev/null 2>&1 & ");
				$status[$pid] = $LIMITKEEP ;
			}
		} else {
		// Process under max
			if ( isset($status[$pid]) && $cpu < $UNLIMIT*$smp ) {
				if ( $status[$pid] <= $LIMITKEEP && $status[$pid] > 0  ) {
					// elligible for unlimit
					$status[$pid] = $status[$pid] - 1  ;
					eve_log ( "candidate for free pid: ".$pid." smp:".$smp." max: ".$max." usage: ".$cpu." status ".$status[$pid]."\n") ;
				} elseif ( $status[$pid] == 0 ) {
					// already elected !
					// send TERM signal to cpulimit
					eve_log ( "free pid now: ".$pid." smp:".$smp." max: ".$max." usage: ".$cpu."\n") ;
					// ps ax | grep cpuli | grep -- "-p 3250" | awk '{print $1}'	
					$lpid=shell_exec("ps ax | grep cpuli | grep -- \"-p ".$pid." \" | grep -v grep | awk '{printf $1}'");
					var_dump($lpid);
					if ( $lpid != "" ) {
						$rc=exec("kill -TERM ".$lpid );
					}
					unset ($status[$pid]) ;
				} elseif ( $status[$pid] == ( $LIMITKEEP + 1 ) ) {
					eve_log ( "unset limit candidate pid: ".$pid." smp:".$smp." max: ".$max." usage: ".$cpu."\n" );
					// was eligible for limit.. no needed anymore
					unset ($status[$pid]) ;
				}
			}
		}
		
	}
	sleep($INTERVAL);
}
?>
