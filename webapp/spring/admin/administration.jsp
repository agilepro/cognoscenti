<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.FileInputStream"
%><%

    request.setCharacterEncoding("UTF-8");

    //List<SiteRequest> allaccounts = SiteReqFile.getAllSiteReqs();
    //List<SiteRequest> deniedAccounts = SiteReqFile.scanDeniedSiteReqs();
    //List<SiteRequest> superRequests = new ArrayList<SiteRequest>();
    //for (SiteRequest accountDetails: allaccounts)
    //{   if (accountDetails.getStatus().equalsIgnoreCase("requested"))
    //    {
    //        superRequests.add(accountDetails);
    //    }
    //}
    long lastSentTime = ar.getSuperAdminLogFile().getLastNotificationSentTime();
    
%>
    <script>
        var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';

    </script>
    <!-- for the tab view -->
    <div id="container">
        <div>
            <ul id="subTabs" class="menu">

            </ul>
        </div>
    </div>

    <!-- Display the search results here -->
    <script type="text/javascript">

        function cancel(){
            myPanel.hide();
        }
        function acceptOrDeny(actionType,stateVal){
            if(stateVal == "Grant" && actionType == "deny"){
                alert("Request is already granted, it can not be denied now.");
                return false;
            }else{
                if(actionType == "deny"){
                    document.getElementById('action').value ="Denied";
                    var description = document.getElementById('description').value;
                    if(description == ""){
                        alert("Description Field is mandetory.");
                        return false;
                    }
                }else{
                    document.getElementById('action').value ="Granted";
                }
                document.getElementById("acceptOrDenyForm").submit();
                return true;
            }
        }



    </script>
</body>
