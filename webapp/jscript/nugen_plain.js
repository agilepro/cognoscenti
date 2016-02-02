   function openWin(url){
       window.open(url);
       return false;
   }


function validate(){
    var projectName =  document.getElementById("projectname");
    if(flag && !projectName.value=='' || !projectName.value==null){
        return true;
    }
    return false;
}


<!-- menu moved -->


        String.prototype.startsWith = function(str) {
          return (this.match("^"+str)==str);
        };


        var htmlTagsArray =new Array('<p','<pre','<a','<br','<h1','<h2','<h3','</p>','</pre>','</a>','</br>','</h1>','</h2>','</h3>');

        function isAcceptableHtmlTag(tag){
          tag='<'+tag;
          for(var i=0;i<htmlTagsArray.length;i++){
            if(tag.startsWith(htmlTagsArray[i])){
              return true;
            }
          }
        }

        var ajaxChangeWatchingCallback = {
        success: function(o) {
          var respText = o.responseText;
          var json = eval('(' + respText+')');
          if(json.msgType == "success"){
            if(typeof(json.notifications)!='undefined'){
                 if(json.notifications == "start"){
                    document.getElementById("stopNotifications").style.display="";
                    document.getElementById("startNotifications").style.display="none";
                }else{
                    document.getElementById("startNotifications").style.display="";
                    document.getElementById("stopNotifications").style.display="none";
                }
             }else{
                if(typeof(flag)=='undefined'){
                  var time = json.watchTime;
                  var pageChangeTime = null;
                  if(document.getElementById('pageChangeTime')!= null){
                    pageChangeTime = document.getElementById('pageChangeTime').value;
                  }

                  if (time>pageChangeTime){
                    document.getElementById("01").style.display="";
                    document.getElementById("02").style.display="none";
                    document.getElementById("03").style.display="none";
                  }
                  else if(time>0){
                    document.getElementById("01").style.display="none";
                    document.getElementById("02").style.display="";
                    document.getElementById("03").style.display="none";
                  }
                  else{
                    document.getElementById("01").style.display="none";
                    document.getElementById("02").style.display="none";
                    document.getElementById("03").style.display="";
                  }

                }
                else{
                  deleteRow();
                }
            }
          }
          else{
            showErrorMessage("Result", json.msg , json.comments );
          }
        },
        failure: function(o) {
          var errorMsg = "<fmt:message key='nugen.generatInfo.callback.failure.error.message'/>"+o.responseText;
            alert(errorMsg);
        }
        }

    var closeJSP = false;
    function submitAsynchForm(formObject,action,close){

        if((action=='Save' || action=='SaveAsDraft') && close !=true){
            if(document.getElementById(action) != null){
                document.getElementById(action).id='Update';
            }
        }
        if(close){
            closeJSP = close;
        }
        YAHOO.util.Connect.setForm(formObject);
        YAHOO.util.Connect.asyncRequest('POST', 'createLeafletSubmit.ajax',formSubmitResponse);
        YAHOO.util.Connect.resetFormState();

    }

var formSubmitResponse ={
    success: function(o) {
        var respText = o.responseText;

        var json = eval('(' + respText+')');
        if(json.msgType == "success"){
            document.getElementById('oid').value= json.noteId;
            if(closeJSP){
                window.close();
            }

            var url = window.location.href;
            var action = document.getElementById('action').value;

            if(action == 'Edit' || action == 'SaveAsDraft'|| action == 'Update' ){

                if(action == 'SaveAsDraft'){
                    alert("This Topic has been saved 'Draft Topics' section.");
                }
                var flagClose = document.getElementById('flagClose').value;
                if(flagClose == 'yes'){
                    window.close();
                }else{
                    url = url.replace("action=Comments","action=Edit");
                    window.location = url+"&oid="+json.noteId;
                }
            }else{
                window.location = url.replace("action=Comments","action=Edit");
            }
        }
        else{
            showErrorMessage("Unable to Perform Action", json.msg , json.comments);
        }
    },
    failure: function(o) {
        alert("Error in createLeafletSubmit.ajax: "+o.responseText);
    }
}



        function isNullOrBlank(id, label){
            var val = "";

            if(document.getElementById(id) != null){
                if(document.getElementById(id).value == ""){
                    alert(label+" field is empty.");
                    document.getElementById(id).focus();
                    return false;
                }else{
                    return true;
                }
            }
            return false;
        }


        /*
         * Variables related to auto complete js.
         */
        var autoSuggestList = new Array();
        var autoAssignTextBox;
        var previousMatchKey = "";
        var actionVal = "";
        var multipleAllowed=true;

        function doCompletion(e) {
          e = (e ? e : window.event);

          if(typeof(e.target)!='undefined'&& e.target.className!="wickEnabled"){
          return false;
        }
          else if(typeof(e.srcElement)!='undefined' && e.srcElement.className!="wickEnabled"){
            return false;
          }
            var textvalue = document.getElementById(autoAssignTextBox).value;
            var tmp=trimme(textvalue);

            if(textvalue.indexOf(",")!=-1){
              tmp = trimme(textvalue.substr(textvalue.lastIndexOf(",")+1));
            }

            if (tmp.length > 2 ) {

              if((e.keyCode >= 48 && e.keyCode <=90) || ( e.keyCode == 8 || e.keyCode == 32 || (e.keyCode >=96 && e.keyCode <=105)  )){
                var url="";
                if(actionVal.indexOf("?")!=-1){
                  url = actionVal+"&matchkey=" + escape(tmp);
                }
                else{
                  url = actionVal+"?matchkey=" + escape(tmp);
                }

                  var req = initRequest();
                  req.onreadystatechange = function() {
                  if (req.readyState == 4) {
                    if (req.status == 200) {
                     autoSuggestList = new Array();
                     autoSuggestList = req.responseText.split(",");
                     handleKeyPress(e);
                     previousMatchKey = tmp;
                    } else if (req.status == 204){

                    }
                  }};
                 req.open("GET", url, true);
                 req.send(null);
              }
            }else{
              handleKeyPress(e);
            }

          }

        function trimme(str)
        {
           return str.replace(/^\s*|\s*$/g,"");
        }


        function initRequest() {
             if (window.XMLHttpRequest) {
                 return new XMLHttpRequest();
             } else if (window.ActiveXObject) {
                 isIE = true;
                 return new ActiveXObject("Microsoft.XMLHTTP");
             }
          }


var showHistoryToggel = false;

function showHistory(divId){
  if(!showHistoryToggel){
    document.getElementById(divId).style.display = "block";
    showHistoryToggel = true;
  }else{
    document.getElementById(divId).style.display = "none";
    showHistoryToggel = false;
  }
}


function clearFieldAssignee(elementName) {

        var assigneeEmail=document.getElementById(elementName).value;
        if(emailadd==assigneeEmail){
            document.getElementById(elementName).value="";
            document.getElementById(elementName).style.color="black";
        }
    }

function defaultAssigneeValue(elementName) {
        var assigneeEmail=document.getElementById(elementName).value;

        if(assigneeEmail==""){
            emailflag=false;
            document.getElementById(elementName).value=emailadd;
            document.getElementById(elementName).style.color="gray";
        }
    }

    var isPublishFromEdit=false;

    function publishNote(baseUrl,pageId,note_id, publishFromEditNote){
        isPublishFromEdit = publishFromEditNote;
        if(changeInNote){
            if(confirm("You have made some changes. Publish will lost all these changes. Do you want to continue?")){
                YAHOO.util.Connect.asyncRequest('POST', baseUrl+"t/createLeafletSubmit.ajax?oid="+note_id+"&p="+pageId+"&action=publish",publishNoteResponse);
            }
        }else{
            if(confirm("Are you sure to publish this note?")){
                YAHOO.util.Connect.asyncRequest('POST', baseUrl+"t/createLeafletSubmit.ajax?oid="+note_id+"&p="+pageId+"&action=publish",publishNoteResponse);
            }
        }
    }

    var publishNoteResponse = {
        success: function(o) {
                var respText = o.responseText;
                var json = eval('(' + respText+')');
                if(json.msgType == "success"){
                    if(json.visibility == 1){
                        alert("'"+json.subject+"' topic has been publish under Public Topics.");
                        if(isPublishFromEdit){
                            window.close();
                        }else{
                            window.location = "public.htm"
                        }
                    }else{
                        alert("'"+json.subject+"' topic has been publish under Member Topics.");
                        if(isPublishFromEdit){
                            window.close();
                        }else{
                            window.location = "member.htm"
                        }
                    }
                }
                else{
                     showErrorMessage("Unable to Perform Action", json.msg , json.comments);
                }
                return false;
            },
        failure: function(o) {
            alert("publishNoteResponse Error:" +o.responseText);
            return false;
        }
    }

    var changeInNote = false;

    function validateEmail(field) {
        //var regex=/^[A-Z0-9._-]+@[A-Z0-9._]+\.[A-Z]{2,4}\b/i;
        var regex=/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i;
        return (regex.test(field)) ? true : false;
    }

    function breakMultipleEmailsBySeparators(value){
        var result = new Array();
        if(value.indexOf(";") != -1){
            result = value.split(";");
        }else if(value.indexOf(",") != -1){
            result = value.split(",");
        }else if(value.indexOf("\n") != -1){
            result = value.split("\n");
        }else{
            value = value+";";
            result = value.split(";");
        }
        return result;
    }

    function validateMultipleEmails(result) {
        for(var i = 0;i < result.length;i++){
             if(trimme(result[i]) != ""){
                 if(!validateEmail(trimme(result[i]))){
                     alert("'"+result[i]+ "' does not look like an email address. Please enter an email id.");
                     return false;
                 }
             }
         }
        return true;
    }

    function contains(a, obj) {
        var i = a.length;
        while (i--) {
           if (a[i] === obj) {
               return true;
           }
        }
        return false;
    }
