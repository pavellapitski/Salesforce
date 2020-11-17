

function helloWorld() {
var csslink = "https://code.jquery.com/ui/1.10.4/themes/redmond/jquery-ui.css";
var newStyleSheet = document.createElement('link');
newStyleSheet.rel='stylesheet';
newStyleSheet.type='text/css';
newStyleSheet.href=csslink;
document.getElementsByTagName("head")[0].appendChild(newStyleSheet);
    var j$ = jQuery.noConflict();
var j$modalDialog = j$('<div></div>')
     .html('<div></div>')
     .dialog({
          autoOpen: false,
          title: 'My Modal Dialog',
          resizable: false,
          width: 400,
          height: 400,
          autoResize: true,
          modal: true,
          draggable: true
      });
j$(document).ready(function(){
    j$modalDialog.dialog('open');
});
}