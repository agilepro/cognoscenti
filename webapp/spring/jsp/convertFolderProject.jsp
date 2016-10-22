<%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%!
    String pageTitle="";
%><%
    /*
    Required parameter:

        1. accountId : This is the id of a site and used to retrieve NGBook.
        2. path: this is the subpath within the site

    */
    if(!ar.isLoggedIn()){
        throw new Exception("convertFolderProject VIEW should be called only when logged in");
    }

    String siteKey = ar.reqParam("accountId");
    NGBook site = NGBook.readSiteByKey(siteKey);
    String path       = ar.defParam("path","/");
    File siteRoot   = site.getSiteRootFolder();
    if (siteRoot==null) {
        throw new Exception("This site does not have a preferred path set.");
    }
    if (!siteRoot.exists()) {
        throw new Exception("Base path for this site does not exist: "+siteRoot);
    }
    File target = new File(siteRoot, path);
    File[] children = target.listFiles();
    if (children==null) {
        children = new File[0];
    }
    File parent = target.getParentFile();
    int stripLen = siteRoot.toString().length();
    String parentPath = null;
    if (parent.toString().length()>=stripLen) {
        parentPath = parent.toString().substring(stripLen).replace("\\","/");
    }

    List<File> folders = new ArrayList<File>();
    int fileCount = 0;
    for (File poss : children) {
        if (poss.isDirectory()) {
            folders.add(poss);
        }
        else {
            fileCount++;
        }
    }

    UserProfile  uProf =ar.getUserProfile();
    List<NGPageIndex> templates = new ArrayList<NGPageIndex>();
    if(uProf != null){
        for(TemplateRecord tr : uProf.getTemplateList()){
            String pageKey = tr.getPageKey();
            NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
            if (ngpi!=null) {
                //silently ignore templates that no longer exist
                templates.add(ngpi);
            }
        }
        NGPageIndex.sortInverseChronological(templates);
    }

%>

<script>
    var flag=false;
    var projectNameRequiredAlert = '<fmt:message key="nugen.project.name.required.error.text"/>';
    var projectNameTitle = '<fmt:message key="nugen.project.projectname.textbox.text"/>';

    function isProjectExist(){
        var projectName = document.getElementById('projectname').value;
        var url="../isProjectExist.ajax?projectname="+projectName+"&siteId=<% ar.writeURLData(siteKey); %>";
        var transaction = YAHOO.util.Connect.asyncRequest('POST',url, projectValidationResponse);
        return false;
    }

    var projectValidationResponse ={
        success: function(o) {
            var respText = o.responseText;
            var json = eval('(' + respText+')');
            if(json.msgType == "no"){
                document.forms["projectform"].submit();
            }
            else{
                showErrorMessage("Result", json.msg, json.comments);
            }
        },
        failure: function(o) {
            alert("projectValidationResponse Error:" +o.responseText);
        }
    }
    function submitFormF(){
        document.forms["projectform"].submit();
    }
</script>
<body>

<div class="pageHeading">Convert Folder to Workspace</div>
<div class="pageSubHeading"></div>

<div class="generalContent">
   <table class="popups">
       <tr>
            <td class="gridTableColummHeader_2">Site:</td>
            <td style="width:20px;"></td>
            <td ><% ar.writeHtml(siteRoot.toString()); %></td>
       </tr>
       <tr><td style="height:10px"></td></tr>

       <% if (parentPath!=null) {
           String parentVisual = parentPath;
           if (parentPath.length()==0) {
               parentVisual = "(root)";
           }%>
           <form action="convertFolderProject.htm" method="get">
               <input type="hidden" name="path" value="<% ar.writeHtml(parentPath); %>">
               <tr><td style="height:10px"></td></tr>
               <tr>
                    <td class="gridTableColummHeader_2"><input class="btn btn-primary btn-raised" type="submit" value="Go Up"></td>
                    <td style="width:20px;"></td>
                    <td ><% ar.writeHtml(parentVisual); %></td>
               </tr>
           </form>
       <% } %>



       <% if (folders.size()>0) { %>
           <tr><td style="height:10px"></td></tr>
           <form action="convertFolderProject.htm" method="get">
           <tr>
               <td class="gridTableColummHeader_2"><input class="btn btn-primary btn-raised" type="submit" value="Drill Down"></td>
               <td style="width:20px;"></td>
               <td >
               <select name="path" class="form-control">
                   <% for (File aFolder : folders) {
                   String thisPath = aFolder.toString().substring(stripLen).replace("\\","/"); %>
                       <option value="<% ar.writeHtml(thisPath); %>"><% ar.writeHtml(thisPath); %></option>
                   <% } %>
               </td>
           </tr>
           </form>
       <% } else { %>
           <tr>
                <td class="gridTableColummHeader_2"></td>
                <td style="width:20px;"></td>
                <td>There are no folders to browse down to.</td>
           </tr>
       <% }  %>

       <% if (hasProject(target)) { %>
           <tr>
                <td class="gridTableColummHeader_2"></td>
                <td style="width:20px;"></td>
                <td>This folder already has a workspace in it.</td>
           </tr>
           <tr><td style="height:10px"></td></tr>
           <tr>
                <td class="gridTableColummHeader_2">Folder:</td>
                <td style="width:20px;"></td>
                <td ><%ar.writeHtml(target.toString()); %> (<%=children.length%> files)</td>
                <input type="hidden" name="loc" value="<%ar.writeHtml(path); %>">
           </tr>

       <% } else if (false && target.equals(siteRoot)) { %>
           <tr>
                <td class="gridTableColummHeader_2"></td>
                <td style="width:20px;"></td>
                <td>You can't create a workspace in the root folder of a site.</td>
           </tr>

       <% } else { %>

       <form name="projectform" action="createprojectFromTemplate.form" method="post" autocomplete="off">

       <tr><td style="height:30px"></td></tr>

       <tr>
            <td class="gridTableColummHeader_2 bigHeading">New Workspace Name:</td>
            <td style="width:20px;"></td>
            <td>
                <table cellpadding="0" cellspacing="0">
                   <tr>
                       <td class="createInput" style="padding:0px;">
                           <span class="inputCreateButton"><%ar.writeHtml(target.getName());%></span>
                           <input type="hidden" name="projectname" id="projectname" value="<%ar.writeHtml(target.getName());%>"/>
                       </td>
                       <td class="createButton" onclick="submitFormF();">&nbsp;</td>
                   </tr>
               </table>
           </td>
        </tr>
       <tr><td style="height:10px"></td></tr>
       <tr>
            <td class="gridTableColummHeader_2">Folder:</td>
            <td style="width:20px;"></td>
            <td ><%ar.writeHtml(target.toString()); %> (<%=fileCount%> files)</td>
            <input type="hidden" name="loc" value="<%ar.writeHtml(path); %>">
       </tr>
        <tr>
            <td colspan="3">
            <table id="assignTask">
                <tr><td width="148" class="gridTableColummHeader_2" style="height:20px"></td></tr>
                <tr>
                    <td width="148" class="gridTableColummHeader_2">Select Template:</td>
                    <td style="width:20px;"></td>
                    <td><Select class="selectGeneral" id="templateName" name="templateName">
                            <option value="" selected>Select</option>
                            <%
                            for (NGPageIndex ngpi : templates) {
                                %>
                                <option value="<%ar.writeHtml(ngpi.containerKey);%>" ><%ar.writeHtml(ngpi.containerName);%></option>
                                <%
                            }
                            %>
                        </Select>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td width="148" class="gridTableColummHeader_2"><fmt:message key="nugen.project.duedate.text"/></td>
                    <td style="width:20px;"></td>
                    <td><input type="text" class="inputGeneral" style="width:368px" size="50" name="dueDate" id="dueDate"  value="" readonly="1"/>
                        <img src="<%=ar.retPath %>/jscalendar/img.gif" id="btn_dueDate" style="cursor: pointer;" title="Date selector"/>
                    </td>
                </tr>
                <tr><td style="height:15px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2" style="vertical-align:top"><fmt:message key="nugen.project.desc.text"/></td>
                    <td style="width:20px;"></td>
                    <td><textarea name="description" id="description" class="textAreaGeneral" rows="4" tabindex=7></textarea></td>
                </tr>
                <tr><td style="height:20px"></td></tr>
            </table>
           </td>
        </tr>
        <tr>
           <td width="148" class="gridTableColummHeader_2"></td>
           <td width="39" style="width:20px;"></td>
           <td style="cursor:pointer">
            <span id="showDiv" style="display:inline" onclick="">
                <img src="<%=ar.retPath %>/assets/createSeperatorDown.gif" width="398" height="13"
                title="Expand" alt="" /></span>
            <span id="hideDiv" style="display:none" onclick="">
                <img src="<%=ar.retPath %>/assets/createSeperatorUp.gif" width="398" height="13"
                title="Collapse" alt="" /></span>
           </td>
        </tr>
        </form>
<script>
function initCal(){
    setUPCal("dueDate","btn_dueDate");
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

initCal();
</script>

       <% }  %>

   </table>

<script type="text/javascript">
    function trim(s) {
        var temp = s;
        return temp.replace(/^s+/,'').replace(/s+$/,'');
    }

</script>

</body>

<%!

    public boolean hasProject(File folder) {
        for (File child : folder.listFiles()) {
            String name = child.getName();
            if (".cog".equals(name)) {
                return true;
            }
            if (name.endsWith(".sp")) {
                return true;
            }
        }
        return false;
    }

%>
