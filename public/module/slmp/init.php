<?php
session_start();
session_unset();
echo '<?xml version="1.0" encoding="UTF-8"?>';
$javascript='<script type="text/javascript" charset="UTF-8" src="./include/js/init-tpe.js"></script>';
include_once "./include/common_php/header.php";

?>
<BODY onload="load();">

<?php include_once "./include/common_php/head.php";?> 

	<div id="center">
		
		<div id="content">
	
			<?php

			include_once "./include/common_php/functions.php";
			include_once "./include/common_php/errors.php";
			if(isset($_POST['blob'])){

				$pairResulted = decodeResponse( $PREFIX_COMMAND,$_POST['blob']);
				if(isset($pairResulted['transactionStatus'])){
					if($pairResulted['transactionStatus'] == 'success'){
						$_SESSION['scimResultSuccess'] = $scimResultSuccess ;
					}
					else if($pairResulted['transactionStatus'] == 'failure'){
						$_SESSION['scimResultFailure'] = $scimResultFailure.' : '.$pairResulted['errorCodes'];
					}
				}
				$uri = $_SERVER['REQUEST_URI'] ;
				$_SERVER['REQUEST_URI'] = cleanUrl($uri);
	
			}
			
			$isFirstInit = ! file_exists($PROPERTIES_FILE_PATH);
			
			if(! $isFirstInit){	
				$properties = new Properties($PROPERTIES_FILE_PATH);
				initializeProperties($properties);
			}

			$isProductionMode = ($isFirstInit) ?  '' : $properties->getValue($CLIENT_PRODUCTION_FLAG)  ;
			$mode = ($isProductionMode == 'true') ? 'PROD' : 'DEV'; 
							
			$identifierDev =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_IDENTIFIER_KEY_DEV)  ;
			$clientAliasDev =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_ALIAS_KEY_DEV) ;
			$clientPathDev =  ($isFirstInit) ?  '' : $properties->getValue($CLIENT_PATH_KEY_DEV) ;
			$clientPathDev  = stripslashes($clientPathDev);
			$clientPasswordDev =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_PASSWORD_KEY_DEV)  ;
			$clientKeyPasswordDev =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_PK_PASSWORD_KEY_DEV)  ;
			$slimpayAliasDev =  ($isFirstInit) ?  '' : $properties->getValue($SLIMPAY_ALIAS_KEY_DEV) ;			
			$slimpayPathDev =  ($isFirstInit) ?  '' :  $properties->getValue($SLIMPAY_PATH_KEY_DEV)  ;
			$slimpayPathDev  = stripslashes($slimpayPathDev);
			$slimpayPasswordDev =  ($isFirstInit) ?  '' :  $properties->getValue($SLIMPAY_PASSWORD_KEY_DEV)  ;
			$slimpayCertDev = ($isFirstInit) ?  '' : $properties->getValue($SLIMPAY_CERT_PATH_KEY_DEV) ;
			$returnUrlDev =  ($isFirstInit) ?  '' :  stripslashes($properties->getValue($CLIENT_RETURN_URL_KEY_DEV))  ;
			$notifyUrlDev =  ($isFirstInit) ?  '' :  stripslashes($properties->getValue($CLIENT_NOTIFY_URL_KEY_DEV))  ;
			
			$identifierProd =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_IDENTIFIER_KEY_PROD)  ;
			$clientAliasProd =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_ALIAS_KEY_PROD) ;
			$clientPathProd =  ($isFirstInit) ?  '' : $properties->getValue($CLIENT_PATH_KEY_PROD) ;
			$clientPathProd  = stripslashes($clientPathProd);
			$clientPasswordProd =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_PASSWORD_KEY_PROD)  ;
			$clientKeyPasswordProd =  ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_PK_PASSWORD_KEY_PROD)  ;
			$slimpayAliasProd =  ($isFirstInit) ?  '' : $properties->getValue($SLIMPAY_ALIAS_KEY_PROD) ;			
			$slimpayPathProd =  ($isFirstInit) ?  '' :  $properties->getValue($SLIMPAY_PATH_KEY_PROD)  ;
			$slimpayPathProd = stripslashes($slimpayPathProd);
			$slimpayPasswordProd =  ($isFirstInit) ?  '' :  $properties->getValue($SLIMPAY_PASSWORD_KEY_PROD)  ;
			$slimpayCertProd = ($isFirstInit) ?  '' : $properties->getValue($SLIMPAY_CERT_PATH_KEY_PROD) ;
			$returnUrlProd =  ($isFirstInit) ?  '' :  stripslashes($properties->getValue($CLIENT_RETURN_URL_KEY_PROD))  ;
			$notifyUrlProd =  ($isFirstInit) ?  '' :  stripslashes($properties->getValue($CLIENT_NOTIFY_URL_KEY_PROD))  ;
									
			$isCardPayment = ($isFirstInit) ?  '' :  $properties->getValue($CLIENT_CARD_PAYMENT_KEY)  ;
			
			$automatic = ($isFirstInit) ? 'checked' :''; 
			$manual =  ($isFirstInit) ?  '' :  'checked'  ;
			$production = ($isProductionMode == 'true') ? 'checked' : ''; 
			$test = ($isProductionMode == 'true') ? '' : 'checked'; 
			$displayCard = ($isCardPayment == 'true') ? 'checked' : ''; 
			
			?>
			
			<h1><?php if($isFirstInit) echo 'Initialisation'; else echo 'Configuration';?> du Terminal de Pr&eacute;l&egrave;vement Virtuel</h1>			
	
			<div style = "">		
					<?php if(isset($_SESSION['scimResultSuccess'])) echo "<label id ='errorText'>". $_SESSION['scimResultSuccess'] ."</label>";?>	
					<?php if(isset($_SESSION['scimResultFailure'])) echo "<label id ='errorText'><font color='red'>". $_SESSION['scimResultFailure'] ."</font></label>";?>	
			</div>
			<div style = "display:<?php if(! isset($_POST['blob'])) echo ''; else echo 'none';?> ;"  >
			
				<FORM name="mainForm" Method="POST" Action="initExec.php" id="init" onsubmit= "return validateInit();">
					
					<h4>Donn&eacute;es d'initialisation </h4>

					<div>
						<?php 
							 echo '<input type="radio" id="mode" name="mode" value="test" onchange="updateMode();" onclick="updateMode();" onkeypress="updateMode();"';
						 if(isset($_SESSION['mode']) && $_SESSION['mode'] == "test") echo 'checked' ; else echo $test ; echo '> Mode test </input>';
						?>
						<?php 
						echo '<input type="radio" id="mode" name="mode" value="production" onchange="updateMode();" onclick="updateMode();" onkeypress="updateMode();"';
						if(isset($_SESSION['mode']) && $_SESSION['mode'] == "production") echo 'checked' ; else echo $production ; echo '> Mode production </input>';
						?>
					</div>

					<div id="divSiteIdDev">
						<label>Identifiant<noscript> (mode test)</noscript></label>
						<input type="text" id="siteIdDev" name="siteIdDev" value="<?php echo $identifierDev; ?>" disabled="true" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
						<span id ="errorTextSiteIdDev" class="error"><font color="red"> <?php if(isset($_SESSION['errorIdDev'])) echo $_SESSION['errorIdDev'];?></font></span>
					</div>

					<div id="divSiteIdProd">
						<label>Identifiant<noscript> (mode production)</noscript></label>
						<input type="text" id="siteIdProd" name="siteIdProd" value="<?php echo $identifierProd; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
						<span id ="errorTextSiteIdProd" class="error"><font color="red"> <?php if(isset($_SESSION['errorIdProd'])) echo $_SESSION['errorIdProd'];?></font></span>
					</div>

					<div id="data" style = ""> 
						<label id= "labelCode">Code d'activation</label>
						<input type="text" id="code" <?php if ($isProductionMode != 'true')   echo 'disabled="true"'; ?> size=20 name="code" onclick="hideError();" onkeypress="hideError();" onchange="hideError();">
						<label id="errorTextCode"><font color="red"><?php if(isset($_SESSION['errorCode'])) echo $_SESSION['errorCode'];?></font></label>
					</div>

					<div style = "">
						<?php  echo'<input type="checkbox" name="isCardPayment" value="$isCardPayment" id = "isCardPayment" ';
						if(isset($_SESSION['isCardPayment']) && $_SESSION['isCardPayment'] == "isCardPayment") echo 'checked' ; else echo $displayCard ; 
						 echo ' onchange ="updateCard();" onclick ="updateCard();" onkeypress="updateCard();">Premier Paiement par carte bancaire.<br>';
						?>
					</div>

					<div style = "<?php if(($isProductionMode == "true")&&($isCardPayment == 'false')) echo "display: none;"?> " id = "cardData">

						<div style = "">
							<label id="labelTerminalMerchant" >Terminal marchand</label>
							<input type="text" id="terminalMerchant" <?php if ($isProductionMode != 'true') echo 'value="1999888" disabled="false"' ; else echo 'value="" '; ?>  size=20 name="terminalMerchant" onclick="hideError();" onkeypress="hideError();" onchange="hideError();">
							<label id = "errorTextTerminalMerchant" ><font color="red"><?php if(isset($_SESSION['errorTerminalMerchant'])) echo $_SESSION['errorTerminalMerchant'];?></font></label>
						</div>			

						<div style = "">
							<label id="labelTerminalOrder">Rang marchand</label>
							<input type="text" id="terminalOrder" <?php if ($isProductionMode != 'true') echo 'value="99" disabled="false"' ; else echo 'value="" '; ?> size=20 name="terminalOrder"   onclick="hideError();" onkeypress="hideError();" onchange="hideError();">
							<label id = "errorTextTerminalOrder" ><font color="red"><?php if(isset($_SESSION['errorTerminalOrder'])) echo $_SESSION['errorTerminalOrder'];?></font></label>
						</div>					
		
						<div style = "">
							<label id="labelTerminalKey" >Cl&eacute; marchand</label>
							<input type="text" id="terminalKey" <?php if ($isProductionMode != 'true') echo 'value="2" disabled="false"' ; else echo 'value="" '; ?> size=20 name="terminalKey"  onclick="hideError();" onkeypress="hideError();" onchange="hideError();" >
							<label id = "errorTextTerminalKey" ><font color="red"><?php if(isset($_SESSION['errorTerminalKey'])) echo $_SESSION['errorTerminalKey']; ?></font></label>
						</div>	
					</div>	
			
					<h4>Parametres du client</h4>

					<div style = "display:<?php if($isFirstInit) echo ''; else echo 'none';?> ;"  >
		
						<?php echo '<input type="radio" id="config" name="config" value="automatic" onchange="updateAuto();" onclick="updateAuto();" onkeypress="updateAuto();"';
						 if(isset($_SESSION['config']) && $_SESSION['config'] == "automatic") echo 'checked' ; else echo $automatic ;						
							echo '>Configuration automatique ';
						?>
						<?php echo '<input type="radio" id="config" name="config" value="manual" onchange="updateAuto();" onclick="updateAuto();" onkeypress="updateAuto();"';
						 if(isset($_SESSION['config']) && $_SESSION['config'] == "manual") echo 'checked' ; else echo $manual ;						
							 echo '>Configuration manuelle ';
						?>			

					</div>	


					<div id="info">
						
						<div id="divClientPathDev">
							<label>Chemin vers le keystore<noscript> (mode test)</noscript></label>
							<input type="text" id="clientPathDev" name="clientPathDev" value ="<?php  echo $clientPathDev;?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();" />
							<span id ="errorTextClientPathDev" class="error"><font color="red"> <?php if(isset($_SESSION['errorClientPathDev'])) echo $_SESSION['errorClientPathDev'] ;?> </font></span>
						</div>
						
						<div id="divClientPathProd">
							<label>Chemin vers le keystore<noscript> (mode production)</noscript></label>
							<input type="text" id="clientPathProd" name="clientPathProd" value ="<?php  echo $clientPathProd;?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();" />
							<span id ="errorTextClientPathProd" class="error"><font color="red"> <?php if(isset($_SESSION['errorClientPathProd'])) echo $_SESSION['errorClientPathProd'] ;?> </font></span>
						</div>
										
						
						<div id="divClientPasswordDev">
							<label>Mot de passe keystore<noscript> (mode test)</noscript></label>
							<input type="password" id="clientPasswordDev" name="clientPasswordDev" value="<?php  echo $clientPasswordDev;?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
							<span id ="errorTextClientPasswordDev" class="error"><font color="red"> <?php if(isset($_SESSION['errorClientPasswordDev'])) echo $_SESSION['errorClientPasswordDev'] ;?> </font></span>
							
						</div>
						
						<div id="divClientPasswordProd">
							<label>Mot de passe keystore<noscript> (mode production)</noscript></label>
							<input type="password" id="clientPasswordProd" name="clientPasswordProd" value="<?php  echo $clientPasswordProd;?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
							<span id ="errorTextClientPasswordProd" class="error"><font color="red"> <?php if(isset($_SESSION['errorClientPasswordProd'])) echo $_SESSION['errorClientPasswordProd'] ;?> </font></span>
							
						</div>
						
						<div id="divClientKeyPasswordDev">
							<label>Mot de passe cl&eacute; priv&eacute;e<noscript> (mode test)</noscript></label>
							<input type="password" id="clientKeyPasswordDev" name="clientKeyPasswordDev" value="<?php  echo $clientKeyPasswordDev;?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();" />
							<span id ="errorTextClientKeyPasswordDev" class="error"><font color="red"> <?php if(isset($_SESSION['errorClientKeyPasswordDev'])) echo $_SESSION['errorClientKeyPasswordDev'] ;?> </font></span>
						</div>
						
						<div id="divClientKeyPasswordProd">
							<label>Mot de passe cl&eacute; priv&eacute;e<noscript> (mode Production)</noscript></label>
							<input type="password" id="clientKeyPasswordProd" name="clientKeyPasswordProd" value="<?php  echo $clientKeyPasswordProd;?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();" />
							<span id ="errorTextClientKeyPasswordProd" class="error"><font color="red"> <?php if(isset($_SESSION['errorClientKeyPasswordProd'])) echo $_SESSION['errorClientKeyPasswordProd'] ;?> </font></span>
						</div>
						
						<div id="divClientAliasDev">
							<label>Alias<noscript> (mode test)</noscript></label>
							<input type="text" id="clientAliasDev" name="clientAliasDev" value="<?php echo $clientAliasDev; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
							<span id ="errorTextClientAliasDev" class="error"><font color='red'><?php if(isset($_SESSION['errorClientAliasDev'])) echo $_SESSION['errorClientAliasDev'] ;?></font></span>
						</div>
						
						<div id="divClientAliasProd">
							<label>Alias<noscript> (mode production)</noscript></label>
							<input type="text" id="clientAliasProd" name="clientAliasProd" value="<?php echo $clientAliasProd; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
							<span id ="errorTextClientAliasProd" class="error"><font color='red'><?php if(isset($_SESSION['errorClientAliasProd'])) echo $_SESSION['errorClientAliasProd'] ;?></font></span>
						</div>
								
			
					</div>		

					<h4>Adresses d'utilisation</h4>

					<div id = "adr" style = ""> 		
						
						<div id="divReturnUrlDev">
							<label>Adresse de retour<noscript> (mode test)</noscript></label>
							<input type="text" id="returnUrlDev" name="returnUrlDev" value="<?php echo $returnUrlDev; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
							<span id ="errorTextReturnUrlDev" class="error"><?php if(isset($_SESSION['errorReturnUrlDev'])) echo $_SESSION['errorReturnUrlDev'];?></span>
						</div>
						
						<div id="divReturnUrlProd">
							<label>Adresse de retour<noscript> (mode production)</noscript></label>
							<input type="text" id="returnUrlProd" name="returnUrlProd" value="<?php echo $returnUrlProd; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();"/>
							<span id ="errorTextReturnUrlProd" class="error"><?php if(isset($_SESSION['errorReturnUrlProd'])) echo $_SESSION['errorReturnUrlProd'];?></span>
						</div>
						
						<div id="divNotifyUrlDev">
							<label>Addresse de notification<noscript> (mode test)</noscript></label>
							<input type="text" id="notifyUrlDev" name="notifyUrlDev" value="<?php echo $notifyUrlDev; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();" />
							<span id ="errorTextNotifyUrlDev" class="error"><?php if(isset($_SESSION['errorNotifyUrlDev'])) echo $_SESSION['errorNotifyUrlDev'] ;?> </font></span>
						</div>
															
						<div id="divNotifyUrlProd">
							<label>Addresse de notification<noscript> (mode test)</noscript></label>
							<input type="text" id="notifyUrlProd" name="notifyUrlProd" value="<?php echo $notifyUrlProd; ?>" onclick="hideError();" onkeypress="hideError();" onchange="hideError();" />
							<span id ="errorTextNotifyUrlProd" class="error"><?php if(isset($_SESSION['errorNotifyUrlProd'])) echo $_SESSION['errorNotifyUrlProd'] ;?> </font></span>
						</div>
					</div>

					<div><input type=submit value=Envoyer></div>
									 
				</FORM>
			</div>

		</div><!-- end content-->
	
	</div><!-- end center-->

	
<?php 
	include_once "./include/common_php/footer.php";	

	if (isset($_SESSION['scimResultSuccess']))
		unset($_SESSION['scimResultSuccess']);	 
	if (isset($_SESSION['scimResultFailure']))
		unset($_SESSION['scimResultFailure']);	 
	if (isset($_SESSION['mode'])) 	
		unset($_SESSION['mode']);
	if (isset($_SESSION['config']))  	
		unset($_SESSION['config']);
	if (isset($_SESSION['isCardPayment']))  	
		$_SESSION['isCardPayment'];

?>	 
</BODY>
</HTML>
