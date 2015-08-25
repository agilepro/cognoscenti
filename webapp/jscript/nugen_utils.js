   function initCal(){
        setUPCal("dueDate","btn_dueDate");
      }

   function openWin(url){
       window.open(url);
       return false;
   }

      function setUPCal(fieldName,buttonName){

           Calendar.setup({
        inputField     :    fieldName,  // id of the input field
        ifFormat       :    "%m/%d/%Y",                // format of the input field
        showsTime      :    true,                        // show the time
        electric       :    false,                       // update date/time only after clicking
        date           :    new Date(),                  // show the time
        button         :    buttonName,      // trigger for the calendar (button ID)
        align          :    "Bl",                      // alignment (defaults to "Bl")
        singleClick    :    true
    });
    }


      function submitForm(){
          throw "I don't believe submitForm is being used";
      if(!validate()){
        alert(projectNameRequiredAlert);
          return false;
      }

       return isProjectExist();
  }



function validate(){
    var projectName =  document.getElementById("projectname");
    if(flag && !projectName.value=='' || !projectName.value==null){
        return true;
    }
    return false;
}

function updateVal(){
  flag=true;
}


 Tab = function(href,name){
          this.name=name;
          this.href=href;

      };
TabRef = function(href,name,ref){
          this.name=name;
          this.href=href;
          this.ref=ref;
      };

function createTabs(){
    var mainElement = document.getElementById("tabs");
    var arrayOfTabs;
    var shortPath = "t/"+book+"/"+pageId;
    var homePath = shortPath + "/notesList.htm";
    if (shortPath == "t///projectHome.htm") {
        homePath = "";
    }
    if(headerType == "user"){
        arrayOfTabs = [
            new TabRef(retPath+"v/"+userKey+"/watchedProjects.htm","Projects","userSubMenu1"),
            new TabRef(retPath+"v/"+userKey+"/userAlerts.htm","Updates",""),
            new TabRef(retPath+"v/"+userKey+"/userActiveTasks.htm","Goals","userSubMenu2"),
            new TabRef(retPath+"v/"+userKey+"/userSettings.htm","Settings","userSubMenu3")
        ];

        if(isSuperAdmin=="true"){
            arrayOfTabs.push(new TabRef(retPath+"v/"+userKey+"/emailListnerSettings.htm","Administration","userSubMenu4"));
        }
    }
    else if(headerType == "site") {
        arrayOfTabs = [
            new TabRef(retPath+"t/"+accountId+"/$/accountListProjects.htm","Site Projects","accountSubMenu2"),
            new TabRef(retPath+"t/"+accountId+"/$/account_settings.htm","Site Settings","accountSubMenu4")
        ];
    }
    else if(headerType == "project") {
        arrayOfTabs = [
            new TabRef(retPath+"t/"+book+"/"+pageId+"/history.htm","Project Stream",""),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/notesList.htm","Project Notes","ddsubmenu1"),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/goalList.htm","Project Goals","ddsubmenu2"),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/listAttachments.htm","Project Documents","ddsubmenu3"),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/personal.htm","Project Settings","ddsubmenu4")
        ];
    }
    else  {
        arrayOfTabs = [
            new TabRef(retPath+homePath,"Home","")
        ];
    }

    for(var  i=0;i<arrayOfTabs.length ;i++){

        var newli   = document.createElement('li');
        var newlink = document.createElement('a');

        newlink.setAttribute('onclick','updateSpecialTab("'+arrayOfTabs[i].name+'");');
        var newspan = document.createElement('span');

        newlink.setAttribute('href',arrayOfTabs[i].href);
        newlink.setAttribute('rel',arrayOfTabs[i].ref);

        if(arrayOfTabs[i].name=="Project Stream" ){
            newli.className = 'mainNavLink1';
        }
        if(arrayOfTabs[i].name=="Projects" ){
            newli.className = 'mainNavLink1';
        }

        if(specialTab=="null" && ((arrayOfTabs[i].name=="Project Stream")||(arrayOfTabs[i].name=="Projects") ||(arrayOfTabs[i].name=="Site Notes"))){
            newli.className = 'mainNavLink1 selected';
        }
        else if(specialTab==arrayOfTabs[i].name){
            if( (arrayOfTabs[i].name=="Project Stream")||
                (arrayOfTabs[i].name=="Projects") ){
                newli.className = 'mainNavLink1 selected';
            }
            else {
                newli.className = 'selected';
            }
        }

        newspan.innerHTML=arrayOfTabs[i].name;

        newlink.appendChild(newspan);
        newli.appendChild(newlink);
        mainElement.appendChild(newli);

    }
    ddlevelsmenu.setup("tabs", "topbar");
}

function updateSpecialTab(tabName){
    specialTab=tabName;
}

function createSubLinks(){

    var arrayOfSubMenu=0;
    var arrayOfMainMenu=0;

    if(headerType == "site") {

        var accountSubMenu2 = [new Tab(retPath+"t/"+accountId+"/$/accountListProjects.htm","List Projects"),
            new Tab(retPath+"t/"+accountId+"/$/accountCreateProject.htm","Create New Project"),
            new Tab(retPath+"t/"+accountId+"/$/accountCloneProject.htm","Clone Remote Project"),
            new Tab(retPath+"t/"+accountId+"/$/convertFolderProject.htm","Convert Folder to Project"),
            new Tab(retPath+"t/"+accountId+"/$/searchAllNotes.htm", "Search Notes")
        ];
        var accountSubMenu4 = [new Tab(retPath+"t/"+accountId+"/$/personal.htm","Personal"),
            new Tab(retPath+"t/"+accountId+"/$/permission.htm","Permissions"),
            new Tab(retPath+"t/"+accountId+"/$/roleRequest.htm","Role Requests"),
            new Tab(retPath+"t/"+accountId+"/$/admin.htm","Admin")
        ];
        arrayOfSubMenu=["accountSubMenu2","accountSubMenu4"];
        arrayOfMainMenu =[accountSubMenu2, accountSubMenu4];
    }
    else if(headerType == "user"){

        var arrayOfTabs1 = [new Tab(retPath+"v/"+userKey+"/watchedProjects.htm","Watched Projects"),
            new Tab(retPath+"v/"+userKey+"/notifiedProjects.htm","Notified Projects"),
            new Tab(retPath+"v/"+userKey+"/ownerProjects.htm","Administered Projects"),
            new Tab(retPath+"v/"+userKey+"/templates.htm","Templates"),
            new Tab(retPath+"v/"+userKey+"/participantProjects.htm","Participant Projects"),
            new Tab(retPath+"v/"+userKey+"/allProjects.htm","All Projects"),
            new Tab(retPath+"t/"+userKey+"/searchAllNotes.htm", "Search Notes"),
            new Tab(retPath+"v/"+userKey+"/userCreateProject.htm","Create New Project")
        ];

        var arrayOfTabs2 = [new Tab(retPath+"v/"+userKey+"/userActiveTasks.htm","Worklist Goals"),
            new Tab(retPath+"v/"+userKey+"/ShareRequests.htm","Share Requests"),
            new Tab(retPath+"v/"+userKey+"/RemoteProfiles.htm","Remote Profiles"),
            new Tab(retPath+"v/"+userKey+"/userRemoteTasks.htm","Remote Goals"),
            new Tab(retPath+"v/"+userKey+"/Agents.htm","Personal Assistant")
        ];

        var arrayOfTabs3 = [new Tab(retPath+"v/"+userKey+"/userSettings.htm","Personal"),
            new Tab(retPath+"v/"+userKey+"/userContacts.htm","Contacts"),
            new Tab(retPath+"v/"+userKey+"/userConnections.htm","Connections"),
            new Tab(retPath+"v/"+userKey+"/userAccounts.htm","Sites"),
            new Tab(retPath+"v/"+userKey+"/notificationSettings.htm","Unsubscribe")
        ];

        if(isSuperAdmin=="true"){
            var arrayOfTabs4 = [new Tab(retPath+"v/"+userKey+"/emailListnerSettings.htm","Email"),
                new Tab(retPath+"v/"+userKey+"/lastNotificationSend.htm","Last Notification Send"),
                new Tab(retPath+"v/"+userKey+"/errorLog.htm",      "Error Log"),
                new Tab(retPath+"v/"+userKey+"/newAccounts.htm",   "New Sites"),
                new Tab(retPath+"v/"+userKey+"/newUsers.htm",      "New Users"),
                new Tab(retPath+"v/"+userKey+"/requestedAccounts.htm","Requested Sites"),
                new Tab(retPath+"v/"+userKey+"/deniedAccounts.htm","Denied Sites")
            ];
            arrayOfSubMenu  =["userSubMenu1","userSubMenu2","userSubMenu3","userSubMenu4"];
            arrayOfMainMenu =[ arrayOfTabs1,  arrayOfTabs2,  arrayOfTabs3,  arrayOfTabs4]
        }
        else{
            arrayOfSubMenu  =["userSubMenu1","userSubMenu2","userSubMenu3"];
            arrayOfMainMenu =[ arrayOfTabs1,  arrayOfTabs2,  arrayOfTabs3]
        }


    }

    else{   //This is the Project case

        var arrayOfTabs1 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/notesList.htm",   "List Notes"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/automaticLinks.htm","Automatic Links"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/searchAllNotes.htm","Search All Notes"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/exportPDF.htm",   "Generate PDF"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/editNote.htm?public=true",  "Create New Note &gt;")
        ];

        var arrayOfTabs2 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/goalList.htm",             "List Goals"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/projectActiveTasks.htm",   "OLD Active Goals"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/projectCompletedTasks.htm","OLD Completed Goals"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/projectFutureTasks.htm",   "OLD Future Goals"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/projectAllTasks.htm",      "OLD All Goals"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/meetingList.htm",          "Meeting List"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/agendaBacklog.htm",        "Agenda Item Backlog")
        ];

        var arrayOfTabs3 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/listAttachments.htm",   "List Documents"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/docsFolder.htm",        "Document Folders"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/docsAdd.htm",           "Add Document"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/SyncAttachment.htm",    "Synchonize") ,
            new Tab(retPath+"t/"+book+"/"+pageId+"/reminders.htm",         "Reminders"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/emailReminder.htm",     "Ask Someone to Attach File"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/docsDeleted.htm",       "Deleted Documents"),
        ];
        var arrayOfTabs4 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/personal.htm",      "Personal"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/permission.htm",    "Permissions"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/roleRequest.htm",   "Role Requests") ,
            new Tab(retPath+"t/"+book+"/"+pageId+"/admin.htm",         "Admin" ),
            new Tab(retPath+"t/"+book+"/"+pageId+"/labelList.htm",     "Labels" ),
            new Tab(retPath+"t/"+book+"/"+pageId+"/listEmail.htm",     "Email Prepared"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/emailSent.htm",     "Email Sent"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/streamingLinks.htm","Streaming Links"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/synchronizeUpstream.htm","Synchronize Upstream")
        ];
        arrayOfSubMenu=["ddsubmenu1","ddsubmenu2","ddsubmenu3","ddsubmenu4"];
        arrayOfMainMenu =[arrayOfTabs1,arrayOfTabs2,arrayOfTabs3,arrayOfTabs4]
    }

    for(var  j=0;j<arrayOfSubMenu.length ;j++){
        var arrayOfTabs=arrayOfMainMenu[j];
        for(var  i=0;i<arrayOfTabs.length ;i++){
            var mainElement = document.getElementById(arrayOfSubMenu[j]);
            var newli= document.createElement('li');
            var newlink = document.createElement('a');
            var newspan = document.createElement('span');
            newlink.setAttribute('href',arrayOfTabs[i].href);
            if (arrayOfTabs[i].name.indexOf('&gt;')>0) {
                newlink.setAttribute('target','_blank');
            }
            newlink.setAttribute('href',arrayOfTabs[i].href);
            newspan.innerHTML=arrayOfTabs[i].name;
            newlink.appendChild(newspan);
            newli.appendChild(newlink);
            mainElement.appendChild(newli);
        }
    }
}



    function formatText(val){
      var bar = val.split("<");
          var level=0;
          var updatedValue="";
          var liHTML=false;
          var bold=false;
          var italics=false;

          for(var i = 0;i<bar.length;i++){
            var clazz = "\"";
          var ch =bar[i];

          if (ch.startsWith("ul>")) {
            level++;
            updatedValue+="<ul>";
            continue;
          }
          else if (ch.startsWith("li>")) {
            for (var j = 0; j < level; j++) {
              // line=line.replaceFirst(ul1CloseHTML,"");
              clazz += "u";
            }
            liHTML=true;

            var newLI = ch.replace("li", "<li class=" + clazz+" \"");
            updatedValue+=newLI;
            continue;
          }
          else if(ch.startsWith("/ul>")){
            level--;
            updatedValue+="</ul>";
            continue;
          }
          else if(ch.startsWith("/li>")){
            updatedValue+="</li>\n";
            continue;
          }
          else if(ch.match('bold;')){
            var text = ch.substring(ch.indexOf('>')+1);

            if(ch.match('italic;')){
              updatedValue+="<b><i>"+text;
              bold=true;
              italics=true;
            }
            else{
              updatedValue+="<b>"+text;
              bold=true;
            }

            continue;
          }
          else if(ch.match('italic;')){
            var text = ch.substring(ch.indexOf('>')+1);
            updatedValue+="<i>"+text;
            italics=true;
            continue;
          }
          else if(ch.startsWith("span")){
            var text = ch.substring(ch.indexOf('>')+1);
            updatedValue+=text;
            continue;

          }
          else if((bold || italics) && ch.startsWith("br")){
            if(italics){
              updatedValue+="</i>";
              var text = ch.substring(ch.indexOf('>')+1);
              alert(text)
              updatedValue+="\n\r<i>"+text;
              italics=true;
            }
            if(bold){
              updatedValue+="</b>";
              var text = ch.substring(ch.indexOf('>')+1);
              updatedValue+="\n\r<b>"+text;
              bold=true;
            }

          }
          else if(ch.match('/span>')){

            if(italics){
              updatedValue+="</i>";
              italics=false;
            }
            if(bold){
              updatedValue+="</b>";
              bold=false;
            }
            var text = ch.substring(ch.indexOf('>')+1);
            updatedValue+=text;
            continue;
          }
          else if(ch.startsWith('div')){
            updatedValue+=ch.substring(ch.indexOf('>')+1);
            continue;
          }
          else if(ch.startsWith('/div')){
            updatedValue+="";
            continue;
          }
          else if(ch!=""){
            if(ch.indexOf(">")!=-1){
              if(isAcceptableHtmlTag(ch)){
                if((ch.substring(0,ch.indexOf('>')+1)).indexOf("\s")!=-1){
                  var tag='';
                  if(!("<"+ch).startsWith('<a')){
                    tag=ch.substring(0,ch.indexOf(' '));
                  }else{
                    tag='a '+ch.substring(ch.indexOf('href'));
                    tag=tag.substring(0,tag.indexOf('>'));
                  }
                  var content='';
                  if(ch.indexOf('>')!=ch.length){
                    content=ch.substring(ch.indexOf('>')+1);
                  }

                  updatedValue+="<"+tag+">"+content;
                }else{
                  updatedValue+="<"+ch;
                }
              }
              else{
                var content=ch.substring(ch.indexOf('>')+1);
                updatedValue+=content;
              }

            }
            else
              updatedValue+=ch+"\n";

            continue;
          }
        }
          return updatedValue;

        }

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
                    alert("This Note has been saved 'Draft Notes' section.");
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


var toggel = false;
function expandCollapseAll(cpath){
  var allDivs = document.getElementsByTagName("div");
  for(index=0;index < allDivs.length ; index++){
    if(allDivs[index].id.startsWith('comment')){
      if(!toggel){
        allDivs[index].style.display = "block";
      }else{
        allDivs[index].style.display = "";
      }
      var hyphen_index = allDivs[index].id.indexOf("-");
      var headingId = "leafHeading"+allDivs[index].id.substring(hyphen_index+1);
      expandCollapseLeaflets(allDivs[index].id,cpath,headingId);

    }

  }
  if(toggel){
    toggel = false;
    document.getElementById("expand_collapse").innerHTML = "[+]";
    document.getElementById("expand_collapse").title = "Expand All";
  }else{
    document.getElementById("expand_collapse").innerHTML = "[-]";
    document.getElementById("expand_collapse").title = "Collapse All";
    toggel = true;
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
                        alert("'"+json.subject+"' note has been publish under Public Notes.");
                        if(isPublishFromEdit){
                            window.close();
                        }else{
                            window.location = "public.htm"
                        }
                    }else{
                        alert("'"+json.subject+"' note has been publish under Member Notes.");
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
