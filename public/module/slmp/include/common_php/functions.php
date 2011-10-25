<?php
// Description
require_once "./include/common_php/Properties.php";
include "./include/common_php/variables.php";

function runExternal($cmd,&$code) {
	$descriptorspec = array(
		0 => array("pipe", "r"), // stdin is a pipe that the child will read from

		1 => array("pipe", "w"), // stdout is a pipe that the child will write to

		2 => array("pipe", "w") // stderr is a file to write to
	);

	$pipes= array();
	$process = proc_open($cmd, $descriptorspec, $pipes);

	$output= "";

	if (!is_resource($process)) return false;

	#close child's input imidiately
	fclose($pipes[0]);

	stream_set_blocking($pipes[1],false);
	stream_set_blocking($pipes[2],false);

	$todo= array($pipes[1],$pipes[2]);

	while( true ) {
		$read= array();
		if( !feof($pipes[1]) ) $read[]= $pipes[1];
		if( !feof($pipes[2]) ) $read[]= $pipes[2];

		if (!$read) break;
		$write=NULL;
		$ex= NULL;
		$ready= stream_select($read, $write, $ex, 2);

		if ($ready === false) {
			break; #should never happen - something died
		}

		foreach ($read as $r) {
			$s= fread($r,1024);
			$output.= $s;
		}
	}

	fclose($pipes[1]);
	fclose($pipes[2]);

	$code= proc_close($process);

	return $output;
} 

// --------------------------------------------------------------------------------------------------------------------------

function decodeResponse( $PREFIX_COMMAND,$blob) {
	$command = $PREFIX_COMMAND .' -response "'.$blob.'"';
	$result = shell_exec($command);
	$pairs = explode("&", $result);
	foreach ($pairs as $pair) {
		$pairArr = explode("=", $pair);
		if(isset($pairArr[1]))
		$pairResulted[$pairArr[0]] = $pairArr[1];
		else $pairResulted[$pairArr[0]] = null;
	}
	return $pairResulted;
}


// --------------------------------------------------------------------------------------------------------------------------
function cleanUrl($url) {

	if(strstr($url,'?')!=null)
		{
		$url = strrev($url);
		$url = strrev(substr($url,strpos($url,"?")+1));
	} 
	return $url;
}

// --------------------------------------------------------------------------------------------------------------------------
function initializeProperties($properties) {
	$properties->setNewLineAsOS();
	$properties->readContent();
}
// --------------------------------------------------------------------------------------------------------------------------

function slm_parse_number($number) {

	$result = str_replace (' ','',$number);
	return $result;
}	

// -----------------------------------------------

function substitute($var){
	$operatingSystem = PHP_OS;
	$operatingSystem = strtolower($operatingSystem);
	
	if (preg_match("/win/", $operatingSystem)){
		$forbidden=array("&",">", "<",  ";", "*", "|", "?" );
	}
	else {
	  	$forbidden=array("&",">", "<",  ";", "*","\\", "|", "?", "\"" );
	} 
	$result = str_replace($forbidden, "", $var);
	return $result;
}


?>
