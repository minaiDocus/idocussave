function load(){
	displayActivationCode();
	displayKeyStoreInfos();
}


function getModeValue() {
	var radio = document.forms['mainForm'].elements['mode'];
	for (var i=0; i<radio.length; i++) {
		if (radio[i].checked) {	
			return radio[i].value;
		}
	}	                            		
}

function getElementType(element) {
	var radio = document.forms['mainForm'].elements[element];
	for (var i=0; i<radio.length; i++) {
		if (radio[i].checked) {
			return radio[i].value;
		}
	}	                            		
}

function updateCorporateDetails() {
	
	var clientType = getElementType('clientType');
	
	if (clientType == "corporate"){
		document.getElementById('corporateDetails').style.display = '';
		document.getElementById('companyName').disabled = false;
		document.getElementById('organizationId').disabled = false;
	}
	else {
		document.getElementById('corporateDetails').style.display = 'none';
		document.getElementById('companyName').disabled = true;
		document.getElementById('organizationId').disabled = true;	
	}
	
}

function updateDebitDetails() {
	
	var requestType = getElementType('requestType');
	
	if (requestType == "collectPayment"){
		document.getElementById('debit').style.display = '';
		document.getElementById('amount').disabled = '';
		document.getElementById('executionDate').disabled = '';
	}
	else {
		document.getElementById('debit').style.display = 'none';
		document.getElementById('amount').disabled = 'true';
		document.getElementById('executionDate').disabled = 'true';	
	}
	
}
	
function getConfigValue() {
	var radio = document.forms['init'].elements['config'];
	for (var i=0; i<radio.length; i++) {
		if (radio[i].checked) {
			return radio[i].value;
		}
	}
}


function validateTransaction() {
	
	var result =true;
	var focusId = ''; 
	if(document.getElementById('firstName').value==''){
		document.getElementById('errorTextFirstName').innerHTML = 'Ce champ est requis. ';
		if( focusId == '') {
			focusId = 'firstName'; 
		}
		result= false;
	}
			
	if(document.getElementById('lastName').value==''){
		document.getElementById('errorTextLastName').innerHTML = 'Ce champ est requis. ';
		if( focusId == '') {
			focusId = 'lastName'; 
		}
		result= false;
	}

	if(document.getElementById('clientReference').value==''){
		document.getElementById('errorTextClientReference').innerHTML = 'Ce champ est requis. ';
		if( focusId == '') {
			focusId = 'clientReference'; 
		}
		result= false;
	}	

	if(document.getElementById('line1Inv').value==''){
		document.getElementById('errorTextLine1Inv').innerHTML = 'Ce champ est requis. ';
		if( focusId == '') {
			focusId = 'line1Inv'; 
		}
		result= false;
	}

	if(document.getElementById('cityInv').value==''){
		document.getElementById('errorTextCityInv').innerHTML = 'Ce champ est requis. ';
		if( focusId == '') {
			focusId = 'cityInv'; 
		}
		result= false;
	}		

	if(document.getElementById('postalCodeInv').value==''){
		document.getElementById('errorTextPostalCodeInv').innerHTML = 'Ce champ est requis. ';
		if( focusId == '') {
			focusId = 'postalCodeInv'; 
		}
		result= false;
	}	

	if((document.getElementById('cardAmount') != null)){
		if(document.getElementById('cardAmount').value==''){
			document.getElementById('errorTextCardAmount').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'cardAmount'; 
			}
			result= false;
		}
	}
				
	if (result == false) {
		document.getElementById(focusId).focus();	
	}

	return result;
}
	

