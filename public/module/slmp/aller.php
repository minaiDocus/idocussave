<?php

session_start();

include_once "./include/common_php/functions.php";
include_once "./include/common_php/errors.php";

$isError = "false";

$command = $PREFIX_COMMAND;

if(file_exists($PROPERTIES_FILE_PATH)){	

	$properties = new Properties($PROPERTIES_FILE_PATH);
	initializeProperties($properties);
	$cardPayment = $properties->getValue($CLIENT_CARD_PAYMENT_KEY);
	$mode = $properties->getValue($CLIENT_PRODUCTION_FLAG);
	if ($mode == "true") {
		$url = $properties->getValue($SERVER_CALL_URL_PROD);
	} else {
		$url = $properties->getValue($SERVER_CALL_URL_DEV);
	}
}
else{ 
	echo "ERROR, cannot find properties file: ".$PROPERTIES_FILE_PATH ;
	exit(2);	
}

$commandStart = $PREFIX_COMMAND;
	
$command = $commandStart;

if(isset($_POST['requestType'])&& $_POST['requestType'] !=''){
	$_SESSION['SlmRequestType'] = substitute($_POST['requestType']);
	$command.= ' -requestType "'.$_SESSION['SlmRequestType'].'"';
}
else {
	$_SESSION['SlmRequestType'] = $SlmErrorEmptyRequestType;
	$isError = "true";
}

if(isset($_POST['transactionId'])&& $_POST['transactionId'] !=''){
	$_SESSION['SlmTransactionId'] = substitute($_POST['transactionId']);
	$command.= ' -transactionId "'.$_SESSION['SlmTransactionId'].'"';
}

if(isset($_POST['clientReference']) && $_POST['clientReference']!=''){
	$_SESSION['SlmClientReference'] = substitute($_POST['clientReference']);
	$command.=' -clientReference "'.$_SESSION['SlmClientReference'].'"';
	if (isset($_SESSION['SlmErrorClientReference']))			 
		unset($_SESSION['SlmErrorClientReference']);
}
else {
	$_SESSION['SlmErrorClientReference'] = $SlmErrorEmptyClientReference;
	$isError = "true";
}

if(isset($_POST['clientType']) && $_POST['clientType'] !='' ){
	$_SESSION['SlmClientType'] = substitute($_POST['clientType']);
	$command .=' -clientType "'.$_SESSION['SlmClientType'].'"';
	if (isset($_SESSION['SlmErrorClientType']))			 
		unset($_SESSION['SlmErrorClientType']);
}
else {
	$_SESSION['SlmErrorClientType'] = $SlmErrorEmptyClientType;
	$isError = "true";
}

if(isset($_POST['companyName'])&& $_POST['companyName'] !=''  && isset($_POST['clientType']) && $_POST['clientType'] == 'corporate'){
	$_SESSION['SlmCompanyName']= substitute($_POST['companyName']);
	$command .=' -companyName "'.$_SESSION['SlmCompanyName'].'"';
	if (isset($_SESSION['SlmErrorCompanyName']))			 
		unset($_SESSION['SlmErrorCompanyName']);

} else if( isset($_POST['clientType']) && $_POST['clientType'] == 'corporate'){
	$_SESSION['SlmErrorCompanyName'] = $SlmErrorEmptyCompanyName;
	$isError = "true";
}

if(isset($_POST['organizationId'])&& $_POST['organizationId'] !=''){
	$_SESSION['SlmOrganizationId']= substitute($_POST['organizationId']);
	$command .=' -organizationId "'.$_SESSION['SlmOrganizationId'].'"';
}


if(isset($_POST['title'])&& $_POST['title'] !=''){
	$_SESSION['SlmTitle']= substitute($_POST['title']);
	$command .=' -contactTitle "'.$_SESSION['SlmTitle'].'"';
}

	
if(isset($_POST['firstName'])&& $_POST['firstName']!=''){
	$_SESSION['SlmFirstName']= substitute($_POST['firstName']);
	$command.= ' -contactFN "'.$_SESSION['SlmFirstName'].'"';
	if (isset($_SESSION['SlmErrorFirstName']))			 
		unset($_SESSION['SlmErrorFirstName']);
}
else {	
	$_SESSION['SlmErrorFirstName'] = $SlmErrorEmptyFirstName;
	$isError = "true";
}
		
if(isset($_POST['lastName'])&& $_POST['lastName']!=''){
	$_SESSION['SlmLastName']= substitute($_POST['lastName']);
	$command.= ' -contactLN "'.$_SESSION['SlmLastName'].'"';
	if (isset($_SESSION['SlmErrorLastName']))			 
		unset($_SESSION['SlmErrorLastName']);
}
else {
	$_SESSION['SlmErrorLastName'] = $SlmErrorEmptyLastName;
	$isError = "true";
}
			
if(isset($_POST['countryCode'])&& $_POST['countryCode']!=''){
	$_SESSION['SlmPhoneCountryCode'] = substitute($_POST['countryCode']);
	if (isset($_SESSION['SlmErrorCountryCode']))			 
		unset($_SESSION['SlmErrorCountryCode']);
}	
else {
	$_SESSION['SlmErrorCountryCode'] = $SlmErrorEmptyCountryCode;
	$isError = "true";
}
		
if(isset($_POST['phoneNumber'])&& $_POST['phoneNumber']!=''){
	$_SESSION['SlmPhone']= substitute($_POST['phoneNumber']);
	$command.= ' -contactPhone "'. $_SESSION['SlmPhoneCountryCode'].$_SESSION['SlmPhone'].'"';
	if (isset($_SESSION['SlmErrorPhone']))			 
		unset($_SESSION['SlmErrorPhone']);
}

if(isset($_POST['email'])&& $_POST['email']!=''){
	$_SESSION['SlmEmail']= substitute($_POST['email']);
	$command.= ' -contactEmail "'.$_SESSION['SlmEmail'].'"';
	if (isset($_SESSION['SlmErrorEmail']))			 
		unset($_SESSION['SlmErrorEmail']);
}

if(isset($_POST['line1Inv']) && $_POST['line1Inv']!=''){
	$_SESSION['SlmLine1Inv']= substitute($_POST['line1Inv']);
	$command.= ' -Iline1 "'.$_SESSION['SlmLine1Inv'].'"';
	if (isset($_SESSION['SlmErrorLine1Inv']))			 
		unset($_SESSION['SlmErrorLine1Inv']);
}
else {
	$_SESSION['SlmErrorLine1Inv'] = $SlmErrorEmptyLine1Inv;
	$isError = "true";
}

if(isset($_POST['line2Inv']) && $_POST['line2Inv'] !=''){
	$_SESSION['SlmLine2Inv']= substitute($_POST['line2Inv']);
	$command .= ' -Iline2 "'.$_SESSION['SlmLine2Inv'].'"';	
}

			
if(isset($_POST['cityInv'])&& $_POST['cityInv']!=''){
	$_SESSION['SlmCityInv']= substitute($_POST['cityInv']);
	$command.= ' -Icity "'.$_SESSION['SlmCityInv'].'"';
	if (isset($_SESSION['SlmErrorCityInv']))			 
		unset($_SESSION['SlmErrorCityInv']);
}
else {
	$_SESSION['SlmErrorCityInv'] = $SlmErrorEmptyCityInv;
	$isError = "true";
}

if(isset($_POST['postalCodeInv'])&& $_POST['postalCodeInv']!=''){
	$_SESSION['SlmPostalCodeInv']= substitute($_POST['postalCodeInv']);
	$command.= ' -IpostalCode "'.$_SESSION['SlmPostalCodeInv'].'"';
	if (isset($_SESSION['SlmErrorPostalCodeInv']))			 
		unset($_SESSION['SlmErrorPostalCodeInv']);
}
else {
	$_SESSION['SlmErrorPostalCodeInv'] = $SlmErrorEmptyPostalCodeInv;
	$isError = "true";
}
			
if(isset($_POST['countryInv'])&& $_POST['countryInv']!=''){
	$_SESSION['SlmCountryInv']= substitute($_POST['countryInv']);
	$command.= ' -Icountry "'.$_SESSION['SlmCountryInv'].'"';
	if (isset($_SESSION['SlmErrorCountryInv']))			 
		unset($_SESSION['SlmErrorCountryInv']);
}
else {
	$_SESSION['SlmErrorCountryInv'] = $SlmErrorEmptyCountryInv;
	$isError = "true";
}
		
if(isset($_POST['line1Delv'])&& $_POST['line1Delv'] !=''){
	$_SESSION['SlmLine1Delv']= substitute($_POST['line1Delv']);
	$command .=' -Dline1 "'.$_SESSION['SlmLine1Delv'].'"';
}
		
if(isset($_POST['line2Delv'])&& $_POST['line2Delv'] !=''){
	$_SESSION['SlmLine2Delv']= substitute($_POST['line2Delv']);
	$command .= ' -Dline2 "'.$_SESSION['SlmLine2Delv'].'"';
}
		
if(isset($_POST['cityDelv'])&& $_POST['cityDelv'] !=''){
	$_SESSION['SlmCityDelv']= substitute($_POST['cityDelv']);
	$command .= ' -Dcity "'.$_SESSION['SlmCityDelv'].'"';
}

if(isset($_POST['countryDelv'])&& $_POST['countryDelv'] !=''){
	$_SESSION['SlmCountryDelv']= substitute($_POST['countryDelv']);
	$command .=' -Dcountry "'.$_SESSION['SlmCountryDelv'].'"';
}

if(isset($_POST['postalCodeDelv'])&& $_POST['postalCodeDelv'] !=''){
	$_SESSION['SlmPostalCodeDelv']= substitute($_POST['postalCodeDelv']);
	$command .= ' -DpostalCode "'.$_SESSION['SlmPostalCodeDelv'].'"';
}

if(isset($_POST['bic'])&& $_POST['bic']!=''){
	$_SESSION['SlmBic']= substitute($_POST['bic']);
	$command.= ' -bic "'.$_SESSION['SlmBic'].'"';
	
}
		
if(isset($_POST['iban'])&& $_POST['iban']!=''){
	$iban= substitute($_POST['iban']);
	$iban=str_replace (' ','',$iban);
	$_SESSION['SlmIban']=str_replace ('-','',$iban);
	$command.= ' -iban "'.$_SESSION['SlmIban'].'"';
}

if(isset($_POST['invoiceReference']) && $_POST['invoiceReference'] != ''){
	$_SESSION['SlmPaymentReference'] = substitute($_POST['invoiceReference']);
	$command.= ' -invoiceReference "'.$_SESSION['SlmPaymentReference'].'"';
}

if(isset($_POST['rum'])&& $_POST['rum'] !=''){
	$_SESSION['SlmRum'] = substitute($_POST['rum']);
	$command.= ' -RUM "'.$_SESSION['SlmRum'].'"';
}

if(isset($_POST['requestType'])  && $_POST['requestType'] == 'collectPayment'){				
	
	$_SESSION['SlmRequestType'] = $_POST['requestType'] ;
		
	if(isset($_POST['debitAmount']) && $_POST['debitAmount'] != null ){
		$debitAmount= substitute($_POST['debitAmount']);
		$_SESSION['SlmAmount'] = slm_parse_number($debitAmount);
		$command .=' -debitAmount "'.$_SESSION['SlmAmount'].'"';
		if (isset($_SESSION['SlmErrorAmount']))			 
			unset($_SESSION['SlmErrorAmount']);
			
	}else{
			$_SESSION['SlmErrorAmount'] = $SlmErrorEmptyAmount;
			$isError = "true";
	}
		
	if(isset($_POST['debitExecutionDate']) && $_POST['debitExecutionDate'] != '' ){
		$debitExecutionDate= substitute($_POST['debitExecutionDate']);
		if ( preg_match( '/[0-9]{2}\/[0-9]{2}\/[0-9]{4}/', $debitExecutionDate))
		{
			$pairs = explode("/", $debitExecutionDate);
			$_SESSION['SlmExecutionDate'] = $pairs[2].'-'.$pairs[1].'-'.$pairs[0];
			$command .=' -debitExecutionDate "'.$_SESSION['SlmExecutionDate'].'"';
			$_SESSION['SlmExecutionDate'] = $debitExecutionDate ;
			if (isset($_SESSION['SlmErrorExecutionDate']))			 
				unset($_SESSION['SlmErrorExecutionDate']);
		}
		else {

			$_SESSION['SlmErrorExecutionDate'] = $SlmErrorFormatExecutionDate;
			$isError = "true";
		}
	}
	else {
			$_SESSION['SlmErrorExecutionDate'] = $SlmErrorEmptyExecutionDate;
			$isError = "true";
	}
	
	if(isset($_POST['debitLabel']) && $_POST['debitLabel'] != null ){
		$debitLabel= substitute($_POST['debitLabel']);
		$_SESSION['SlmLabel'] = slm_parse_number($debitLabel);
		$command .=' -debitLabel "'.$_SESSION['SlmLabel'].'"';
	}
}


if($cardPayment == 'true'){

		if(isset($_POST['cardOperationType'])&& $_POST['cardOperationType'] !=''){
			$_SESSION['SlmCardOperationType'] = substitute($_POST['cardOperationType']);
			$command.= ' -cardOperation "'.$_SESSION['SlmCardOperationType'].'"';
			if (isset($_SESSION['SlmErrorCardOperationType']))			 
				unset($_SESSION['SlmErrorCardOperationType']);
		}
		else {
			$_SESSION['SlmErrorCardOperationType'] = $SlmErrorEmptyCardOperationType;
			$isError = "true";
		}
				
		if(isset($_POST['cardAmount'])&& $_POST['cardAmount']!=''){
			 $amount=substitute($_POST['cardAmount']); 
			 $_SESSION['SlmCardAmount'] = slm_parse_number($amount);
			 $command .= ' -cardAmount "'.$_SESSION['SlmCardAmount'].'"';
			 if (isset($_SESSION['SlmErrorCardAmount']))			 
				unset($_SESSION['SlmErrorCardAmount']);
		}
		else {
			$_SESSION['SlmErrorCardAmount'] = $SlmErrorEmptyCardAmount;
			$isError = "true";
		} 
	}

$refererUrl = $_SERVER['HTTP_REFERER'];	


if ($isError == "false"){
	$result = shell_exec($command);
	if(strstr($result,"ERROR")==null && $result != null){
			echo '<?xml version="1.0" encoding="UTF-8"?>';
	?>		
				<html>
					<header></header>
					<body onload="document.forms['mainForm'].submit()">
						<form action="<?php echo stripslashes($url) ;?>" method="post" name="mainForm"> 
							<input type="hidden" name="blob" value="<?php echo $result; ?> "/>
							<noscript>
								<input type="submit" name="envoyer" value="envoyer" />
							</noscript>
						</form>
					</body>
				</html> 
				  	
<?php	}
	else{
		$result = runExternal($command,$code);
		if (isset($result))	
			$_SESSION['scimResult'] = $result;
		header ("location:".stripslashes($refererUrl));
	}	
}
else {

	header ("location:".stripslashes($refererUrl));
}

?>
