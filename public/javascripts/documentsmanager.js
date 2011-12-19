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
  $("#content").css('height', contentheight +"px");
  $("#content").css('width', windowwidth +"px");
  $("#content .leftcolon").css('height', leftcolonheight +"px");
  $("#content .leftcolon").css('width', leftcolonwidth +"px");
  $("#content .rightcolon").css('height', rightcolonheight +"px");
  $("#content .rightcolon").css('width', rightcolonwidth +"px");
  $("#header .rightcolon").css('width', headerrightcolonwidth +"px");
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
  pagesbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*pane_ratio)-20;
  pagesbrowserwidth = docummentcomposerwidth -10
  documentbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*30);
  documentbrowserwidth = docummentcomposerwidth -10
  compdoccolwidth = (pagesbrowserwidth /100)*60;
  infoscolwidth = (pagesbrowserwidth /100)*40;

  // Widget element resize
  $("#documentcomposer").css('height', docummentcomposerheight +"px");
  $("#documentcomposer").css('width', docummentcomposerwidth +"px");
  $("#documentcomposer .pagesbrowser").css('height', pagesbrowserheight +"px");
  $("#documentcomposer .pagesbrowser").css('width', pagesbrowserwidth +"px");
  $("#documentcomposer .pagesbrowser .pageslist").css('width', pagesbrowserwidth - (margin*2) +"px");
  $("#documentcomposer .documentbrowser").css('height', documentbrowserheight +"px");
  $("#documentcomposer .documentbrowser").css('width', documentbrowserwidth +"px");
  $("#documentcomposer .documentbrowser .doccol").css('width', compdoccolwidth +"px");
  $("#documentcomposer .documentbrowser .doccol").css('height', documentbrowserheight -10 +"px");
  $("#documentcomposer .documentbrowser .infoscol").css('width', infoscolwidth -10 +"px");
  $("#documentcomposer .documentbrowser .infoscol").css('height', documentbrowserheight -10 +"px");
  $("#useraccount").css('height', useraccountheight +"px");
  $("#useraccount").css('width', useraccountwidth +"px");
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
  pagesbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*pane_ratio)-20;
  pagesbrowserwidth = docummentcomposerwidth -10
  documentbrowserheight = (((docummentcomposerheight - actiobarheight)/100)*30);
  documentbrowserwidth = docummentcomposerwidth -10
  compdoccolwidth = (pagesbrowserwidth /100)*60;
  infoscolwidth = (pagesbrowserwidth /100)*40;

  // Widget element resize
  $("#documentcomposer .pagesbrowser").closest(".jScrollPaneContainer").css('height', pagesbrowserheight +"px");
  $("#documentcomposer .pagesbrowser").closest(".jScrollPaneContainer").css('width', pagesbrowserwidth +"px");
  $("#documentcomposer .documentbrowser .infoscol").closest(".jScrollPaneContainer").css('height', documentbrowserheight -10 +"px");
  $("#documentcomposer .documentbrowser .infoscol").closest(".jScrollPaneContainer").css('width', infoscolwidth -10 +"px");
  $("#documentcomposer .documentbrowser .doccol").closest(".jScrollPaneContainer").css('height', documentbrowserheight -10 +"px");
  $("#documentcomposer .documentbrowser .doccol").closest(".jScrollPaneContainer").css('width', compdoccolwidth +"px");
  $("#useraccount").closest(".jScrollPaneContainer").css('height', useraccountheight +"px");
  $("#useraccount").closest(".jScrollPaneContainer").css('width', useraccountwidth +"px");
}



// Custom function
// Resize apply scrollbar
function customscrollbarapplayer() {
  $.extend($.fn.jScrollPane.defaults, {showArrows:true});
  $('#documentcomposer .pagesbrowser').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
  $('#documentcomposer .documentbrowser .infoscol').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
  $('#documentcomposer .documentbrowser .doccol').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
  $("#documentcomposer .documentbrowser .doccol").closest(".jScrollPaneContainer").css('float', "left");
  $("#documentcomposer .documentbrowser .infoscol").closest(".jScrollPaneContainer").css('float', "right");
  
  $('#useraccount').jScrollPane({scrollbarWidth:8, scrollbarMargin:0, showArrows:false});
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



