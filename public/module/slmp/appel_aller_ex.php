<?php
session_start();

echo '<?xml version="1.0" encoding="UTF-8"?> ';
$javascript='<script type="text/javascript" charset="UTF-8" src="./include/js/slimpay-tpe.js"></script>';
include_once "./include/common_php/header.php";

?>
<BODY onload="updateCorporateDetails();updateDebitDetails();">

<?php include_once "./include/common_php/head.php";?>

<div id="center">
	<div id="content">
<?php 
	include_once "./include/common_php/functions.php";
	include_once "./include/common_php/errors.php";
	
	if(file_exists($PROPERTIES_FILE_PATH)){	
		
		$properties = new Properties($PROPERTIES_FILE_PATH);
		initializeProperties($properties);
		$isCardPayment = $properties->getValue($CLIENT_CARD_PAYMENT_KEY);
		$isProductionMode = $properties->getValue($CLIENT_PRODUCTION_FLAG)  ;
		$identifier = ($isProductionMode == 'true') ? $properties->getValue($CLIENT_IDENTIFIER_KEY_PROD) : $properties->getValue($CLIENT_IDENTIFIER_KEY_DEV); 
	}
	else {
		echo $SlmErrorNotFoundPropertiesFile. ' [' .$PROPERTIES_FILE_PATH .']' ;
	}
?>
		<h1>Enregistrement</h1>

			<form id="mainForm" action="aller.php" method= "POST">
							
				<?php
					if(isset($_SESSION['scimResult']) && $_SESSION['scimResult'] !=''){
						echo '<hr>' ;			
						echo $_SESSION['scimResult'];
						echo '<hr>' ;			
					}
				?>			
								
				<div class="comment">Les champs marqu&eacute;es d'un * sont obligatoires.</div>
				
				<h4>Informations d'identification</h4>
		

				<div style = "">
					<label>Transaction ID: </label>
					<input type="text" size="20" name="transactionId" id="transactionId" value="<?php if(isset($_SESSION['SlmTransactionId'])) echo $_SESSION['SlmTransactionId'];?>">
				</div>

				<div  style=""> 
					<label for="clientType">Type de client*:</label> 
					<input id="clientType1" name="clientType" type="radio" value="individual" onchange="updateCorporateDetails()" onclick="updateCorporateDetails()" onkeypress="updateCorporateDetails()" 
					<?php if( ! isset($_SESSION['SlmClientType']) || $_SESSION['SlmClientType'] == 'individual' ) echo 'checked';?>	/>Particulier 
					<input id="clientType2" name="clientType" type="radio" value="corporate" onchange="updateCorporateDetails()" onclick="updateCorporateDetails()" onkeypress="updateCorporateDetails()"
					<?php if(isset($_SESSION['SlmClientType']) && $_SESSION['SlmClientType'] == 'corporate' ) echo 'checked';?> />Entreprise 
		
				</div> 

				<div id="corporateDetails" style="">
					<div style="">
						<label for="companyName">Raison sociale *:</label>
						<input type="text" size=20 name="companyName" id="companyName" maxlength="70" value="<?php if(isset($_SESSION['SlmCompanyName'])) echo $_SESSION['SlmCompanyName'];?>">
						<label id = "errorTextCityInv"><font color="red"><?php if(isset($_SESSION['SlmErrorCompanyName'])) echo $_SESSION['SlmErrorCompanyName'];?></font></label>
					</div>
					<div style="">
						<label for="organizationId">SIRET:</label>
						<input type="text" size=20 name="organizationId" id="organizationId" value="<?php if(isset($_SESSION['SlmOrganizationId'])) echo $_SESSION['SlmOrganizationId'];?>">
					</div>
				</div>
<div>
						<label for="title">Civilit&eacute;:</label>
						<input id="title1" name="title" type="radio" value="mr" <?php if(isset($_SESSION['SlmTitle']) && $_SESSION['SlmTitle'] == 'mr') echo ' checked';?>  onchange="" onclick="" onkeypress="" />M
						<input id="title2" name="title" type="radio" value="miss" <?php if(isset($_SESSION['SlmTitle']) && $_SESSION['SlmTitle'] == 'miss') echo ' checked';?> onchange="" onclick="" onkeypress="" />Melle
						<input id="title3" name="title" type="radio" value="mrs" <?php if(isset($_SESSION['SlmTitle']) && $_SESSION['SlmTitle'] == 'mrs') echo ' checked';?> onchange="" onclick="" onkeypress="" />Mme	
				</div>
				<div>
					<label>Pr&eacute;nom*:</label>
					<input type="text "size="20" name="firstName" maxlength="32" id= "firstName" value="<?php if(isset($_SESSION['SlmFirstName'])) echo $_SESSION['SlmFirstName'];?>">
					<label id = "errorTextFirstName"><font color="red"><?php if(isset($_SESSION['SlmErrorFirstName'])) echo $_SESSION['SlmErrorFirstName'];?></font></label>
				</div>		
				<div>
					<label>Nom*:</label>
					<input type="text" size="20" name="lastName" maxlength="32" id="lastName" value="<?php if(isset($_SESSION['SlmLastName'])) echo $_SESSION['SlmLastName'];?>">
					<label id = "errorTextLastName"><font color="red"><?php if(isset($_SESSION['SlmErrorLastName'])) echo $_SESSION['SlmErrorLastName'];?></font></label> 		
				</div>
	
				<div>
					<label>Identifiant du client*:</label>
					<input type=text size=20 name="clientReference" id="clientReference" value = "<?php if(isset($_SESSION['SlmClientReference'])) echo $_SESSION['SlmClientReference'];?>" >
					<label id = "errorTextClientReference"><font color="red"><?php if(isset($_SESSION['SlmErrorClientReference'])) echo $_SESSION['SlmErrorClientReference'];?></font></label>
				</div>
				<div>
					<label for="phone">T&eacute;l&eacute;phone portable (accessible):</label>
					<select id="countryCode" name="countryCode" class="phoneCountryCode"  size="1">
						<option value=""></option>
						<option value="+49">+49</option>
						<option value="+43">+43</option>
						<option value="+32">+32</option>
						<option value="+359">+359</option>
						<option value="+357">+357</option>
						<option value="+45">+45</option>
						<option value="+34">+34</option>
						<option value="+372">+372</option>
						<option value="+358">+358</option>
						<option value="+33" selected="selected">+33</option>
						<option value="+350">+350</option>
						<option value="+30">+30</option>
						<option value="+590">+590</option>
						<option value="+594">+594</option>
						<option value="+36">+36</option>
						<option value="+353">+353</option>
						<option value="+354">+354</option>
						<option value="+39">+39</option>
						<option value="+371">+371</option>
						<option value="+423">+423</option>
						<option value="+370">+370</option>
						<option value="+352">+352</option>
						<option value="+356">+356</option>
						<option value="+596">+596</option>
						<option value="+337">+337</option>
						<option value="+47">+47</option>
						<option value="+31">+31</option>
						<option value="+48">+48</option>
						<option value="+351">+351</option>
						<option value="+40">+40</option>
						<option value="+44">+44</option>
						<option value="+420">+420</option>
						<option value="+262">+262</option>
						<option value="+421">+421</option>
						<option value="+386">+386</option>
						<option value="+41">+41</option>
						<option value="+46">+46</option>
						<option value="+248">+248</option>
					</select>
					<input type="text" size=20 name="phoneNumber" id="phone" maxlength="10" value="<?php if(isset($_SESSION['SlmPhone'])) echo $_SESSION['SlmPhone'];?>">	
				</div>
				<div  style="">
					<label for="email">Email:</label>
					<input type="text" size=20 name="email" maxlength="70" value="<?php if(isset($_SESSION['SlmEmail'])) echo $_SESSION['SlmEmail'];?>">
				</div>
			<h4>Adresse de facturation</h4>

	
			<div  style="">
				<label for="invoiceAddress.line1">Adresse *:</label> 
				<input type="text" maxlength="70" size=20 name="line1Inv" id="line1Inv" value="<?php if(isset($_SESSION['SlmLine1Inv'])) echo $_SESSION['SlmLine1Inv'];?>">	
				<label id = "errorTextLine1Inv"><font color="red"><?php if(isset($_SESSION['SlmErrorLine1Inv'])) echo $_SESSION['SlmErrorLine1Inv'];?></font></label>
			</div>
			<div  style="">
				<label for="line2">Compl&eacute;ment d'adresse:</label> 
				<input type="text" size="20" name="line2Inv" maxlength="70"  id="line2Inv" value="<?php if(isset($_SESSION['SlmLine2Inv'])) echo $_SESSION['SlmLine2Inv'];?>">
			</div>

			<div  style="">
				<label for="invoiceAddress.city">Ville*:</label>
				<input type="text" size="20" name="cityInv" maxlength="35" id ="cityInv" value="<?php if(isset($_SESSION['SlmCityInv'])) echo $_SESSION['SlmCityInv'];?>">

				<label id = "errorTextCityInv"><font color="red"><?php if(isset($_SESSION['SlmErrorCityInv'])) echo $_SESSION['SlmErrorCityInv'];?></font></label>
			</div>
			<div  style="">
				<label for="invoiceAddress.zipcode">Code postal*:</label>
				<input type=text size=20 name=postalCodeInv id ="postalCodeInv" maxlength="5"  value="<?php if(isset($_SESSION['SlmPostalCodeInv'])) echo $_SESSION['SlmPostalCodeInv'];?>">
				<label id = "errorTextPostalCodeInv"><font color="red"><?php if(isset($_SESSION['SlmErrorPostalCodeInv'])) echo $_SESSION['SlmErrorPostalCodeInv'];?></font></label>
			</div>
				<div >		
				<label for="countryInv">Pays*:</label>
				<select id="countryInv" name=countryInv size="1">
					<option value="DE">Allemagne</option>
					<option value="AT">Autriche</option>
					<option value="BE">Belgique</option>
					<option value="BG">Bulgarie</option>
					<option value="CY">Chypre</option>

					<option value="DK">Danemark</option>
					<option value="ES">Espagne</option>
					<option value="EE">Estonie</option>
					<option value="FI">Finlande</option>
					<option value="FR" selected="selected">France</option>
					<option value="GI">Gibraltar</option>

					<option value="GR">Grèce</option>
					<option value="GP">Guadeloupe</option>
					<option value="GF">Guyane Française</option>
					<option value="HU">Hungary</option>
					<option value="IE">Irlande</option>
					<option value="IS">Islande</option>

					<option value="IT">Italie</option>
					<option value="LV">Lettonie</option>
					<option value="LI">Liechtenstein</option>
					<option value="LT">Lituanie</option>
					<option value="LU">Luxembourg</option>
					<option value="MT">Malte</option>

					<option value="MQ">Martinique</option>
					<option value="MC">Monaco</option>
					<option value="NO">Norvège</option>
					<option value="NL">Pays-Bas</option>
					<option value="PL">Pologne</option>
					<option value="PT">Portugal</option>

					<option value="RO">Roumanie</option>
					<option value="GB">Royaume-Uni</option>
					<option value="CZ">R&eacute;publique Tchèque</option>
					<option value="RE">R&eacute;union</option>
					<option value="SK">Slovaquie</option>
					<option value="SI">Slov&eacute;nie</option>

					<option value="CH">Suisse</option>
					<option value="SE">Suède</option>
					<option value="AX">Îles Åland</option>
				</select>		
			</div>
	
			<h4>Adresse de livraison</h4>	
	
			<div  style="">
				<label>Adresse:</label> 
				<input type="text" size="20" name="line1Delv" maxlength="70"  id="line1Delv" value="<?php if(isset($_SESSION['SlmLine1Delv'])) echo $_SESSION['SlmLine1Delv'];?>">	
			</div>
			<div  style="">
				<label >Compl&eacute;ment d'adresse:</label>
				<input type="text" size="20" name="line2Delv" maxlength="70"  id="line2Delv" value="<?php if(isset($_SESSION['SlmLine2Delv'])) echo $_SESSION['SlmLine2Delv'];?>">
			</div>

			<div  style="">
				<label >Ville:</label> 
				<input type="text" size="20" name="cityDelv" maxlength="35" id="cityDelv" value="<?php if(isset($_SESSION['SlmCityDelv'])) echo $_SESSION['SlmCityDelv'];?>">
			</div>
			<div  style="">
				<label >Code postal:</label>
				<input type=text size="20" name="postalCodeDelv" maxlength="5"  id="postalCodeDelv" value="<?php if(isset($_SESSION['SlmPostalCodeDelv'])) echo $_SESSION['SlmPostalCodeDelv'];?>">	
			</div>
				<div >		
				<label for="countryDelv">Pays:</label>
				<select id="countryDelv" name=countryDelv size="1"> 
					<option value="DE">Allemagne</option>
					<option value="AT">Autriche</option>
					<option value="BE">Belgique</option>
					<option value="BG">Bulgarie</option>
					<option value="CY">Chypre</option>

					<option value="DK">Danemark</option>
					<option value="ES">Espagne</option>
					<option value="EE">Estonie</option>
					<option value="FI">Finlande</option>
					<option value="FR" selected="selected">France</option>
					<option value="GI">Gibraltar</option>

					<option value="GR">Grèce</option>
					<option value="GP">Guadeloupe</option>
					<option value="GF">Guyane Française</option>
					<option value="HU">Hungary</option>
					<option value="IE">Irlande</option>
					<option value="IS">Islande</option>

					<option value="IT">Italie</option>
					<option value="LV">Lettonie</option>
					<option value="LI">Liechtenstein</option>
					<option value="LT">Lituanie</option>
					<option value="LU">Luxembourg</option>
					<option value="MT">Malte</option>

					<option value="MQ">Martinique</option>
					<option value="MC">Monaco</option>
					<option value="NO">Norvège</option>
					<option value="NL">Pays-Bas</option>
					<option value="PL">Pologne</option>
					<option value="PT">Portugal</option>

					<option value="RO">Roumanie</option>
					<option value="GB">Royaume-Uni</option>
					<option value="CZ">R&eacute;publique Tchèque</option>
					<option value="RE">R&eacute;union</option>
					<option value="SK">Slovaquie</option>
					<option value="SI">Slov&eacute;nie</option>

					<option value="CH">Suisse</option>
					<option value="SE">Suède</option>
					<option value="AX">Îles Åland</option>
				</select>		
			</div>
			<h4> Donnn&eacute;es bancaires:</h4>
	
					<div>
						<label>Bic:</label>
						<input type="text" size="20" maxlength="11"  name="bic" id ="bic" value="<?php if(isset($_SESSION['SlmBic'])) echo $_SESSION['SlmBic'];?>">
					</div>
		
					<div>
						<label>Iban:</label>
						<input type="text" size="20" maxlength="34"  name="iban" id="iban" value="<?php if(isset($_SESSION['SlmIban'])) echo $_SESSION['SlmIban'];?>">	
					</div>
		
			
			<h4> Transaction : </h4>	

				<div  style=""> 
					<label for="clientType">Type de requete*:</label> 
					<input id="requestType1" name="requestType" type="radio" value="mandate" onchange="updateDebitDetails()" onclick="updateDebitDetails()" onkeypress="updateDebitDetails()" <?php if( ! isset($_SESSION['SlmRequestType']) || $_SESSION['SlmRequestType'] == 'mandate' ) echo 'checked';?>	/>Signature de mandat uniquement.
					<input id="requestType2" name="requestType" type="radio" value="collectPayment" onchange="updateDebitDetails()" onclick="updateDebitDetails()" onkeypress="updateDebitDetails()"  <?php if( isset($_SESSION['SlmRequestType']) && $_SESSION['SlmRequestType'] == 'collectPayment' ) echo 'checked';?>/>Signature de mandat et pr&eacute;l&egrave;vement. 
		
				</div> 
				
				<div>
					<label>RUM:</label>
					<input type="text" size="20" name="rum" id="rum"  value="<?php if(isset($_SESSION['SlmRum'])) echo $_SESSION['SlmRum'];?>"></label>
				
				</div>
								
				<?php if($isCardPayment == 'true'){
					echo '<div><label>Type d\'op&eacute;ration carte*:</label> 
					<input id="cardOperationType1" name="cardOperationType" type="radio" value="authorization" onchange="updateCorporateDetails()" onclick="updateCorporateDetails()" onkeypress="updateCorporateDetails()"'; if(isset($_SESSION['SlmCardOperationType']) && $_SESSION['SlmCardOperationType'] == 'authorization' ) echo ' checked';
					echo '/>Autorisation uniquement.
					<input id="cardOperationType2" name="cardOperationType" type="radio" value="payment" onchange="updateCorporateDetails()" onclick="updateCorporateDetails()" onkeypress="updateCorporateDetails()"';if(isset($_SESSION['SlmCardOperationType']) && $_SESSION['SlmCardOperationType'] == 'payment' ) echo ' checked';
					echo ' />Autorisation et recouvrement. 
					</div>
					<label id = "SlmErrorCardOperationType"><font color="red">'; if(isset($_SESSION['SlmErrorCardOperationType'])) echo $_SESSION['SlmErrorCardOperationType'];
					echo '</font></label>';
					}
				?>	
				
				<div style = "">
					<label>R&eacute;f&eacute;rence facture: </label>
					<input type="text" size="20" name="invoiceReference" maxlength="35" id="commandReference" value="<?php if(isset($_SESSION['SlmPaymentReference'])) echo $_SESSION['SlmPaymentReference'];?>">
				</div>
				
				<div id="debit">
					<h4>Pr&eacute;l&egrave;vement bancaire</h4>					
					
					<div style = "">
						<label>Montant par pr&eacute;levement *: </label>

						<input type="bigDecimal" name="debitAmount" id="amount" size=20  id="amount" value="<?php if(isset($_SESSION['SlmAmount'])) echo $_SESSION['SlmAmount'];?>">
						<label>(ex: 103.50)</label>
						<label id = "SlmErrorAmount"><font color="red"><?php if(isset($_SESSION['SlmErrorAmount'])) echo $_SESSION['SlmErrorAmount'];?></font></label>
					</div>
						
					<div style = "">
						<label>Date d'ex&eacute;cution *: </label>
						<input type=text size=20 name="debitExecutionDate" id="executionDate"  value="<?php if(isset($_SESSION['SlmExecutionDate'])) echo $_SESSION['SlmExecutionDate'];?>">
						<label>(ex: 01/08/2012)</label>
						<label id = "SlmErrorExecutionDate"><font color="red"><?php if(isset($_SESSION['SlmErrorExecutionDate'])) echo $_SESSION['SlmErrorExecutionDate'];?></font></label>
					</div>
					<div style = "">
					<label>Lib&eacute;ll&eacute; : </label>
					<input type="text" size="60" name="debitLabel" id="label" maxlength="140" value="<?php if(isset($_SESSION['SlmLabel'])) echo $_SESSION['SlmLabel'];?>">
				</div>
				</div>


				<div style="<?php if($isCardPayment == 'false') echo 'display : none;'; else if($isCardPayment == 'true') echo '';?>">
					<h4>Pr&eacute;l&egrave;vement carte</h4>					
					
					<label for="amount">Montant carte bancaire*:</label>
					<input type="text" id="cardAmount" name="cardAmount"  maxlength="19"  value="<?php if(isset($_SESSION['SlmCardAmount'])) echo $_SESSION['SlmCardAmount'];?>">
					<label>(ex: 103.50)</label>
					<label id = "errorTextCardAmount"><font color="red"><?php if(isset($_SESSION['SlmErrorCardAmount'])) echo $_SESSION['SlmErrorCardAmount'];?></font></label>
				</div>
				
				<div class="center">	
					<input type="submit" id="saveReg" name="saveReg" value="Enregistrer" />
				</div>
	
		</form>
	
	</div><!-- end content-->
	
</div><!-- end center-->


<?php 
	include_once "./include/common_php/footer.php";	
	
?>	 

</HTML>
