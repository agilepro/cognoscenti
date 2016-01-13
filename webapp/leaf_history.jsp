<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    String p = ar.reqParam("p");
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    String go = ar.defParam("go", null);
    if (go==null)
    {
        go = ar.getResourceURL(ngp,"");
    }

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName();
    specialTab = "Stream";
    newUIResource = "history.htm";%>

<%@ include file="Header.jsp"%>

<%
    headlinePath(ar, "History");
%>

<%
    if (!ar.isLoggedIn() && !ar.isStaticSite())
{
    mustBeLoggedInMessage(ar);
}
else if (!isMember && !isAdmin && !ar.isStaticSite())
{
    mustBeMemberMessage(ar);
}
else
{
%>

<br/>

<%
    if (!ar.isStaticSite()) {
%>
<h1>Workspace Status Update</h1>
<table>
<form action="<%=ar.retPath%>HistoryAction.jsp" method="post">
<input type="hidden" name="p" value="<%ar.writeHtml(p);%>"/>
<input type="hidden" name="go" value="<%ar.writeHtml(ar.getRequestURL());%>"/>
<tr><td>
<textarea name="status" cols="60" rows="3"></textarea>
</td></tr>
<tr><td>
<input type="submit" name="action" value="Update Status"/>
</td></tr>
</form>
</table>
<%
    }
%>

<div id="historydiv">
    <table id="history">
        <thead>
            <tr>
                <th>Pict</th>
                <th>History</th>
            </tr>
        </thead>
        <tbody>
<%

    // use this hashtable for "name" lookup.
    Hashtable<String,GoalRecord> taskHash = new Hashtable<String,GoalRecord>();
    for (GoalRecord task: ngp.getAllGoals())
    {
        taskHash.put(task.getId(), task);
    }

    List<HistoryRecord> histRecs = ngp.getAllHistory();

    for (HistoryRecord history : histRecs)
    {
        AddressListEntry ale = AddressListEntry.parseCombinedAddress(history.getResponsible());
        String shortName = SectionUtil.cleanName(history.getResponsible());
%>
        <tr>
            <td><img src="<%=ar.retPath%>blank_photo.gif"/></td><td>
                <%
                    //dummy link for the sorting purpose.
                ar.write("<a href=\"");
                ar.write(Long.toString(history.getTimeStamp()));
                ar.write("\"></a>");

                if (history.getComments() != null && history.getComments().length() > 0 )
                {
                    protectComment(ar, history.getComments());
                    ar.write(" -- \n");
                }

                if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_PROCESS)
                {
                    //no context is needed
                }
                else if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_TASK)
                {
                    if (!taskHash.containsKey(history.getContext()))
                    {
                        ar.write("Unknown goal");
                    }
                    else if (ar.isStaticSite())
                    {
                        GoalRecord task = (GoalRecord) taskHash.get(history.getContext());
                        ar.write("Action Item \"");
                        ar.writeHtml(task.getSynopsis());
                    }
                    else
                    {
                        GoalRecord task = (GoalRecord) taskHash.get(history.getContext());
                        String tname = task.getSynopsis();
                        ar.write("Action Item \"<a href=\"");
                        ar.write(ar.retPath);
                        ar.write("WorkItem.jsp?p=");
                        ar.writeURLData(ngp.getKey());
                        ar.write("&s=Tasks&id=");
                        ar.write(history.getContext());
                        ar.write("&go=");
                        ar.writeURLData(ar.retPath);
                        ar.write("p/");
                        ar.writeURLData(ngp.getKey());
                        ar.write("/history.htm\" title=\"view the task details\">");
                        if (tname.length()>20)
                        {
                            ar.write(tname.substring(0,19));
                            ar.write("...");
                        }
                        else
                        {
                            ar.writeHtml(tname);
                        }
                        ar.write("</a>");
                    }
                    ar.write("\" was ");
                    ar.writeHtml(HistoryRecord.convertEventTypeToString(history.getEventType()));
                }
                else if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_PERMISSIONS)
                {
                    ar.write("User \"");
                    AddressListEntry ale2 = AddressListEntry.parseCombinedAddress(history.getContext());
                    protectUserAddress(ar,ale2);
                    ar.write("\" was ");
                    ar.writeHtml(HistoryRecord.convertEventTypeToString(history.getEventType()));
                }
                else if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_ROLE)
                {
                    ar.write("User \"");
                    AddressListEntry ale2 = AddressListEntry.parseCombinedAddress(history.getContext());
                    protectUserAddress(ar,ale2);
                    ar.write("\" was ");
                    ar.writeHtml(HistoryRecord.convertEventTypeToString(history.getEventType()));
                }
                else if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_DOCUMENT)
                {
                    String docid = history.getContext();
                    AttachmentRecord att = ngp.findAttachmentByID(docid);
                    ar.write("Attachment \"");
                    if (att!=null)
                    {
                        ar.writeHtml(att.getNiceName());
                    }
                    else
                    {
                        ar.write("#");
                        ar.writeHtml(docid);
                    }
                    ar.write("\" was ");
                    ar.writeHtml(HistoryRecord.convertEventTypeToString(history.getEventType()));
                }
                else if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_LEAFLET)
                {
                    String lid = history.getContext();
                    NoteRecord leaflet = ngp.getNote(lid);
                    ar.write("Topic \"");
                    if (leaflet==null)
                    {
                        ar.write("#");
                        ar.writeHtml(lid);
                    }
                    else if (ar.isStaticSite())
                    {
                        ar.writeHtml(leaflet.getSubject());
                    }
                    else
                    {
                        leaflet.writeLink(ar, 60);
                    }
                    ar.write("\" was ");
                    ar.writeHtml(HistoryRecord.convertEventTypeToString(history.getEventType()));
                }
                else
                {
                    //no need to mention context
                }
                ar.write("\n<br/>");   //bring the name to the beginning of a new line
                protectUserAddress(ar,ale);
                ar.write("\n<br/>");   //bring the date to the beginning of a new line
                SectionUtil.nicePrintTime(ar, history.getTimeStamp(), ar.nowTime);
                %>
            </td>

        </tr>
<%
    }
%>
        </tbody>
    </table>
</div>
<br/>



<%
}  //end of access control block
%>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
<%!public void protectUserAddress(AuthRequest ar, AddressListEntry ale) throws Exception
{
    //special behavior exists only for static sites, so for non
    //static site, just write out an ALE link.
    if (!ar.isStaticSite())
    {
        ale.writeLink(ar);
    }

    //For static sites, print a name if one exists, but if it
    //looks like an email address, DONT put it in the static site!
    String name = ale.getName();
    int atPos = name.indexOf("@");
    if (atPos>0) {
        name = name.substring(0,atPos);
    }
    ar.writeHtml(name);
}

public void protectComment(AuthRequest ar, String comment) throws Exception
{
    //special behavior exists only for static sites, so for non
    //static site, just write out an ALE link.
    if (!ar.isStaticSite())
    {
        ar.writeHtml(comment);
    }

    //For static sites, check to see if there is an at sign in there.
    //if so, just don't print out the comment.  There were many comments
    //that contain a list of email addresses, so simply avoid the entire
    //comment if there is an at sign.
    int atPos = comment.indexOf("@");
    if (atPos<0) {
        ar.writeHtml(comment);
    }
}%>