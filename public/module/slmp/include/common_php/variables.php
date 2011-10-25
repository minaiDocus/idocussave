<?php
//to define the scim home
$SCIM_HOME = "./";

if (! $SCIM_HOME ){
  print "ERROR : ENVIRONMENT VARIABLE SCIM_HOME IS NOT SET ";
  exit(0);
}
// to define the scim jar name 
$SCIM_JAR_NAME='scim.jar';

//to define the operating system to create paths dynamically 
$OS=PHP_OS;
$LANG_VARIABLE="";
$OPERATING_SYSTEM=strtolower($OS);
if (preg_match("/lin/", $OPERATING_SYSTEM) || preg_match("/darwin/", $OPERATING_SYSTEM ) ){
	$JAR =  $SCIM_HOME."/scim/".$SCIM_JAR_NAME;
	$PROPERTIES_FILE ="/Properties/SCIMProperties.properties";
	$LOGGER_CONFIG = $SCIM_HOME."/scim/log4j.xml";
	$LANG_VARIABLE='LANG="en_US.UTF8" ';
}
else if (preg_match( "/win/", $OPERATING_SYSTEM )){
   $JAR =  $SCIM_HOME."\\scim\\".$SCIM_JAR_NAME;
   $PROPERTIES_FILE ="\\Properties\\SCIMProperties.properties";
   $LOGGER_CONFIG = $SCIM_HOME."\\scim\log4j.xml";
}
else{
   print "ERROR : OPERATING SYSTEM NOT SUPPORTED ";
   print "ERROR : YOU MUST SPECIFY YOUR OPERATING SYSTEM VARIABLE ";
   exit(1);
} 

if (! file_exists($JAR)) {
    print "ERROR : FILE ". $JAR." DOES NOT EXIST";
    exit(1);
}

$PROPERTIES_FILE_PATH=$SCIM_HOME.$PROPERTIES_FILE;

$CLIENT_CARD_PAYMENT_KEY= "scim.client.card.payment";

$CLIENT_DYNAMIC_CERT="scim.dynamic.certificate.flag";
$CLIENT_PRODUCTION_FLAG="scim.production.flag";

//dev
$CLIENT_IDENTIFIER_KEY_DEV="scim.dev.site.id";
$SERVER_CALL_URL_DEV ="scim.dev.target.url";
$CLIENT_ALIAS_KEY_DEV = "scim.dev.client.key.alias";
$CLIENT_PATH_KEY_DEV = "scim.dev.client.keystore.filename";
$CLIENT_PASSWORD_KEY_DEV="scim.dev.client.keystore.password";
$CLIENT_PK_PASSWORD_KEY_DEV="scim.dev.client.privatekey.password";
$SLIMPAY_ALIAS_KEY_DEV="scim.dev.slimpay.key.alias";
$SLIMPAY_PATH_KEY_DEV="scim.dev.slimpay.keystore.filename";
$SLIMPAY_PASSWORD_KEY_DEV="scim.dev.slimpay.keystore.password";
$SLIMPAY_CERT_PATH_KEY_DEV="scim.dev.slimpay.certificate.filename";
$SLIMPAY_CERT_URL_DEV="scim.dev.slimpay.certificate.url";
$CLIENT_NOTIFY_URL_KEY_DEV="scim.dev.client.notify.url";
$CLIENT_RETURN_URL_KEY_DEV="scim.dev.client.return.url";

//prod
$CLIENT_IDENTIFIER_KEY_PROD="scim.prod.site.id";
$SERVER_CALL_URL_PROD ="scim.prod.target.url";
$CLIENT_ALIAS_KEY_PROD = "scim.prod.client.key.alias";
$CLIENT_PATH_KEY_PROD = "scim.prod.client.keystore.filename";
$CLIENT_PASSWORD_KEY_PROD="scim.prod.client.keystore.password";
$CLIENT_PK_PASSWORD_KEY_PROD="scim.prod.client.privatekey.password";
$SLIMPAY_PATH_KEY_PROD="scim.prod.slimpay.keystore.filename";
$SLIMPAY_ALIAS_KEY_PROD="scim.prod.slimpay.key.alias";
$SLIMPAY_PASSWORD_KEY_PROD="scim.prod.slimpay.keystore.password";
$SLIMPAY_CERT_PATH_KEY_PROD="scim.prod.slimpay.certificate.filename";
$SLIMPAY_CERT_URL_PROD="scim.prod.slimpay.certificate.url";
$CLIENT_NOTIFY_URL_KEY_PROD="scim.prod.client.notify.url";
$CLIENT_RETURN_URL_KEY_PROD="scim.prod.client.return.url";
	
$PREFIX_COMMAND=$LANG_VARIABLE.'java -Dfile.encoding=UTF-8 -Dlog4j.configuration=file:'.$LOGGER_CONFIG.' -Dscim.home='.$SCIM_HOME.' -jar '.$JAR;

?>
