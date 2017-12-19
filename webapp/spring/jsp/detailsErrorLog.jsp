<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.ErrorLog"
%><%@page import="org.socialbiz.cog.ErrorLogDetails"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%

/*

Required Parameters:

    1. errorId      : This parameter specifies the error id to look up and display.
    2. errorDate    : The date of the log file to find the error in.
    3. goURL        : This is the url of current page which is used when form is successfully processed bt controller.
*/


    long errorDate = Long.parseLong((String)request.getAttribute("errorDate"));
    int errorId = Integer.parseInt((String)request.getAttribute("errorId"));
    String searchByDate=ar.reqParam("searchByDate");
    String goURL=ar.reqParam("goURL");

    Cognoscenti cog = Cognoscenti.getInstance(request);
    ErrorLog eLog = ErrorLog.getLogForDate(errorDate, cog);
    ErrorLogDetails eDetails = eLog.getDetails(errorId);

    SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
    String searchDate = sdf.format(new Date(errorDate));
    String formattedDate = new SimpleDateFormat("yyyy/MM/dd hh:mm:ss.SSS").format(eDetails.getModTime());

%>
<script type="text/javascript">

function postMyComment(){
    document.forms["logUserComents"].submit();
}
</script>

<!-- Begin mainContent (Body area) -->
<div ng-app="myApp" ng-controller="myCtrl">


    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="errorLog.htm?searchDate=<%=searchDate%>">Return to Error List</a></li>
        </ul>
      </span>
    </div>
        <div class="generalSettings">
             <form name="logUserComents" action="logUserComents.form" method="post">

              <input type="hidden" name="errorNo" id="errorNo" value="<%ar.writeHtml(errorId); %>"/>
              <input type="hidden" name="searchByDate" id="searchByDate" value="<%ar.writeHtml(searchByDate); %>"/>
              <input type="hidden" name="goURL" id="goURL" value="<%ar.writeHtml(goURL); %>"/>

                <table width="100%" border="0px solid red">
                    <tr>
                      <td style="text-align:left">
                        <b>Error Message:</b>  <%ar.writeHtmlWithLines(eDetails.getErrorMessage()); %>
                        <br /><br />
                        <b>Page:</b> <a href="<%ar.writeHtml(eDetails.getURI()); %>"><%ar.writeHtml( eDetails.getURI()); %></a>
                        <br /><br />
                        <b>Date & Time:</b> <%ar.writeHtml(formattedDate); %>
                        <br /><br />
                        <b>User Detail: </b> <%ar.writeHtml(eDetails.getModUser()); %>
                        <br /><br />
                        <b>Comments: </b>
                        <br />
                        <textarea rows="4" name="comments" id="comments" class="textAreaGeneral"><%ar.writeHtml(eDetails.getUserComment()); %></textarea>
                        <br /><br />
                        <input type="submit" class="btn btn-primary btn-raised" value="<fmt:message key="nugen.button.comments.update" />"
                                                                onclick="postMyComment()">
                    </td>
                  </tr>
                    <tr><td style="height:20px"></td></tr>
                     <tr>
                         <td class="errorDetailArea">
                            <span id="showDiv" style="display:inline" onclick="setVisibility('errorDetails')">
                                Show Error Details &nbsp;&nbsp;
                                 <img src="<%=ar.retPath %>assets/expandBlackIcon.gif" title="Expand" alt="" />
                             </span>
                            <span id="hideDiv" style="display:none" onclick="setVisibility('errorDetails')">
                                Hide Error Details &nbsp;&nbsp;
                                <img src="<%=ar.retPath %>assets/collapseBlackIcon.gif" title="Collapse" alt="" />
                             </span>
                         </td>
                     </tr>

                      <tr><td style="height:20px"></td></tr>
                      <tr>
                          <td style="text-align:left">
                            <div id="errorDetails" class="errorStyle" style="display:none;">
                            <pre style="overflow:auto;width:900px;"><%ar.writeHtml(eDetails.getErrorDetails()); %></pre>
                            </div>
                          </td>
                      </tr>
                </table>
             </form>

        </div>
 </div>


