<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%

    request.setCharacterEncoding("UTF-8");
    UserProfile  uProf = ar.getUserProfile();
%>
<style>
.formFieldHelp {
    margin-bottom:15px;
}
.spaceytable tr td {
    padding:10px;
}
</style>
<script>
    window.setMainPageTitle("Request New Site");
</script>

<div>From here you can request to create a new site from where you can create & handle multiple projects.</div>
<div class="generalSettings">
    <div id="requestAccount">
        <form name="requestNewAccount" action="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/accountRequests.form" method="post">
            <input type="hidden" name="action" id="action" value="">
            <table class="spaceytable">
                <tr>
                    <td class="gridTableColummHeader_2" valign="top"><b>Site Name:<span style="color:red">*</span></b></td>
                    <td><input type="text" name="accountName" id="accountName" class="form-control" />
                        <span class="formFieldHelp">Enter a descriptive proper name.  This can be changed later.</span></td>
                </tr>
                <tr>
                    <td class="gridTableColummHeader_2" valign="top"><b>Site ID:<span style="color:red">*</span></b></td>
                    <td><input type="text" name="accountID" id="accountID" class="form-control"/>
                        <span class="formFieldHelp">Enter 4 to 8 letters and numbers to identify this site uniquely.<br/>
                        The value you pick here is permanent, and can not be changed for this site.</span></td>
                </tr>
                <tr>
                    <td class="gridTableColummHeader_2" valign="top"><b>Site Description:<span style="color:red">*</span></b></td>
                    <td><textarea name="accountDesc" id="accountDesc" class="form-control" rows="4"></textarea>
                        <span class="formFieldHelp">The description helps others know what you intend to use this site for.</span></td>
                </tr>
                <tr>
                    <td class="gridTableColummHeader_2"></td>
                    <td><input type="submit" value="<fmt:message key='nugen.button.general.submit'/>" class="btn btn-primary btn-raised"  onclick="javascript:requestAccount('Submit')"/>
                    &nbsp;<input type="submit" value="<fmt:message key='nugen.button.general.cancel'/>" class="btn btn-primary btn-raised"  onclick="javascript:requestAccount('Cancel')"/>
                    </td>
                </tr>
            </table>
        </form>
    </div>
    <script>
        function requestAccount(action){
            document.getElementById("action").value=action;
        }
    </script>
<%@ include file="functions.jsp"%>
