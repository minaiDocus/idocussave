<?php
session_start();
require_once "./include/common_php/Properties.php";
include_once "./include/common_php/functions.php";
include_once "./include/common_php/variables.php";

$isError = "false";

$command = $PREFIX_COMMAND;

$command.= ' -requestType "init"';

$refererUrl = $_SERVER['HTTP_REFERER']	;
$refererUrl = cleanUrl($refererUrl);

if( isset($refererUrl) && $refererUrl != ''){
	$command .=' -clientInitializationUrl "'.$refererUrl.'"';
}
else {
	print "Missing refererUrl value. ";
	$isError = "true";
}

if(isset($_POST['mode']) && $_POST['mode'] != ''){
	
	$command .=' -mode "'.$_POST['mode'].'"';
	
	if ($_POST['mode']== "test"){
		$mode ="Dev";
		$serverCallUrl=$SERVER_CALL_URL_DEV;
	}
	
	else if($_POST['mode']== "production")
	{	
		if(isset($_POST['code']) && $_POST['code'] != ''){
			$code= substitute($_POST['code']);
			$command .= ' -code "'.$code.'"';
			if (isset($_SESSION['SlmErrorCode']))			 			
				unset($_SESSION['SlmErrorCode']);  

		}
		else{
			$_SESSION['SlmErrorCode'] = $SlmErrorEmptyCode;
			$isError = "true";		
		}
		$mode ="Prod";
		$serverCallUrl=$SERVER_CALL_URL_PROD;
	}
	else {
		$_SESSION['SlmErrorMode'] = $SlmErrorUnknownMode ;
		$isError = "true";		
	}

}
else{
	$_SESSION['SlmErrorMode'] = $SlmErrorEmptyMode ;
	$isError = "true";		
}

if(isset($mode) && ( $mode == 'Dev'  || $mode == 'Prod')) {
	
	$siteIdfield ='siteId'.$mode;
	
	if(isset($_POST[$siteIdfield]) && $_POST[$siteIdfield] != ''){
		$siteId = substitute($_POST[$siteIdfield]);
		$command .=' -siteId "'.$siteId.'"';
		
		if (isset($_SESSION['SlmErrorSiteId']))		
			unset($_SESSION['SlmErrorSiteId']); 
	}
	else {
		$_SESSION['SlmErrorSiteId'] = $SlmErrorEmptySiteId;
		$isError = "true";
	}
	
	if(isset($_POST['isCardPayment'])){

		$command .= ' -cardPayment '; 
			
		if(isset($_POST['terminalMerchant']) && $_POST['terminalMerchant'] != ''){
			$terminalMerchant= substitute($_POST['terminalMerchant']);
			$command .= ' -terminalMerchant "'.$terminalMerchant.'"'; 
			if (isset($_SESSION['SlmErrorTerminalMerchant']))			
				unset($_SESSION['SlmErrorTerminalMerchant']); 
		}
		else{				
			$_SESSION['SlmErrorTerminalMerchant'] =$SlmErrorEmptyTerminalMerchant;
			$isError = "true";	
		}
	
		if(isset($_POST['terminalKey']) && $_POST['terminalKey'] != ''){
			$terminalKey= substitute($_POST['terminalKey']);
			$command .= ' -terminalKey "'.$terminalKey.'"'; 
			if (isset($_SESSION['SlmErrorTerminalKey']))			
				unset($_SESSION['SlmErrorTerminalKey']); 
		} 
		else {				
			$_SESSION['SlmErrorTerminalKey'] =$SlmErrorEmptyTerminalKey;
			$isError = "true";	
		}
		
		if(isset($_POST['terminalOrder']) && $_POST['terminalOrder'] != ''){
			$terminalOrder= substitute($_POST['terminalOrder']);
			$command .= ' -terminalOrder "'.$terminalOrder.'"';
			if (isset($_SESSION['SlmErrorTerminalOrder']))			 
				unset($_SESSION['SlmErrorTerminalOrder']); 
		}
		else{				
			$_SESSION['SlmErrorTerminalOrder'] =$SlmErrorEmptyTerminalOrder;
			$isError = "true";	
		}
	}
	
	if(isset($_POST['config']))
	{
		if($_POST['config'] == 'manual')
		{	
			
			$clientPathfield ='clientPath'.$mode;
		
			if(isset($_POST[$clientPathfield]) && $_POST[$clientPathfield] != '' ){
				$clientPath = substitute($_POST[$clientPathfield]);
				$command  .= ' -clientKeyStorePath "'.$clientPath.'"';
				if (isset($_SESSION['SlmErrorClientPath']))			 			
					unset($_SESSION['SlmErrorClientPath']);  
			}
			else {
				$_SESSION['SlmErrorClientPath'] =$SlmErrorEmptyClientPath;
				$isError = "true";
			}
		
			$clientPasswordfield ='clientPassword'.$mode;
		
			if(isset($_POST[$clientPasswordfield]) && $_POST[$clientPasswordfield] != ''){
				$clientPassword = substitute($_POST[$clientPasswordfield]);
				$command  .= ' -clientKeyStorePassword "'.$clientPassword.'"';
				if (isset($_SESSION['SlmErrorClientPassword']))			 						
					unset($_SESSION['SlmErrorClientPassword']);  
			}
			else{
				$_SESSION['SlmErrorClientPassword'] =$SlmErrorEmptyClientPassword;
				$isError = "true";
			}
			
			$clientKeyPasswordfield ='clientKeyPassword'.$mode;
			
			if(isset($_POST[$clientKeyPasswordfield]) && $_POST[$clientKeyPasswordfield] != ''){
				$clientPassword = substitute($_POST[$clientKeyPasswordfield]);
				$command  .= ' -clientPrivateKeyPassword "'.$clientPassword.'"';
			}
			
			$clientAliasfield ='clientAlias'.$mode;
		
			if(isset($_POST[$clientAliasfield]) && $_POST[$clientAliasfield] != ''){
				$clientAlias= substitute($_POST[$clientAliasfield]);
				$command  .= ' -clientAlias "'.$clientAlias.'"';
				if (isset($_SESSION['SlmErrorClientAlias']))			 						
					unset($_SESSION['SlmErrorClientAlias']);  
			}
			else {			
				$_SESSION['SlmErrorClientAlias'] =$SlmErrorEmptyClientAlias;
				$isError = "true";
			}
		}
	}
	
	$returnUrlfield ='returnUrl'.$mode;
	
	if(isset($_POST[$returnUrlfield]) && $_POST[$returnUrlfield] != ''){
		$returnUrl = substitute($_POST[$returnUrlfield]);
		$command .= ' -returnUrl "'.$returnUrl.'"';
		if (isset($_SESSION['SlmErrorReturnUrl']))	
			unset($_SESSION['SlmErrorReturnUrl']); 
	}
	else {	
		$_SESSION['SlmErrorReturnUrl'] = $SlmErrorEmptyReturnUrl;
		$isError = "true";
	}
	
	$notifyUrlfield ='notifyUrl'.$mode;

	if(isset($_POST[$notifyUrlfield]) && $_POST[$notifyUrlfield] != ''){
		$notifyUrl = substitute($_POST[$notifyUrlfield]);
		$command .= ' -notifyUrl "'.$notifyUrl.'"';
		if (isset($_SESSION['SlmErrorNotifyUrl']))	
			unset($_SESSION['SlmErrorNotifyUrl']); 
	}
	else {	
		$_SESSION['SlmErrorNotifyUrl'] = $SlmErrorEmptyNotifyUrl;
		$isError = "true";
	}
	

}



if( $isError == "false"){
	$result = shell_exec($command);

}
else {
	if (isset($_POST['mode']))	
		$_SESSION['mode'] = $_POST['mode'];
	if (isset($_POST['config']))
		$_SESSION['config'] = $_POST['config'];
	if (isset($_POST['cardPayment']))
		$_SESSION['isCardPayment'] = $_POST['cardPayment'];
	header ("location:".stripslashes($refererUrl));

}
if(strstr($result,"ERROR")==null && $result != null){

	if(file_exists($PROPERTIES_FILE_PATH)){	
		$properties = new Properties($PROPERTIES_FILE_PATH);
		$properties->setNewLineAsOS();
		$properties->readContent();
		$url = $properties->getValue($serverCallUrl);
	}
	
	echo '<?xml version="1.0" encoding="UTF-8"?>';
	$javascript="";
?>
		<?php include_once "./include/common_php/header.php";?>
		<body onload="document.forms['mainForm'].submit()">
			<?php include_once "./include/common_php/head.php";?>
			<div id="center">
				<div id="content">
					<form action="<?php echo stripslashes($url); ?>" method="post" name="mainForm"> 
						<input type="hidden" name="blob" value="<?php echo $result; ?>"/>
						<noscript>
							<input type="submit" name="envoyer" value="Envoyer"/>
						</noscript>
					</form>
				</div>
			</div>
		</body>
	</html>
<?php
}
else{
	$result = runExternal($command,$code);
	if (isset($_POST['mode']))	
		$_SESSION['mode'] = $_POST['mode'];
	if (isset($_POST['config']))	
		$_SESSION['config'] = $_POST['config'];
	if (isset($_POST['isCardPayment']))	
		$_SESSION['isCardPayment'] = $_POST['isCardPayment'];
	if (isset($result))	
		$_SESSION['scimResult'] = $result;

	header ("location:".stripslashes($refererUrl));

}

?>

