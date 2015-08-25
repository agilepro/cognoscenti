<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not attach a document to this project.");

    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ngb = ngp.getSite();
    ar.setPageAccessLevels(ngp);

    UserPage uPage = ar.getUserPage();
    Vector<ConnectionSettings> connectionList = uPage.getAllConnectionSettings();
    if(connectionList.isEmpty()){
        throw new Exception("User has no connections");
    }

    pageTitle = "Add Remote Attachment to "+ngp.getFullName();
    ar.assertMember("Can not attach a document to this project.");


    String fid = ar.defParam("fid","");
    String go =  ar.defParam("go","");
    String atype = ar.defParam("atype", "PUB");
    String comment = ar.defParam("comment", "");
    String dname = ar.defParam("name", "");
    String rlink = ar.defParam("rlink", "");
    String folderId = ar.defParam("folderId", dfolderid);

    if(fid !=null && fid.length() > 0){
        int indx = fid.indexOf('/');
        if (indx > 0) {
            folderId = fid.substring(0, indx);
            ConnectionType cType = uPage.getConnectionOrFail(folderId);
            rlink = cType.getFullPath(fid.substring(indx));
        }
    }

    if(dname.length()== 0 && rlink.length() > 0) {
        dname = rlink.substring(rlink.lastIndexOf('/') + 1);
    }

    String pubChecked = "";
    String memChecked = "";

    if("PUB".equals(atype)){
        pubChecked = "checked";
    }else{
        memChecked = "checked";;
    }%>

<%@ include file="Header.jsp"%>

<h1>Link to a Document in a Repository</h1>

<p>Use this form to make a link to a file in an external document repository.
   Members of this project will be able to access from this project, and will
   be able to synchronize with the document in the respository.</p>

<table width="600">
<col width="150">
<col width="470">
<form action="RemoteAttachmentAction.jsp" method="POST">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<input type="hidden" name="go"       value="<%ar.writeHtml(go);%>"/>

<tr>
  <td>
    Document URL:
  </td>
  <td>
    <input type="text"   name="rlink"  value="<%ar.writeHtml(rlink);%>" size="60"/>
  </td>
  <td>
      <input type=button name="Browse" value="Browse" onClick="parent.location='FolderDisplay.jsp?p=<%ar.writeHtml(p);%>&action=attach'"/>
  </td>
</tr>
<tr>
  <td>
    Repository:
  </td>
  <td>
    <select name="folderId">
<%
    for(ConnectionSetting cSet : connectionList){
        String folderName = cSet.getDisplayName();
        String lfid = cSet.getId();
        String selected = "";
        if(lfid.equals(folderId))
            selected = "selected=\"selected\"";
%>
        <option value="<%ar.writeHtml(lfid);%>" <%=selected%> ><%ar.writeHtml(folderName);%></option>
<%
    }
%>
    </select> Document URL must be within a connected repository.<br/>
    Visit your profile to make connections to document respositories.
  </td>
</tr>
<tr>
  <td>
    Description of<br/>
    Linked Document:
  </td>
  <td>
    <textarea name="comment" id="comment" style="WIDTH:95%;"><%ar.writeHtml(comment);%></textarea>
  </td>
</tr>
<tr>
  <td>Accessibility:</td>
  <td>
        <input type="radio" name="atype" value="*PUB*" checked="<%=pubChecked%>" /> Public
        <input type="radio" name="atype" value="*MEM*" checked="<%=memChecked%>" /> Member Only

  </td>
</tr>
<input type="hidden"  name="ftype" value="FILE">




<tr>
  <td>
    Access Name:
  </td>
  <td>
    <input type="text"   name="name"  value="<%ar.writeHtml(dname);%>" size="60"/>
  </td>
</tr>
<tr>
  <td></td><td>
    <input type="submit" name="action" value="Link Document" />
  </td>
</tr>
</form>
</table>

<br/> <br/>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
