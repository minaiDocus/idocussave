function remove_fields(link) {
    if(confirm("Êtes-vous sûr ?")){
        $(link).next("input[type=hidden]").val("true");
        $(link).parent().hide();
    }
}

function add_fields(link, association, content) {
    var count = parseInt($(link).next("input[name="+association+"_count]").val()) + 1;
    $(link).next("input[name="+association+"_count]").val(count);
    var regexp = new RegExp(association+"_attributes\]\[[0-9]*","g");
    var regexp2 = new RegExp(association+"_attributes_[0-9]*","g");
    var result = content.replace(regexp,association+"_attributes]["+count);
    result = result.replace(regexp2,association+"_attributes_"+count);
    $(link).before(result);
}
