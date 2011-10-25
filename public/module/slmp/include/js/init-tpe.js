function getRandomId() {
	return Math.round(Math.random()*10000000);
}

function load(){
	storeDefaultValues();
	updateMode();
	updateCard();
	updateAuto();
}

var testTerminalMerchant = '';
var testTerminalOrder = '';
var testTerminalKey = '';
var prodTerminalMerchant = '';
var prodTerminalOrder = '';
var prodTerminalKey = '';
var previousMode;

function storeDefaultValues() {
	if (document.getElementById('siteIdDev') == null) {
		return;
	}
	
	if (document.getElementById('siteIdDev').value == "") {
		document.getElementById('siteIdDev').value = getRandomId();
	}
	previousMode = getModeValue();
	if (previousMode=="test") {
		if (document.getElementById('terminalMerchant').value == "") {
			document.getElementById('terminalMerchant').value = "1999888";
		}
		if (document.getElementById('terminalOrder').value == "") {
			document.getElementById('terminalOrder').value = "99";
		}
		if (document.getElementById('terminalKey').value == "") {
			document.getElementById('terminalKey').value = "2";
		}
	}
}

function getModeValue() {
	if (typeof document.forms['mainForm'] == 'undefined') {
		return "";
	}
	
	var radio = document.forms['mainForm'].elements['mode'];
	for (var i=0; i<radio.length; i++) {
		if (radio[i].checked) {	
			return radio[i].value;
		}
	}	                            		
}
	
function updateMode(){
	var mode = getModeValue();
	if (mode=="test") {
		document.getElementById('data').style.display='none';	
		if (previousMode == "production") {
			prodTerminalMerchant = document.getElementById('terminalMerchant').value;
			prodTerminalOrder = document.getElementById('terminalOrder').value;
			prodTerminalKey = document.getElementById('terminalKey').value;
			document.getElementById('terminalMerchant').value = testTerminalMerchant;
			document.getElementById('terminalOrder').value = testTerminalOrder;
			document.getElementById('terminalKey').value = testTerminalKey;
		}
		document.getElementById('code').disabled=true; 
		document.getElementById('terminalMerchant').disabled=true; 
		document.getElementById('terminalOrder').disabled=true; 
		document.getElementById('terminalKey').disabled=true; 
		document.getElementById('divClientPathProd').style.display='none';
		document.getElementById('divClientPasswordProd').style.display='none';
		document.getElementById('divClientKeyPasswordProd').style.display='none';
		document.getElementById('divClientAliasProd').style.display='none';
		document.getElementById('divReturnUrlProd').style.display='none';
		document.getElementById('divNotifyUrlProd').style.display='none';
		document.getElementById('divSiteIdProd').style.display='none';
		document.getElementById('divClientPathDev').style.display='';
		document.getElementById('divClientPasswordDev').style.display='';
		document.getElementById('divClientKeyPasswordDev').style.display='';
		document.getElementById('divClientAliasDev').style.display='';
		document.getElementById('divReturnUrlDev').style.display='';
		document.getElementById('divNotifyUrlDev').style.display='';
		document.getElementById('divSiteIdDev').style.display='';
		
		if (document.getElementById('terminalMerchant').value == "") {
			document.getElementById('terminalMerchant').value = "1999888";
		}
		if (document.getElementById('terminalOrder').value == "") {
			document.getElementById('terminalOrder').value = "99";
		}
		if (document.getElementById('terminalKey').value == "") {
			document.getElementById('terminalKey').value = "2";
		}
	}
	else if (mode=="production") {
		document.getElementById('data').style.display='';
		document.getElementById('code').disabled=false; 
		document.getElementById('terminalMerchant').disabled=false; 
		document.getElementById('terminalOrder').disabled=false; 
		document.getElementById('terminalKey').disabled=false; 
		if (previousMode == "test") {
			testTerminalMerchant = document.getElementById('terminalMerchant').value;
			testTerminalOrder = document.getElementById('terminalOrder').value;
			testTerminalKey = document.getElementById('terminalKey').value;
			document.getElementById('terminalMerchant').value = prodTerminalMerchant;
			document.getElementById('terminalOrder').value = prodTerminalOrder;
			document.getElementById('terminalKey').value = prodTerminalKey;
		}
		document.getElementById('divClientPathDev').style.display='none';
		document.getElementById('divClientPasswordDev').style.display='none';
		document.getElementById('divClientKeyPasswordDev').style.display='none';
		document.getElementById('divClientAliasDev').style.display='none';
		document.getElementById('divReturnUrlDev').style.display='none';
		document.getElementById('divNotifyUrlDev').style.display='none';
		document.getElementById('divSiteIdDev').style.display='none';
		document.getElementById('divClientPathProd').style.display='';
		document.getElementById('divClientPasswordProd').style.display='';
		document.getElementById('divClientKeyPasswordProd').style.display='';
		document.getElementById('divClientAliasProd').style.display='';
		document.getElementById('divReturnUrlProd').style.display='';
		document.getElementById('divNotifyUrlProd').style.display='';
		document.getElementById('divSiteIdProd').style.display='';
	}
	previousMode = mode;
}

function updateCard(){
	if (typeof document.getElementById('isCardPayment') == 'undefined' || document.getElementById('isCardPayment') == null) {
		return;
	}
	
	if (document.getElementById('isCardPayment').checked) {
		document.getElementById('cardData').style.display=''; 
	} else {
		document.getElementById('cardData').style.display='none'; 
	}
		
}

		

function updateAuto(){
		
	var value = getConfigValue();
	if (value=="automatic") {
		document.getElementById('info').style.display='none'; 
	}
	else if(value=="manual") {
		document.getElementById('info').style.display='';
	}
}
	
function getConfigValue() {
	if (typeof document.forms['mainForm'] == 'undefined') {
		return "";
	}
	
	var radio = document.forms['mainForm'].elements['config'];
	for (var i=0; i<radio.length; i++) {
		if (radio[i].checked) {
			return radio[i].value;
		}
	}
}
	

	 	
function validateInit()	{
	
	var value = getConfigValue();
	var mode = getModeValue();
	var result = true;
	var focusId = '';
					
	if(value=="manual") {
	
		if (mode=="test") {
			if(document.getElementById('clientPathDev').value==''){
				document.getElementById('errorTextClientPathDev').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientPathDev'; 
				}
				result = false;
			}
			if(document.getElementById('clientPasswordDev').value==''){
				document.getElementById('errorTextClientPasswordDev').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientPasswordDev'; 
				}
				result = false;
			}
			if(document.getElementById('clientKeyPasswordDev').value==''){
				document.getElementById('errorTextClientKeyPasswordDev').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientKeyPasswordDev'; 
				}
				result = false;
			}
			if(document.getElementById('clientAliasDev').value==''){
				document.getElementById('errorTextClientAliasDev').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientAliasDev'; 
				}
				result = false;
			}
		}
		if (mode=="production") {
			if(document.getElementById('clientPathProd').value==''){
				document.getElementById('errorTextClientPathProd').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientPathProd'; 
				}
				result = false;
			}
			if(document.getElementById('clientPasswordProd').value==''){
				document.getElementById('errorTextClientPasswordProd').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientPasswordProd'; 
				}
				result = false;
			}
			if(document.getElementById('clientKeyPasswordProd').value==''){
				document.getElementById('errorTextClientKeyPasswordProd').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientKeyPasswordProd'; 
				}
				result = false;
			}
			if(document.getElementById('clientAliasProd').value==''){
				document.getElementById('errorTextClientAliasProd').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'clientAliasProd'; 
				}
				result = false;
			}
		}
	}
	if (mode=="test") {
		if(document.getElementById('returnUrlDev').value==''){
			document.getElementById('errorTextReturnUrlDev').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'returnUrlDev'; 
			}
			result = false;
		}
		if(document.getElementById('notifyUrlDev').value==''){
			document.getElementById('errorTextNotifyUrlDev').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'notifyUrlDev'; 
			}
			result = false;
		}
		if(document.getElementById('siteIdDev').value==''){
			document.getElementById('errorTextSiteIdDev').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'siteIdDev'; 
			}
			result = false;
		}
	}
	if (mode=="production") {
		if(document.getElementById('returnUrlProd').value==''){
			document.getElementById('errorTextReturnUrlProd').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'returnUrlProd'; 
			}
			result = false;
		}
		if(document.getElementById('notifyUrlProd').value==''){
			document.getElementById('errorTextNotifyUrlProd').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'notifyUrlProd'; 
			}
			result = false;
		}
		if(document.getElementById('siteIdProd').value==''){
			document.getElementById('errorTextSiteIdProd').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'siteIdProd'; 
			}
			result = false;
		}
	}
			
	if (mode=="test") {
		document.getElementById('data').style.display='none'; 
	}
	if(mode=="production") {     		
		if(document.getElementById('code').value==''){
			document.getElementById('errorTextCode').innerHTML = 'Ce champ est requis. ';
			if( focusId == '') {
				focusId = 'code'; 
			}
			result = false;
		}
		if(document.getElementById('isCardPayment').checked ){
			if(document.getElementById('terminalMerchant').value==''){
				document.getElementById('errorTextTerminalMerchant').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'terminalMerchant'; 
				}
				result = false;
			}
			if(document.getElementById('terminalOrder').value==''){
				document.getElementById('errorTextTerminalOrder').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'terminalOrder'; 
				}
				result = false;
			}
			if(document.getElementById('terminalKey').value==''){
				document.getElementById('errorTextTerminalKey').innerHTML = 'Ce champ est requis. ';
				if( focusId == '') {
					focusId = 'terminalKey'; 
				}
				result = false;
			}
		}
	}
	if(result == false){
		document.getElementById(focusId).focus();
	}
	else {
		document.getElementById('siteIdDev').disabled=false ;
		document.getElementById('terminalMerchant').disabled=false; 
		document.getElementById('terminalOrder').disabled=false; 
		document.getElementById('terminalKey').disabled=false;
	}
	return result;
}
			
function hideError()
{
	document.getElementById('errorTextClientPathDev').innerHTML = '';
	document.getElementById('errorTextClientPathProd').innerHTML = '';
	document.getElementById('errorTextClientPasswordDev').innerHTML = '';
	document.getElementById('errorTextClientPasswordProd').innerHTML = '';
	document.getElementById('errorTextClientKeyPasswordDev').innerHTML = '';
	document.getElementById('errorTextClientKeyPasswordProd').innerHTML = '';
	document.getElementById('errorTextClientAliasDev').innerHTML = '';
	document.getElementById('errorTextClientAliasProd').innerHTML = '';
	document.getElementById('errorTextReturnUrlDev').innerHTML = '';
	document.getElementById('errorTextReturnUrlProd').innerHTML = '';
	document.getElementById('errorTextNotifyUrlDev').innerHTML = '';
	document.getElementById('errorTextNotifyUrlProd').innerHTML = '';
	document.getElementById('errorTextSiteIdDev').innerHTML = '';
	document.getElementById('errorTextSiteIdProd').innerHTML = '';
	document.getElementById('errorTextCode').innerHTML = '';
	document.getElementById('errorTextTerminalMerchant').innerHTML = '';
	document.getElementById('errorTextTerminalOrder').innerHTML = '';
	document.getElementById('errorTextTerminalKey').innerHTML = '';
	
}

