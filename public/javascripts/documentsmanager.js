// Custom function
// Resize layout structure
function layoutresizer() {
  var margin;
  var windowheight;
  var windowwidth;
  var contentwidth;
  var contentheight;
  var leftcolonwidth;
  var leftcolonheight;
  var headerheight;
  var rightcolonwidth;
  var rightcolonheight;
  var headerleftcolonwidth;
  var headerrightcolonwidth;

  // Set default values
  margin = 20;
  headerheight = 60;
  leftcolonwidth= 0;
  headerleftcolonwidth = 260;

  // Get the window size
  windowheight = document.body.clientHeight;
  windowwidth = document.body.clientWidth;

  // Calculated values
  contentheight = windowheight - headerheight;
  rightcolonwidth = windowwidth - leftcolonwidth;
  leftcolonheight = windowheight - headerheight;
  rightcolonheight = windowheight - headerheight;
  headerrightcolonwidth = windowwidth - headerleftcolonwidth;

  // Content element resize
  // $("#content").css('height', contentheight +"px");
  $("#content").css('width', windowwidth +"px");
  $("#content .leftcolon").css('height', leftcolonheight +"px");
  $("#content .leftcolon").css('width', leftcolonwidth +"px");
  $("#content .rightcolon").css('height', rightcolonheight +"px");
  
  if (rightcolonwidth >= 660) {
    $("#content .rightcolon").css('width', rightcolonwidth +"px");
  } else {
    $("#content .rightcolon").css('width', "660px");
  }
  
  if (headerrightcolonwidth >= 400) {
    $("#header .rightcolon").css('width', headerrightcolonwidth +"px");
    $("#header").css('width', headerleftcolonwidth + headerrightcolonwidth +"px");
  } else {
    $("#header .rightcolon").css('width', "400px");
    $("#header").css('width', "660px");
  }
}



// Custom function
// Resize document manager structure
function documentmanagerresizer() {
  var margin;
  var windowheight;
  var windowwidth;
  var headerheight;
  var leftcolonwidth;
  var docummentcomposerheight;
  var useraccountheight;
  var useraccountwidth;
  var userbackupheight;
  var userbackupwidth;
  var userreportingheight;
  var userreportingwidth;
  var pagesbrowserheight;
  var pagesbrowserwidth;
  var actiobarheight;
  var pane_ratio;

  // Set default values
  minimun_width = 660;
  margin = 1;
  headerheight = 60;
  leftcolonwidth= 0;
  actiobarheight= 42 ;
  //pane_ratio = $('.documentbrowser').size() > 0 ? 70 : 100;
  pane_ratio = 100;

  // Get the window size
  windowheight = document.body.clientHeight;
  windowwidth = document.body.clientWidth;

  // Calculated values
  docummentcomposerheight = windowheight - headerheight;
  docummentcomposerwidth = windowwidth - leftcolonwidth;
  useraccountheight = windowheight - headerheight - 5;
  useraccountwidth = windowwidth - leftcolonwidth - 10;
  userbackupheight = windowheight - headerheight - 5;
  userbackupwidth = windowwidth - leftcolonwidth - 10;
  userreportingheight = windowheight - headerheight - 5; 
  userreportingwidth =  windowwidth - leftcolonwidth - 10;
  pagesbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*pane_ratio)-20;
  pagesbrowserwidth = docummentcomposerwidth -10
  documentbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*30);
  documentbrowserwidth = docummentcomposerwidth -10

  // Widget element resize
  $("#documentcomposer").css('height', docummentcomposerheight +"px");
  if (docummentcomposerwidth >= minimun_width)
    $("#documentcomposer").css('width', docummentcomposerwidth +"px");
  else
    $("#documentcomposer").css('width', minimun_width +"px");

  $("#documentcomposer .pagesbrowser").css('height', pagesbrowserheight +"px");
  if (pagesbrowserwidth >= minimun_width)
    $("#documentcomposer .pagesbrowser").css('width', pagesbrowserwidth - margin +"px");
  else
    $("#documentcomposer .pagesbrowser").css('width', minimun_width - margin +"px");
  
  if ((pagesbrowserwidth - (margin*2)) >= minimun_width) {
    $("#documentcomposer .pagesbrowser .pageslist").css('width', pagesbrowserwidth - margin +"px");
    $("#documentcomposer .pagesbrowser .documentslist").css('width', pagesbrowserwidth - margin +"px");
  } else {
    $("#documentcomposer .pagesbrowser .pageslist").css('width', minimun_width - margin +"px");
    $("#documentcomposer .pagesbrowser .documentslist").css('width', minimun_width - margin +"px");
  }
  
  $("#useraccount").css('height', useraccountheight +"px");
  $("#useraccount").css('width', useraccountwidth +"px");
  $("#userbackup").css('height', userbackupheight +"px");
  $("#userbackup").css('width', userbackupwidth +"px");
  $("#userreporting").css('height', userreportingheight +"px");
  $("#userreporting").css('width', userreportingwidth +"px");
}



// Custom function
// Resize scrolpane container structure
function scrollpaneresizer() {
  var margin;
  var windowheight;
  var windowwidth;
  var headerheight;
  var leftcolonwidth;
  var docummentcomposerheight;
  var useraccountheight;
  var useraccountwidth;
  var userbackupheight;
  var userbackupwidth;
  var userreportingheight;
  var userreportingwidth;
  var pagesbrowserheight;
  var pagesbrowserwidth;
  var actiobarheight;
  var pane_ratio;

  // Set default values
  margin = 20;
  headerheight = 60;
  leftcolonwidth= 0;
  actiobarheight= 42 ;
  //pane_ratio = $('.documentbrowser').size() > 0 ? 70 : 100;
  pane_ratio = 100;

  // Get the window size
  windowheight = document.body.clientHeight;
  windowwidth = document.body.clientWidth;

  // Calculated values
  docummentcomposerheight = windowheight - headerheight;
  docummentcomposerwidth = windowwidth - leftcolonwidth;
  useraccountheight = windowheight - headerheight - 5;
  useraccountwidth = windowwidth - leftcolonwidth - 10;
  userbackupheight = windowheight - headerheight - 5;
  userbackupwidth = windowwidth - leftcolonwidth - 10;
  userreportingheight = windowheight - headerheight - 5; 
  userreportingwidth =  windowwidth - leftcolonwidth - 10;
  pagesbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*pane_ratio)-20;
  pagesbrowserwidth = docummentcomposerwidth -10
  documentbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*30);
  documentbrowserwidth = docummentcomposerwidth -10

  // Widget element resize
  // $("#documentcomposer .pagesbrowser .jspContainer").css('height', pagesbrowserheight +"px");
  // $("#documentcomposer .pagesbrowser .jspContainer").css('width', pagesbrowserwidth +"px");
  // $("#documentcomposer .pagesbrowser .jspContainer .jspPane").css('height', pagesbrowserheight +"px");
  // $("#documentcomposer .pagesbrowser .jspContainer .jspPane").css('width', pagesbrowserwidth +"px");
  $("#useraccount").closest(".jScrollPaneContainer").css('height', useraccountheight +"px");
  $("#useraccount").closest(".jScrollPaneContainer").css('width', useraccountwidth +"px");
  $("#userbackup").closest(".jScrollPaneContainer").css('height', userbackupheight +"px");
  $("#userbackup").closest(".jScrollPaneContainer").css('width', userbackupwidth +"px");
  $("#userreporting").closest(".jScrollPaneContainer").css('height', userreportingheight +"px");
  $("#userreporting").closest(".jScrollPaneContainer").css('width', userreportingwidth +"px");
}



// Custom function
// Resize apply scrollbar
function customscrollbarapplayer() {
  $.extend($.fn.jScrollPane.defaults, {showArrows:true});
  // $(".application").jScrollPane({scrollbarMargin:0, showArrows:false});
  $("#documentcomposer").jScrollPane({scrollbarMargin:0, showArrows:false});
  
  $('#useraccount').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
  $('#userbackup').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
  $('#userreporting').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
}



// Call functions on document ready
$(document).ready(function () {
  layoutresizer();
  documentmanagerresizer();
  scrollpaneresizer();
  customscrollbarapplayer();

  // View sources code for more information http://www.wil-linssen.com/demo/jquery-sortable-ajax/

  // Call functions on document resize
  $(window).resize(function() {
    layoutresizer();
    documentmanagerresizer();
    scrollpaneresizer();
    customscrollbarapplayer();
  });
});



