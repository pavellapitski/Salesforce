
function doIt()
{
try{
  jQuery(function() {
    /*Append the jQuery CSS CDN Link to the Head tag. */
    jQuery('head').append('<link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/themes/start/jquery-ui.css" type="text/css" />');
  
    /*Create the HTML(DIV Tag) for the Dialog.*/
    var html =
      '<div id="dialog" title="Go Home"><p>Do you want to go to the Home tab ?</p></div>';
   
    /*Check if the Dialog(DIV Tag) already exists if not then Append the same to the Body tag.*/
    if(!jQuery('[id=dialog]').size()){
      jQuery('body').append(html);
    }    
      else
      {
        jQuery( "#dialog").empty();  
      }
    /*Open the jQuery Dialog.*/
      jQuery( "#dialog" ).html("<b\> TEST OK </b>");
    jQuery( "#dialog" ).dialog({
      autoOpen: true,
      modal: true,
      show: {
        effect: "bounce",
        duration: 1000
      },
      hide: {
        effect: "bounce",
        duration: 1000
      },
      buttons: {
        "Continue": function() {
          location.replace('/home/home.jsp');
          jQuery( this ).dialog( "close" );
        },
        Cancel: function() {
          jQuery( this ).dialog( "close" );
        }
      }
    });
  });
}
catch(e){
alert('An Error has Occured. Error: ' + e);
}
}