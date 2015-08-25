<%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%!
    String pageTitle="";
%><%
/*
Required parameter:

    1. accountId : This is the id of a site and used to retrieve NGBook.

*/

    //this page should only be called when logged in and having access to the site
    ar.assertLoggedIn("Must be logged in to clone a remote project");

    String accountKey = ar.reqParam("accountId");

    UserProfile  uProf =ar.getUserProfile();
    Vector<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());

    String upstream = ar.defParam("upstream", "");
    String desc = ar.defParam("desc", "");
    String pname = ar.defParam("pname", "");

%>

<script>
    var flag=false;
    var projectNameRequiredAlert = '<fmt:message key="nugen.project.name.required.error.text"/>';
    var projectNameTitle = '<fmt:message key="nugen.project.projectname.textbox.text"/>';

    function isProjectExist(){
        var projectName = document.getElementById('projectname').value;
        var url="../isProjectExist.ajax?projectname="+projectName+"&siteId=<% ar.writeURLData(accountKey); %>";
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
</script>
<body>


<div class="pageHeading">Create Clone from Remote Project</div>
<div class="pageSubHeading"></div>

<div class="generalContent">
   <form name="projectform" action="createClone.form" method="post" autocomplete="off">
        <table class="popups">
           <tr><td style="height:30px"></td></tr>
            <tr>
                <td colspan="3">
                <table id="assignTask">
                    <tr>
                        <td>Enter the streaming link from the remote project you would like to clone:</td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td><input type="text" class="form-control" style="width:368px" size="50" name="upstream"/>
                        </td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td><input type="submit" class="btn btn-default" name="op" value="Create Clone"/>
                        </td>
                    </tr>
                </table>
               </td>
            </tr>
       </table>
   </form>

    </body>
