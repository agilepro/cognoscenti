<%@page import="org.socialbiz.cog.exception.NGException"
%><%@page import="org.socialbiz.cog.exception.ProgramLogicError"
%><%@page import="org.socialbiz.cog.AddressListEntry"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NoteRecord"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGContainer"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionAttachments"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionTask"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WikiConverter"
%><%@page import="org.socialbiz.cog.WikiConverterForWYSIWYG"
%><%@page import="org.socialbiz.cog.dms.ConnectionSettings"
%><%@page import="org.socialbiz.cog.dms.ConnectionType"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.dms.ResourceEntity"
%><%@page import="java.io.File"
%><%@page import="java.io.Writer"
%><%@page import="java.io.Writer"
%><%@page import="java.lang.StringBuffer"
%><%@page import="java.lang.StringBuffer"
%><%@page import="java.net.URLDecoder"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Date"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.HashMap"
%><%@page import="java.util.Iterator"
%><%@page import="java.util.List"
%><%@page import="java.util.Map"
%><%@page import="java.util.Properties"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Vector"
%><%

/*

functions.jsp provides useful java functions for the pages
It does NOT produce any output by itself.

*/

%><%!

    int count=100;
    private NGContainer ngp = null;
    private NGBook ngb = null;
    private boolean firstLeafLet = true;

    public static void writeHtml(Writer out, String t)
    throws Exception
    {
        if (t==null) {
            return;  //treat it like an empty string
        }
        for (int i=0; i<t.length(); i++) {

            char c = t.charAt(i);
            switch (c) {
                case '&':
                    out.write("&amp;");
                    continue;
                case '<':
                    out.write("&lt;");
                    continue;
                case '>':
                    out.write("&gt;");
                    continue;
                case '"':
                    out.write("&quot;");
                    continue;
                default:
                    out.write(c);
                    continue;
            }
        }
    }

    boolean needTomcatKludge = false;
    public String defParam(HttpServletRequest request,
        String paramName,
        String defaultValue)
        throws Exception
    {
        String val = request.getParameter(paramName);
        if (val!=null)
        {
            // this next line should not be needed, but I have seen this hack recommended
            // in many forums.  See setTomcatKludge() above.
            if (needTomcatKludge)
            {
                val = new String(val.getBytes("iso-8859-1"), "UTF-8");
            }
            return val;
        }

        //try and see if it a request attribute
        val = (String)request.getAttribute(paramName);
        if (val != null)
        {
            return val;
        }

        return defaultValue;
    }


    public String getProjectRootURL(AuthRequest ar, NGPage ngp) {
        NGBook site = ngp.getSite();
        String pageRootURL = ar.retPath + "t/"+site.getKey()+"/"+ngp.getKey()+"/";
        return pageRootURL;
    }
    public String getNoteEditorURL(AuthRequest ar, NGContainer ngc, String noteId) throws Exception  {
        return ar.retPath + ar.getResourceURL(ngc, "editNote.htm")+"?nid=" + noteId;
    }
    public String getNoteCreatorURL(AuthRequest ar, NGContainer ngc, boolean isPublic)  throws Exception  {
        return ar.retPath + ar.getResourceURL(ngc, "editNote.htm") + "?public=" + isPublic;
    }



    private String getShortName(String name, int maxsize) {
        if (name.endsWith("/")) {
            name = name.substring(0, name.length() - 1);
        }
        if (name.length() > maxsize) {
            name = name.substring(0, maxsize - 3) + "...";
        }

        return name;

    }

    /**
    * Creates a title attribute of a HTML element only if the name is longer than
    * a specified amount.
    */
    private void writeTitleAttribute(AuthRequest ar, String name, int maxsize) throws Exception {
        if (name.endsWith("/")) {
            name = name.substring(0, name.length() - 1);
        }
        if (name.length() > maxsize) {
            ar.write(" title=\"");
            ar.writeHtml(name);
            ar.write("\"");
        }
    }



    //Recursive routine to handle variable number of parent folders
    private void createFolderLinks(AuthRequest ar, ResourceEntity ent) throws Exception
    {
        ResourceEntity parent = ent.getParent();
        if (parent!=null) {
            createFolderLinks(ar, parent);
            String dlink = ar.retPath + "v/"+ ar.getUserProfile().getKey() + "/folder"+ent.getFolderId()
                +".htm?path=" + URLEncoder.encode(ent.getPath()+"/", "UTF-8")
                +"&encodingGuard=%E6%9D%B1%E4%BA%AC";
            ar.write("&nbsp;&nbsp;&gt;&nbsp;&nbsp;<a href=\"");
            ar.writeHtml(dlink);
            ar.write("\">");
            ar.writeHtml(ent.getDecodedName());
            ar.write("</a>");
        }
    }%>
