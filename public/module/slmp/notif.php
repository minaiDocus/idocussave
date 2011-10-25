<?php

include_once "./include/common_php/variables.php";

$blob = $_POST['blob'];
$command =$PREFIX_COMMAND.' -response '.$blob;
$result = shell_exec($command);
$pairs = explode("&", $result);
$mapping = array();
foreach ($pairs as $pair) {
	$pairArr = explode("=", $pair);
	$mapping[$pairArr[0]] = $pairArr[1];
}

$transactionId =  (isset($mapping['transactionId'])) ?  $mapping['transactionId'] : '' ;

$transactionStatus =  (isset($mapping['transactionStatus'])) ?  $mapping['transactionStatus'] : '' ;

$transactionErrorCode =  (isset($mapping['transactionErrorCode'])) ?  $mapping['transactionErrorCode'] : '' ;

$signatureOperationResult =  (isset($mapping['signatureOperationResult'])) ?  $mapping['signatureOperationResult'] : '' ;

$signatureDate =  (isset($mapping['signatureDate'])) ?  $mapping['signatureDate'] : '' ;

$mandateScore =  (isset($mapping['mandateScore'])) ?  $mapping['mandateScore'] : '' ;

$cardTransactionId =  (isset($mapping['cardTransactionId'])) ?  $mapping['cardTransactionId'] : '' ;

$cardRequestId =  (isset($mapping['cardRequestId'])) ?  $mapping['cardRequestId'] : '' ;

$cardOperationType =  (isset($mapping['cardOperationType'])) ?  $mapping['cardOperationType'] : '' ;

$cardOperationResult =  (isset($mapping['cardOperationResult'])) ?  $mapping['cardOperationResult'] : '' ;

$collectOperationResult =  (isset($mapping['collectOperationResult'])) ?  $mapping['collectOperationResult'] : '' ;

$invoiceReference =  (isset($mapping['invoiceReference'])) ?  $mapping['invoiceReference'] : '' ;

$invoiceAmount =  (isset($mapping['invoiceAmount'])) ?  $mapping['invoiceAmount'] : '' ;

$invoiceExecutionDate =  (isset($mapping['invoiceExecutionDate'])) ?  $mapping['invoiceExecutionDate'] : '' ;

$reference =  (isset($mapping['reference'])) ?  $mapping['reference'] : '' ;

$title =  (isset($mapping['title'])) ?  $mapping['title'] : '' ;

$firstName =  (isset($mapping['firstName'])) ?  $mapping['firstName'] : '' ;

$lastName =  (isset($mapping['lastName'])) ?  $mapping['lastName'] : '' ;

$email =  (isset($mapping['email'])) ?  $mapping['email'] : '' ;

$bic =  (isset($mapping['bic'])) ?  $mapping['bic'] : '' ;

$iban =  (isset($mapping['iban'])) ?  $mapping['iban'] : '' ;

$RUM =  (isset($mapping['RUM'])) ?  $mapping['RUM'] : '' ;

$companyName =  (isset($mapping['companyName'])) ?  $mapping['companyName'] : '' ;

$organizationId =  (isset($mapping['organizationId'])) ?  $mapping['organizationId'] : '' ;

$invoiceLine1 =  (isset($mapping['invoiceLine1'])) ?  $mapping['invoiceLine1'] : '' ;

$invoiceLine2 =  (isset($mapping['invoiceLine2'])) ?  $mapping['invoiceLine2'] : '' ;

$invoiceCity =  (isset($mapping['invoiceCity'])) ?  $mapping['invoiceCity'] : '' ;

$invoiceCountry =  (isset($mapping['invoiceCountry'])) ?  $mapping['invoiceCountry'] : '' ;

$invoicePostalCode =  (isset($mapping['invoicePostalCode'])) ?  $mapping['invoicePostalCode'] : '' ;

$deliveryLine1 =  (isset($mapping['deliveryLine1'])) ?  $mapping['deliveryLine1'] : '' ;

$deliveryLine2 =  (isset($mapping['deliveryLine2'])) ?  $mapping['deliveryLine2'] : '' ;

$deliveryCity =  (isset($mapping['deliveryCity'])) ?  $mapping['deliveryCity'] : '' ;

$deliveryCountry =  (isset($mapping['deliveryCountry'])) ?  $mapping['deliveryCountry'] : '' ;

$deliveryPostalCode =  (isset($mapping['deliveryPostalCode'])) ?  $mapping['deliveryPostalCode'] : '' ;
// Les valeurs récuperées doivent être persistées

$connexion = new Mongo("mongodb.alwaysdata.com:27017");

$db = null;

if ($_GET['environment'] == 'development') {
	$db = $connexion->grevalis_development;
	$db->authenticate("grevalis","grevidoc");
} else if ($_GET['environment'] == 'production') {
	$db = $connexion->grevalis_production;
	$db->authenticate("grevalis","grevidoc");
}

$user = $db->users->find(array("email" => $email));

$doc = array(
"transactionId" => $transactionId,
"transactionStatus" => $transactionStatus,
"transactionErrorCode" => $transactionErrorCode,
"signatureOperationResult" => $signatureOperationResult,
"signatureDate" => $signatureDate,
"mandateScore" => $mandateScore,
"cardTransactionId" => $cardTransactionId,
"cardRequestId" => $cardRequestId,
"cardOperationType" => $cardOperationType,
"cardOperationResult" => $cardOperationResult,
"collectOperationResult" => $collectOperationResult,
"invoiceReference" => $invoiceReference,
"invoiceAmount" => $invoiceAmount,
"invoiceExecutionDate" => $invoiceExecutionDate,
"reference" => $reference,
"title" => $title,
"firstName" => $firstName,
"lastName" => $lastName,
"email" => $email,
"bic" => $bic,
"iban" => $iban,
"RUM" => $RUM,
"companyName" => $companyName,
"organizationId" => $organizationId,
"invoiceLine1" => $invoiceLine1,
"invoiceLine2" => $invoiceLine2,
"invoiceCity" => $invoiceCity,
"invoiceCountry" => $invoiceCountry,
"invoicePostalCode" => $invoicePostalCode,
"deliveryLine1" => $deliveryLine1,
"deliveryLine2" => $deliveryLine2,
"deliveryCity" => $deliveryCity,
"deliveryCountry" => $deliveryCountry,
"deliveryPostalCode" => $deliveryPostalCode,
"user_id" => $user["_id"]
);

if (isset($user["debit_mandate_id"]) && $user["debit_mandate_id"] != null) {
	$db->debit_mandates->update(array("_id" => $user["debit_mandate_id"]),$doc);
} else {
	$db->debit_mandates->insert($doc);
	$current_debit_mandate = $db->debit_mandates->findOne(array("user_id" => $user["_id"]));
	$db->users->update(array("email" => $user["email"]),array('$set' => array("debit_mandate_id" => $current_debit_mandate["_id"])));
}

?>

