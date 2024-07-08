<%@page import="com.purplehillsbooks.weaver.exception.NGException"
%><%@page import="com.purplehillsbooks.weaver.exception.ProgramLogicError"
%><%@page import="com.purplehillsbooks.weaver.AddressListEntry"
%><%@page import="com.purplehillsbooks.weaver.AttachmentRecord"
%><%@page import="com.purplehillsbooks.weaver.AuthRequest"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%@page import="com.purplehillsbooks.weaver.DOMFace"
%><%@page import="com.purplehillsbooks.weaver.HistoryRecord"
%><%@page import="com.purplehillsbooks.weaver.TopicRecord"
%><%@page import="com.purplehillsbooks.weaver.LeafletResponseRecord"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.LicensedURL"
%><%@page import="com.purplehillsbooks.weaver.NGBook"
%><%@page import="com.purplehillsbooks.weaver.NGContainer"
%><%@page import="com.purplehillsbooks.weaver.NGPage"
%><%@page import="com.purplehillsbooks.weaver.NGPageIndex"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.NGSection"
%><%@page import="com.purplehillsbooks.weaver.SectionAttachments"
%><%@page import="com.purplehillsbooks.weaver.SectionDef"
%><%@page import="com.purplehillsbooks.weaver.SectionTask"
%><%@page import="com.purplehillsbooks.weaver.SectionUtil"
%><%@page import="com.purplehillsbooks.weaver.UserManager"
%><%@page import="com.purplehillsbooks.weaver.UserPage"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%@page import="com.purplehillsbooks.weaver.UtilityMethods"
%><%@page import="com.purplehillsbooks.weaver.WikiConverter"
%><%@page import="com.purplehillsbooks.weaver.WikiConverterForWYSIWYG"
%><%@page import="java.io.File"
%><%@page import="java.io.Writer"
%><%@page import="java.io.Writer"
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


%>
