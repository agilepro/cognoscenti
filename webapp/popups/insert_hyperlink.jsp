<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <title>Create or Modify Link</title>

<script type="text/javascript" src="<%=request.getContextPath()%>/jscript/wysiwyg-popup.js"></script>
<script type="text/javascript" src="<%=request.getContextPath()%>/jscript/nugen_utils.js"></script>
<link href="<%=request.getContextPath()%>/css/body.css" rel="styleSheet" type="text/css" media="screen" />
<link href="<%=request.getContextPath()%>/css/popupstyles.css" rel="styleSheet" type="text/css" media="screen" />
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/autocomplete.css" media="screen" type="text/css">
<script type="text/javascript" src="<%=request.getContextPath()%>/jscript/autocomplete.js"></script>

<script type="text/javascript">
var count_hyperlink = 0;
function autoCompleteForProjects(e,obj){
    autoAssignTextBox= obj.id;
    multipleAllowed = false;
    var book_key = window.opener.document.getElementById("book_key").value;
    actionVal = "<%=request.getContextPath()%>/t/getProjects.ajax?book="+book_key;
    if(count_hyperlink == 0){
        doCompletion(e);
        count_hyperlink++;
    }
}

/* ---------------------------------------------------------------------- *\
  Function    : insertHyperLink() (changed)
  Description : Insert the link into the iframe html area
\* ---------------------------------------------------------------------- */
function insertHyperLink() {
  var n = WYSIWYG_Popup.getParam('wysiwyg');

  // get values from form fields
  var href = document.getElementById('linkUrl').value;
  var name = document.getElementById('linkName').value;

    // insert link
  WYSIWYG.insertLink(href,name, n);
  window.close();
}


  function insertInternalLink() {
      var n = WYSIWYG_Popup.getParam('wysiwyg');

      // get values from form fields
      var href = document.getElementById('project').value;
      var name = document.getElementById('linkName').value;

      // insert link
      WYSIWYG.insertLink(href,name, n);
      window.close();
  }
/* ---------------------------------------------------------------------- *\
  Function    : loadLink() (new)
  Description : Load the link attributes to the form
\* ---------------------------------------------------------------------- */
function loadLink() {
  // get params
  var n = WYSIWYG_Popup.getParam('wysiwyg');

  // get selection and range
  var sel = WYSIWYG.getSelection(n);
  var range = WYSIWYG.getRange(sel);
  var lin = null;
  if(WYSIWYG_Core.isMSIE) {
    if(sel.type == "Control" && range.length == 1) {
      range = WYSIWYG.getTextRange(range(0));
      range.select();
    }
    if (sel.type == 'Text' || sel.type == 'None') {
      sel = WYSIWYG.getSelection(n);
      range = WYSIWYG.getRange(sel);
      // find a as parent element
      lin = WYSIWYG.findParent("a", range);
    }
  }
  else {
    // find a as parent element
    lin = WYSIWYG.findParent("a", range);
  }

  // if no link as parent found exit here
  if(lin == null) return;

  // set form elements with attribute values
  for(var i=0; i<lin.attributes.length; i++) {
    var attr = lin.attributes[i].name.toLowerCase();
    var value = lin.attributes[i].value;
    if(attr && value && value != "null") {
      switch (attr) {
        case "href":
          // strip off urls on IE
          /*
          if(WYSIWYG_Core.isMSIE){
            value = WYSIWYG.stripURLPath(n, value, false);
          }
          */
          if(value.indexOf('http')!=-1){
            document.getElementById('linkUrl').value = value;
          }
          else{
            document.getElementById('project').value = value;
          }
        break;
        case "name":
          document.getElementById('linkName').value = value;
        break;

      }
    }
  }

  // Getting style attribute of the link separately, because IE interprets the
  // style attribute is an complex object, and do not return a text stylesheet like Mozilla.

}


/* ---------------------------------------------------------------------- *\
  Function    : selectItem()
  Description : Select an item of an select box element by value.
\* ---------------------------------------------------------------------- */
function selectItemByValue(element, value) {
  if(element.options.length) {
    for(var i=0;i<element.options.length;i++) {
      if(element.options[i].value == value) {
        element.options[i].selected = true;
        return;
      }
    }
    element.options[(element.options.length-1)].selected = true;
  }
}

</script>
</head>
<body onLoad="loadLink();">

<!-- Content Area Starts Here -->
<div class="generalArea">
    <div class="generalSettings">
        <div class="generalHeading">Create a Hyperlink</div>
            <table border="0px solid red" class="popups" width="100%">
                <tr><td style="height:5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">URL:</td>
                    <td style="width:20px;"></td>
                    <td><input type="text" size="30" name="linkUrl" id="linkUrl" value="http://" class="inputGeneral"></td>
                </tr>
                <tr><td style="height:5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit" class="inputBtn" value="Submit External Link" onClick="insertHyperLink();">
                        <input type="submit" class="inputBtn" value="Cancel" onClick="window.close();">
                    </td>
                </tr>
            </table>
            <div style="height:40px">&nbsp;</div>
            <div class="generalHeading">Add link to an existing Project</div>
            <table>
                <tr><td style="height:5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Existing Project Name:</td>
                    <td style="width:20px;"></td>
                    <td>
                    <input type="text" class="wickEnabled" name="project" id="project" size="30" tabindex=2 value='' autocomplete="off" onkeyup="autoCompleteForProjects(event,this);" onfocus="initsmartInputWindowVlaue('smartInputFloater','smartInputFloaterContent');"/>
                    <div style="position:relative;text-align:left">
                            <table  class="floater" style="position:absolute;top:0;left:0;background-color:#cecece;display:none;visibility:hidden"  id="smartInputFloater"  rules="none" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td id="smartInputFloaterContent"  nowrap="nowrap" width="100%"></td>
                                </tr>
                            </table>
                        </div>
                    </td>
                </tr>
                <tr><td style="height:5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit"  class="inputBtn" value="Link Existing Project" onClick="insertInternalLink();"  >
                        <input type="submit" class="inputBtn" value="Cancel" onClick="window.close();">
                    </td>
                </tr>
            </table>
        <input type="hidden" name="linkName" id="linkName" value="" style="font-size: 10px;">
    </div>
</div>

</body>
</html>
