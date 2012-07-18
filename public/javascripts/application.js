// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function submit_login()
{
	document.getElementById('login_redirect_url').value="Consent";
	document.forms["login"].submit();
}
function submit_payment_login()
{
	document.forms["payment_login"].submit();
}
function submit_manage_consent()
{
	document.getElementById('login_redirect_url').value="Manage Consent";
	document.forms["login"].submit();
}
function submit_registration()
{
	document.forms["registration"].submit();
}
function submit_chage_password()
{
	document.forms["reset"].submit();
}
function submit_change_password_consent()
{
	document.forms["reset_password"].submit();
}
function validate_pin()
{
	document.forms["resend_mobile_pin"].submit();
}
function submit_consent_confirmation_accept()
{
	document.getElementById('consent_consent_status').value = "Accept";
	document.forms["consent_confirmation"].submit();
}
function submit_consent_confirmation_decline()
{
	document.getElementById('consent_consent_status').value = "Decline";
	document.forms["consent_confirmation"].submit();
}
function revoke_application()
{
	document.forms["revoke_application"].submit();
}
function issue_current_consent(name)
{
	app_name=document.getElementById('app_'+name).value;
	scope=document.getElementById('scope_'+name).value;
	document.getElementById('consent_application_name').value = app_name;
	document.getElementById('consent_application_scope').value = scope;
	document.forms["consent_application"].submit();
}
function change_in_year(current_year)
{
	year = document.getElementById('content_year').value;
	if(year == "Select Year")
	{
		document.getElementById('content_month').style.display="none";
		document.getElementById('content_day').style.display="none";
	}
	else
	{
		difference = current_year - year;
		if(difference == 13)
		{
			document.getElementById('content_month').style.display="";
			document.getElementById('content_day').style.display="";
		}
		else
		{
			document.getElementById('content_month').style.display="none";
			document.getElementById('content_day').style.display="none";
		}
	}
}
function terms_and_conditions(termsConditionData)
{	
document.getElementById('spinner').style.display = "none"
        content=termsConditionData;
	// open the window
	win3 = window.open("", "Window3", "width=750,height=500,scrollbars=yes");
		
	// write to window
	win3.document.writeln("<Title>AT&T Terms & Conditions</Title><center><img src='/images/att-logo.png' alt='' id='logo' height='43' width='92'></img></center>"+ content +"</br><center><a href='javascript:self.close();'>Close</a></center>");
	win3.document.close();
  win3.focus();
}
function privacypolicy(url) {
	newwindow=window.open(url,"Window5", "width=750,height=500,scrollbars=yes");
	if (window.focus) {newwindow.focus()}
	return false;
}

function showNewUsers()
{
    if(typeof already_loaded == "undefined")
    {
        document.getElementById('spinner').style.display = "block"
	new Ajax.Request('/user/new_user/', {method: 'get'});        
	already_loaded = true;
    }
    else
    {
        hideExistingUsers();
    }
}
function termsnconditions()
{
document.getElementById('spinner').style.display = "block"
		new Ajax.Request('/termsnconditions', {method: 'get'});        

}
function submit_off_net_wireless()
{
	 if(document.getElementById('login_no_of_tries').value == "0")
	{
	 document.forms["off_net_consent_wireless"].submit();
	}
	document.getElementById('login_no_of_tries').value = "1";
}
function submit_off_net_aoc_wireless()
{
	if(document.getElementById('login_no_of_tries').value == "0")
  {
	 document.forms["off_net_aoc_consent_wireless"].submit();
	}
	document.getElementById('login_no_of_tries').value = "1";
}
function submit_on_net_wireless()
{
//	document.forms["on_net_consent_wireless"].submit();
login_app_name = document.getElementById('login_app_name').value;
login_dev_name = document.getElementById('login_dev_name').value;
login_app_scope = document.getElementById('login_app_scope').value;
new Ajax.Request('verify_onpin', {method: 'get'});        
new Ajax.Request('on_net_consent_wireless', {method: 'get', parameters: {app_name: login_app_name, dev_name: login_dev_name, app_scope: login_app_scope}});        
}
function on_net_manage_consent()
{
//	document.forms["on_net_consent_wireless"].submit();
new Ajax.Request('mc_verify_onpin', {method: 'get'});        
new Ajax.Request('on_net_manage_consent', {method: 'get'});        
}
function submit_on_net_aoc_wireless()
{
//	document.forms["on_net_consent_wireless"].submit();
	session_id = document.getElementById('login_session_id').value;
	login_app_name = document.getElementById('login_app_name').value;
	login_dev_name = document.getElementById('login_dev_name').value;
	login_app_scope = document.getElementById('login_app_scope').value;
	login_organization = document.getElementById('login_organization').value;
	login_charge = document.getElementById('login_charge').value;
new Ajax.Request('verify_onpin', {method: 'get', parameters: {login_session_id: session_id}});        
new Ajax.Request('on_network', {method: 'get', parameters: {app_name: login_app_name, dev_name: login_dev_name, app_scope: login_app_scope, organization: login_organization, charge: login_charge}});        
}
function off_net_send_pin()
{
		document.forms["off_net_send_pin"].submit();
}
function off_net_aoc_send_pin()
{
		document.forms["off_net_aoc_send_pin"].submit();
}
function submit_consent_decline()
{
	document.getElementById('login_redirect_url').value="Consent Decline";
	document.forms["login"].submit();
}
function off_net_mc_verify_pin()
{
	if(document.getElementById('manage_consent_no_of_tries').value == "0")
	{
	 document.forms['off_net_mc_verify_pin'].submit();
	}
	document.getElementById('manage_consent_no_of_tries').value = "1";
}
function mc_off_net_send_pin()
{
	document.forms['mc_off_net_send_pin'].submit();
}
function addBookmark()
{
	var c= document.getElementById('bookurl').value
	bookmarkurl =c;
	bookmarktitle="Manage Consent | AT&T";
	if (document.all)
		window.external.AddFavorite(bookmarkurl,bookmarktitle)
	else if ( window.sidebar ) {
		window.sidebar.addPanel(bookmarktitle, bookmarkurl,"");
	}
}
function checkIt(evt) {
    evt = (evt) ? evt : window.event
    var charCode = (evt.which) ? evt.which : evt.keyCode
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
        return false
    }
    return true
}
function favicon_headers()
{
	link_favi=document.createElement('link');
	link_favi.href='/images/favicon.ico';
	link_favi.rel='shortcut icon';
	link_favi.type = 'image/x-icon';
	document.getElementsByTagName('head')[0].appendChild(link_favi);

	link114=document.createElement('link');
	link114.href='/images/Consent_Icon_114x114.png';
	link114.rel='apple-touch-icon-precomposed';
	link114.sizes='114x114';
	document.getElementsByTagName('head')[0].appendChild(link114);

	link72=document.createElement('link');
	link72.href='/images/Consent_Icon_72x72.png';
	link72.rel='apple-touch-icon-precomposed';
	link72.sizes='72x72';
	document.getElementsByTagName('head')[0].appendChild(link72);

	link57=document.createElement('link');
	link57.href='/images/Consent_Icon_57x57';
	link57.rel='apple-touch-icon-precomposed';
	document.getElementsByTagName('head')[0].appendChild(link57);

	link_touch=document.createElement('link');
	link_touch.href='/images/apple-touch-icon.png';
	link_touch.rel='apple-touch-icon';
	document.getElementsByTagName('head')[0].appendChild(link_touch);
}
function limitText(limitField, limitCount, limitNum) {
	if (limitField.value.length > limitNum) {
		limitField.value = limitField.value.substring(0, limitNum);
	} else {
		limitCount.value = limitNum - limitField.value.length;
	}
}

function checkCookiesEnabledOrNotAndDisplayErrorMessage(errorLabelId) {
   if(navigator.cookieEnabled){
   }
   else{
       document.getElementById(errorLabelId).innerHTML="Cookies must be enabled to use this service.";
   }
}