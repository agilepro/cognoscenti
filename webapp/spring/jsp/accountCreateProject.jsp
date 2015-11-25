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
    ar.assertLoggedIn("Must be logged in to create a workspace");

    String accountKey = ar.reqParam("accountId");

    UserProfile  uProf =ar.getUserProfile();
    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());

    String upstream = ar.defParam("upstream", "");
    String desc = ar.defParam("desc", "");
    String pname = ar.defParam("pname", "");

%>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Create Workspace in this Site
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="" >Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>


<div class="generalContent">
   <form name="projectform" action="createprojectFromTemplate.form" method="post" autocomplete="off">
        <table class="popups">
           <tr><td style="height:30px"></td></tr>
           <tr>
                <td class="gridTableColummHeader_2 bigHeading">New Workspace Name:</td>
                <td style="width:20px;"></td>
                <td>
                    <table cellpadding="0" cellspacing="0">
                       <tr>
                           <td class="createInput" style="padding:0px;">
                               <input type="text" class="inputCreateButton" name="projectname"
                                   value="<%ar.writeHtml(pname);%>"/>
                           </td>
                           <td><button type="submit" class="createButton"></button></td>
                       </tr>
                   </table>
               </td>
            </tr>
            <tr>
                <td colspan="3">
                <table id="assignTask">
                    <tr><td width="148" class="gridTableColummHeader_2" style="height:20px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader_2">Select Template:</td>
                        <td style="width:20px;"></td>
                        <td><Select class="form-control" id="templateName" name="templateName">
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
                        <td width="148" class="gridTableColummHeader_2">Upstream Link:</td>
                        <td style="width:20px;"></td>
                        <td><input type="text" class="form-control" style="width:368px" size="50" name="upstream"
                            value="<%ar.writeHtml(upstream);%>"/>
                        </td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                </table>
               </td>
            </tr>
       </table>
   </form>

