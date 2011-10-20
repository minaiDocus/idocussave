jQuery(function ($) {
	$("#tab_1_page").css("display","block");
	$("a.tab_lien").click(function(){
		var id='';
    var current='';
		id=jQuery(this).attr("id");
		$(".tabpage").hide();
    current = "#"+id+"_page"
		$(current).show();
    $("a.tab_lien").removeClass("current");
		$(this).addClass("current");
	});
});
