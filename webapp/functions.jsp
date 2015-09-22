<%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.AddressListEntry"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.EmailSender"
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
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionAttachments"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFolders"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionTask"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UserRef"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WikiConverter"
%><%@page import="org.socialbiz.cog.dms.ConnectionSettings"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.dms.ResourceEntity"
%><%@page import="org.socialbiz.cog.spring.NGWebUtils"
%><%@page import="java.io.File"
%><%@page import="java.io.Writer"
%><%@page import="java.io.Writer"
%><%@page import="java.lang.StringBuffer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Date"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.List"
%><%@page import="java.util.Properties"
%><%@page import="java.util.StringTokenizer"
%><%@page import="java.util.Vector"
%><%!private NGPage ngp = null;
    private NGBook ngb = null;


    boolean needTomcatKludge = false;

    public void setTomcatKludge(HttpServletRequest request)
    {
        //here we are testing is TomCat is configured correctly.  If it is this value
        //will be received uncorrupted.  If not, we will attempt to correct things by
        //doing an additional decoding
        String encodingGuard = request.getParameter("encodingGuard");
        needTomcatKludge = !(encodingGuard==null || "\u6771\u4eac".equals(encodingGuard));
    }


    public int defParamInt(AuthRequest ar,
        String paramName, int defaultValue)
        throws Exception
    {
        String val = ar.defParam(paramName, null);
        if (val == null) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(val);
        }
        catch (Exception e) {
            return defaultValue;
        }
    }


    public long defParamLong(AuthRequest ar,
        String paramName,
        long defaultValue)
        throws Exception
    {
        String val = ar.defParam(paramName, null);
        if (val == null) {
            return defaultValue;
        }
        try {
            return DOMFace.safeConvertLong(val);
        }
        catch (Exception e) {
            return defaultValue;
        }
    }


    static public String formateDate(long timestamp, String format) throws Exception
    {
        if (timestamp==0){
            return "";
        }
        Date date = new Date(timestamp);
        SimpleDateFormat  sFormat = new SimpleDateFormat(format);
        return sFormat.format(date);

    }

    public static String getUserFullNameList()
    {
        return UserManager.getUserFullNameList();
    }


    public static String pasreFullname(String fullNames) throws Exception {
        String assigness = "";
        String[] fullnames = UtilityMethods.splitOnDelimiter(fullNames, ',');
        for(int i=0; i<fullnames.length; i++){
            String fname = fullnames[i];
            int bindx = fname.indexOf('<');
            int length = fname.length();
            if(bindx > 0){
                fname = fname.substring(bindx+1,length-1);
            }
            assigness = assigness + "," + fname;

        }
        if(assigness.startsWith(",")){
            assigness = assigness.substring(1);
        }
        return assigness;
    }

    private void writeLeaflets(NGPage ngp, AuthRequest ar, int accessLevel)
        throws Exception
    {
        ar.write("\n <div class=\"section\"> ");

        ar.write("\n     <div class=\"section_title\"> ");
        ar.write("\n         <h1 class=\"left\"><b> Topics </a></b></h1> ");

        ar.write("\n         <div class=\"section_date right\">");
        ar.write("</div> ");

        ar.write("\n         <div class=\"clearer\">&nbsp;</div> ");
        ar.write("\n     </div> ");

        ar.write("\n     <div class=\"section_body\"> ");
        List<NoteRecord> vizComments = ngp.getVisibleNotes(ar, accessLevel);

        int i = -1;
        for (NoteRecord cr : vizComments) {
            i++;
            int commentLevel = cr.getVisibility();
            if (commentLevel != accessLevel) {
                throw new Exception(
                        "Hmmm, get visible comments not working quite right because I should not see an element at a different visibility level at this point.");
            }
            displayOldLeaflet(ar, ngp, cr, i);
        }


        ar.write("\n     </div> ");
        ar.write("\n </div> ");

        ar.flush();
    }


    /**
     * displayOldLeaflet will display a single comment record. index "i" denotes
     * the index on the page, when there are multiple entries on the page. This
     * is important for being able to open and close the sections. Pass a -1 for
     * the index to disable this, and leave it only open and without controls
     * for opening or zooming.
     */
    public void displayOldLeaflet(AuthRequest ar, NGPage ngp, NoteRecord cr, int i) throws Exception {
        UserProfile uProf = ar.getUserProfile();
        boolean canEdit = false;
        UserRef lastModifiedBy = cr.getModUser();
        String owner = lastModifiedBy.getName();
        long cTime = cr.getLastEdited();
        long effDime = cr.getEffectiveDate();

        if (!ar.isLoggedIn() || ar.isStaticSite() || uProf==null) {
            canEdit = false;
        } else if (ngp.secondaryPermission(uProf)) {
            canEdit = true;
        } else if (uProf.hasAnyId(owner)) {
            canEdit = true;
        } else if (ngp.primaryOrSecondaryPermission(uProf)) {
            canEdit = true;
        }

        String subject = cr.getSubject();
        if (subject == null || subject.length() == 0) {
            subject = "No Subject";
        }

        String divid = "comment-" + i;
        ar.write("\n<h1>");
        if (i >= 0) {
            String javascript1 = "showHideCommnets('" + divid + "')";
            ar.write("<a href=\"javascript:");
            ar.writeHtml(javascript1);
            ar.write("\" title=\"Click to show or hide the topic body\">");
            ar.writeHtml(subject);
            ar.write("</a><img src=\"");
            ar.write(ar.retPath);
            ar.write("but_process_view.gif\" height=\"18\" width=\"18\"");
            ar.write(" onclick=\"");
            ar.writeHtml(javascript1);
            ar.write("\"/> ");
        } else {
            ar.writeHtml(subject);
        }

        if (canEdit) {
            String editUrl = ar.retPath + "EditLeaflet.jsp?p="
                    + SectionUtil.encodeURLData(ngp.getKey()) + "&oid="
                    + SectionUtil.encodeURLData(cr.getId())
                    + "&action=Edit&go="
                    + SectionUtil.encodeURLData(ar.getRequestURL());
            ar.write("\n<a href=\"");
            ar.writeHtml(editUrl);
            ar.write("\" title=\"Edit this topic\"  target=\"_blank\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("edittexticon.gif\"/></a>");
        }

        ar.write("</h1>");

        ar.write("\n<div id=\"");
        ar.write(divid); // this does not need encoding
        ar.write("\" style=\"display:block\">");
        WikiConverter.writeWikiAsHtml(ar, cr.getWiki().trim());
        ar.write("\n<div  class=\"section_metadata\"><div  class=\"content\">Last edited by ");
        UserProfile.writeLink(ar, cr.getModUser().getUniversalId());
        ar.write(" ");
        SectionUtil.nicePrintTime(ar, cTime, ar.nowTime);
        ar.write("\n- Owned by ");
        UserProfile.writeLink(ar, owner);
        ar.write(" ");
        long pin = cr.getPinOrder();
        if (pin > 0) {
            ar.write("(<i>Pinned at position ");
            ar.write(Long.toString(pin));
            ar.write("</i>)");
        } else {
            ar.write("(<i>Effective date ");
            SectionUtil.nicePrintTime(ar, cr.getEffectiveDate(), ar.nowTime);
            ar.write("</i>)");
        }
        ar.write(" viz="+cr.getVisibility());
        ar.write("\n</div></div>");

        ar.write("\n</div>");
        ar.write("<hr/>");
    }





    /**
     * Returns only valid alphanumeric characters of the input String.
     * Any characters outside the ASCII character set (greater than 127)
     * used to be returned unchanged (version 7.2 and earlier) but now
     * characters > 127 are excluded.  This is because JavaScript variable
     * rules (sanitized names are used for JS variables as well as form
     * variable names) require only alphanumeric and underscore.
     *
     * @param s The input String to be translated to pure alphanumeric String.
     * @return The String after removing all non-alphanumeric characters.
     */
    public static String getSanitizedString(String s) {
        StringBuffer sOut = null;
        if (s == null) {
            return null;
        }
        if (s.length() == 0) {
            return "";
        }

        int ilen = s.length();
        sOut = new StringBuffer(ilen);
        char c;
        for (int i = 0; i<ilen; i++)
        {
            c = s.charAt(i);
            if (c == '_'                ||  // underscore
                (c >= 'A' && c <= 'Z')  ||  // uppercase letters
                (c >= 'a' && c <= 'z')  ||  // lowercase letters
                (c >= '0' && c <= '9'))     // numerals
            {
                sOut.append(c);
            }
        }
        return sOut.toString();
    }


    public UserProfile findSpecifiedUserOrDefault(AuthRequest ar)
        throws Exception
    {
        String u = ar.defParam("u", null);
        UserProfile up = null;
        if (u!=null)
        {
            up = UserManager.getUserProfileByKey(u);
            if (up==null)
            {
                Thread.sleep(3000);
                throw new Exception("Can not find a user with key = '"+u+"'.  This page requires a valid key.");
            }
        }
        else
        {
            if (!ar.isLoggedIn())
            {
                return null;
            }
            up = ar.getUserProfile();

            //every logged in user should have a profile, so should never hit this
            if (up == null)
            {
                throw new Exception("every logged in user should have a profile, why is it missing in this case?");
            }
        }
        return up;
    }

    public void headlinePath(AuthRequest ar, String localName)
        throws Exception
    {
        ar.write("\n<div class=\"pagenavigation\">");
        ar.write("\n<div class=\"pagenav\">");
        ar.write("\n<div class=\"left\">");
        if (ngb!=null)
        {
            ar.writeHtml(ngb.getFullName());
        }
        ar.write(" &raquo; ");
        if (ngp!=null)
        {
            ar.writeHtml(ngp.getFullName());
        }
        ar.write(" &raquo; ");
        ar.writeHtml(localName);
        ar.write("\n</div>");
        ar.write("\n<div class=\"right\"></div>");
        ar.write("\n<div class=\"clearer\">&nbsp;</div>");
        ar.write("\n</div>");
        ar.write("\n<div class=\"pagenav_bottom\"></div>");
        ar.write("\n</div>");
    }


    public String redirectToViewLevel(AuthRequest ar, NGPage ngp, int viewLevel)
        throws Exception
    {
        if (viewLevel==SectionDef.MEMBER_ACCESS)
        {
            return ar.getResourceURL(ngp,"member.htm");
        }
        if (viewLevel==SectionDef.ADMIN_ACCESS)
        {
            return  ar.getResourceURL(ngp,"admin.htm");
        }
        if (viewLevel==SectionDef.PRIVATE_ACCESS)
        {
            return ar.getResourceURL(ngp,"private.htm");
        }
        return ar.getResourceURL(ngp,"public.htm");
    }


    public static int writeOutUsers(AuthRequest ar, List<AddressListEntry> users, int level,
            String label, int limit, String b)  throws Exception
    {
        int actorLevel = 0;
        if (ar.isAdmin())
        {
            actorLevel = 4;
        }
        else if (ar.isMember())
        {
            actorLevel = 2;
        }
        boolean demote = actorLevel >= level;
        boolean promote = actorLevel > level;
        if (users.size()==0)
        {
            //don't output anything if the vector is empty
            return 0;
        }
        ar.write("<tr><td colspan=\"2\">");
        ar.writeHtml(label);
        ar.write("</td></tr>\n");
        int count = 0;
        for (AddressListEntry ale : users)
        {
            String userName = ale.getName();
            boolean isMe = ar.isMe(userName);
            int demoteLevel = 0;
            if (level>2)
            {
                demoteLevel = 2;
            }
            ar.write("<tr><td width=\"100\">&nbsp;</td><td>");
            ale.writeLink(ar);
            ar.write("</td>");
            if (promote)
            {
                ar.write("</td><form action=\"BookMemberAction.jsp\">");
                ar.write("<input type=\"hidden\" name=\"b\" value=\"");
                ar.writeHtml(b);
                ar.write("\"><input type=\"hidden\" name=\"level\" value=\"");
                ar.write(Integer.toString(level+1));
                ar.write("\">");
                ar.write("<input type=\"hidden\" name=\"userid\" value=\"");
                ar.writeHtml(userName);
                ar.write("\"><td><input type=\"submit\" value=\"Promote");
                if (isMe)
                {
                    ar.write(" (you)");
                }
                ar.write("\"></td></form>");
            }
            if (demote)
            {
                ar.write("<form action=\"BookMemberAction.jsp\">");
                ar.write("<input type=\"hidden\" name=\"b\" value=\"");
                ar.writeHtml(b);
                ar.write("\"><input type=\"hidden\" name=\"level\" value=\"");
                ar.write(Integer.toString(demoteLevel));
                ar.write("\">");
                ar.write("<input type=\"hidden\" name=\"userid\" value=\"");
                ar.writeHtml(userName);
                ar.write("\"><td><input type=\"submit\" value=\"Remove");
                if (isMe)
                {
                    ar.write(" (you)");
                }
                ar.write("\"></td></form>");
            }
            ar.write("</tr>\n");
            count++;
        }
        if (count==0)
        {
            ar.write("<tr><td></td><td>- none -</td></tr>\n");
        }
        return count;
    }


    public void appendUsersF(List<AddressListEntry> members, Vector<AddressListEntry> collector)
        throws Exception
    {
        for (AddressListEntry ale : members)
        {
            Enumeration e2 = collector.elements();
            boolean found = false;
            while (e2.hasMoreElements())
            {
                AddressListEntry coll = (AddressListEntry)e2.nextElement();
                if (coll.hasAnyId(ale.getUniversalId()))
                {
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                collector.add(ale);
            }
        }
    }


    public static void writeLeafletEmailBody(AuthRequest ar, NGPage ngp, NoteRecord leaflet,
            boolean tempmem, AddressListEntry ale, String note, boolean includeBody)
        throws Exception
    {
        String pageURL    = ar.retPath + ar.getResourceURL(ngp, "");
        String lic = "";
        if (tempmem)
        {
            License lobj = ngp.getProcess().accessLicense();
            lic = lobj.getId();
            pageURL     = LicensedURL.addLicense(pageURL, lic);
        }
        ar.write("<p>Note From ");
        ar.getUserProfile().writeLink(ar);
        ar.write("</p>");
        ar.write("\n<p>");
        ar.writeHtml(note);
        List<AttachmentRecord> selAtt = NGWebUtils.getSelectedAttachments(ar, ngp);
        if (selAtt.size()>0)
        {
            ar.write("</p>");
            ar.write("\n<p><b>Attachments:</b> (click links for secure access to documents)<ul> ");
            for (AttachmentRecord att : selAtt)
            {
                ar.write("<li><a href=\"");
                ar.write(ar.retPath);
                ar.write("AccessAttachment.jsp?p=");
                ar.writeURLData(ngp.getKey());
                ar.write("&aid=");
                ar.writeURLData(att.getId());
                ar.write("\">");
                ar.writeHtml(att.getNiceName());
                ar.write("</a></li> ");
            }
            ar.write("</ul></p>");
        }


        if (leaflet!=null)
        {
            String leafletURL = ar.retPath + ar.getResourceURL(ngp, leaflet);
            if (tempmem)
            {
                leafletURL  = LicensedURL.addLicense(leafletURL, lic);
            }
            if (includeBody)
            {
                ar.write("\n<p><font color=\"blue\"><i>The web page is copied below.  You can access the most recent, ");
                ar.write("most up to date version on the web at the following link: <a href=\"");
                ar.write(leafletURL);
                ar.write("\" title=\"Access the latest version of this message\">");
                ar.writeHtml(leaflet.getSubject());
                ar.write("</a></i></font></p>");
                ar.write("\n<hr/>\n");

                WikiConverter.writeWikiAsHtml(ar, leaflet.getWiki());
                ar.write("\n<hr/>");
            }
            else
            {
                ar.write("\n<p><font color=\"blue\"><i>Access the web page using the following link: <a href=\"");
                ar.write(leafletURL);
                ar.write("\" title=\"Access the latest version of this message\">");
                ar.writeHtml(leaflet.getSubject());
                ar.write("</a></i></font></p>");
                ar.write("\n<hr/>\n");
            }

            String choices = leaflet.getChoices();
            String[] choiceArray = UtilityMethods.splitOnDelimiter(choices, ',');
            String userData = "";
            String userChoice = "";

            UserProfile up = ale.getUserProfile();
            if (up!=null && choiceArray.length>0)
            {
                LeafletResponseRecord llr = leaflet.getOrCreateUserResponse(up);
                userData = llr.getData();
                userChoice = llr.getChoice();
            }
            if (choiceArray.length>0 & includeBody)
            {
                ar.write("<form method=\"post\" action=\"");
                ar.write(ar.retPath);
                ar.write("LeafletResponseAction.jsp\">\n<input type=\"hidden\" name=\"p\" value=\"");
                ar.writeHtml(ngp.getKey());
                ar.write("\">\n<input type=\"hidden\" name=\"lid\" value=\"");
                ar.writeHtml(leaflet.getId());
                ar.write("\">\n<input type=\"hidden\" name=\"lic\" value=\"");
                ar.writeHtml(lic);
                ar.write("\">\n<input type=\"hidden\" name=\"uid\" value=\"");
                ar.writeHtml(ale.getUniversalId());
                ar.write("\">\n<input type=\"hidden\" name=\"go\" value=\"");
                ar.writeHtml(ar.getResourceURL(ngp,leaflet));
                ar.write("\">");
                ar.write("<p><font color=\"blue\"><i>You may use this form to respond.  On email clients ");
                ar.write("that do not display forms, you must use the <a href=\"");
                ar.write(leafletURL);
                ar.write("#Response\" title=\"Response form on the web\">web page</a> to respond.</i></font></p>");
                ar.write("\n<table>");
                ar.write("\n<tr><td>Response</td><td>");

                for (String ach : choiceArray)
                {
                    String isChecked = "";
                    if (ach.equals(userChoice)) {
                        isChecked = " checked=\"checked\"";
                    }
                    ar.write("<input type=\"submit\" name=\"choice\"");
                    ar.write(" value=\"");
                    ar.writeHtml(ach);
                    ar.write("\">");
                    ar.write(" &nbsp; ");
                }
                ar.write("</td></tr>");
                ar.write("<tr><td>Reason / <br/>Comment</td><td><textarea name=\"data\">");
                ar.writeHtml(userData);
                ar.write("</textarea></td></tr>");
                ar.write("<tr><td>User ID:</td><td><input type=\"text\" name=\"uid\" value=\"");
                ar.writeHtml(ale.getUniversalId());
                ar.write("\" size=\"50\"></td></tr>");
                ar.write("<tr><td></td><td><input type=\"hidden\" name=\"action\" value=\"Update Your Response\"></td></tr>");
                ar.write("</table>");
                ar.write("</form>");
            }
        }
    }



    public static void writeInviteEmail(AuthRequest ar, NGPage ngp, NGRole ngr, UserRef ale)
        throws Exception
    {
        String pageURL    = ar.retPath + ar.getResourceURL(ngp, "");
        ProcessRecord process = ngp.getProcess();
        ar.write("<p>You are invited to the ");
        ar.writeHtml(ngr.getName());
        ar.write(" role for the ");
        ar.writeHtml(ngp.getFullName());
        ar.write("  project. </p>");
        ar.write("\n<p>The goal of this project is:</p><ul><li>");
        ar.writeHtml(process.getSynopsis());
        ar.write("</li></ul>\n<p>The purpose of this project is: </p><ul><li>");
        ar.writeHtml(process.getDescription());
        ar.write("</li></ul>\n<p>");
        ar.writeHtml(ngr.getName());
        ar.write(" are expected to: </p><ul><li>");
        ar.writeHtml(ngr.getRequirements());
        ar.write("</li></ul>");
    }



    /**
    * Strange function.  If you have an openid, this will return an email address for
    * that user if one is known.  If you have an email, it will return the openid
    * for that user if one is known.  In all other cases a zero length string is returned.
    */
    public String getPossibleOtherId(String possibleId)
    {
        if (possibleId==null)
        {
            return "";
        }
        UserProfile up = UserManager.findUserByAnyId(possibleId);
        if (up==null)
        {
            return "";
        }

        boolean isEmail = (possibleId.indexOf('@')>0);
        if (isEmail)
        {
            String testOpenId = up.getOpenId();
            if (testOpenId!=null)
            {
                return testOpenId;
            }
        }
        else
        {
            String testEmail = up.getPreferredEmail();
            if (testEmail!=null)
            {
                return testEmail;
            }
        }
        return "";
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
    private void writeTitleAttribute(AuthRequest ar, String name, int maxsize)
        throws Exception
    {
        if (name.endsWith("/")) {
            name = name.substring(0, name.length() - 1);
        }
        if (name.length() > maxsize) {
            ar.write(" title=\"");
            ar.writeHtml(name);
            ar.write("\"");
        }
    }


    //standard way to guarantee that there are no any old calls passing useless parameters
    public void assureNoParameter(AuthRequest ar, String paramName)
        throws Exception
    {
        String val = ar.defParam(paramName, null);
        if (val!=null)
        {
            throw new Exception("Program logic error: you no longer need to specify a '"+paramName+"' parameter on page: "
              +ar.getRequestURL() +" (had value: "+val+")");
        }
    }


    //don't need this method any more
    public static boolean isMember(AuthRequest ar, NGContainer ngc)
            throws Exception {
        return ar.isMember();
    }
    //don't need this method any more
    public static boolean isAdmin(AuthRequest ar, NGContainer ngc)
            throws Exception {
        return ar.isAdmin();
    }


    public static void mustBeLoggedInMessage(AuthRequest ar)
        throws Exception
    {
        ar.write("<div class=\"pagenavigation\">");
        ar.write("\n<div class=\"pagenav\">");
        ar.write("\n  <div class=\"left\">");
        ar.write("\n    You must be logged in to see this tab.");
        ar.write("\n  </div>");
        ar.write("\n  <div class=\"right\"></div>");
        ar.write("\n  <div class=\"clearer\">&nbsp;</div>");
        ar.write("\n</div>");
        ar.write("\n<div class=\"pagenav_bottom\"></div>");
        ar.write("\n</div>");
    }

    public static void mustBeMemberMessage(AuthRequest ar)
        throws Exception
    {
        ar.write("<div class=\"pagenavigation\">");
        ar.write("\n<div class=\"pagenav\">");
        ar.write("\n  <div class=\"left\">");
        ar.write("\n    You must be a member to see this tab.");
        ar.write("\n  </div>");
        ar.write("\n  <div class=\"right\"></div>");
        ar.write("\n  <div class=\"clearer\">&nbsp;</div>");
        ar.write("\n</div>");
        ar.write("\n<div class=\"pagenav_bottom\"></div>");
        ar.write("\n</div>");
    }

    public static void requestMemberButton(AuthRequest ar, NGContainer ngc, UserProfile uProf)
        throws Exception
    {
        requestRoleButton(ar, ngc, uProf, "Member");
    }
    public static void requestAdminButton(AuthRequest ar, NGContainer ngc, UserProfile uProf)
        throws Exception
    {
        requestRoleButton(ar, ngc, uProf, "Administrator");
    }
    public static void requestRoleButton(AuthRequest ar, NGContainer ngc, UserProfile uProf, String roleName)
        throws Exception
    {
        ar.write("\n<form action=\"");
        ar.write(ar.retPath);
        ar.write("RoleAction.jsp\" method=\"post\">");
        ar.write("\n<input type=\"submit\" value=\"Request to be ");
        ar.writeHtml(roleName);
        ar.write("\"/>");
        ar.write("\n<input type=\"hidden\" name=\"p\" value=\"");
        ar.writeHtml(ngc.getKey());
        ar.write("\"/>");
        ar.write("\n<input type=\"hidden\" name=\"r\" value=\"");
        ar.writeHtml(roleName);
        ar.write("s\"/>");
        ar.write("\n<input type=\"hidden\" name=\"u\" value=\"");
        ar.writeHtml(uProf.getUniversalId());
        ar.write("\"/>");
        ar.write("\n<input type=\"hidden\" name=\"op\" value=\"add\"/>");
        ar.write("\n<input type=\"hidden\" name=\"go\" value=\"");
        ar.writeHtml(ar.getRequestURL());
        ar.write("\"/>");
        ar.write("</form>");
    }


    private void displayHeader(AuthRequest ar, ResourceEntity ent, String pageId)throws Exception {
        ar.write("Repository Folder: ");
        String symbol = ent.getSymbol();
        int indx = symbol.indexOf('/');
        String relPath = symbol.substring(0, indx);
        String folderId = symbol.substring(indx);

        String fdname = ent.getDisplayName();
        int indx2 = fdname.indexOf('/');
        if (indx2 > 0) {
            fdname = fdname.substring(0, indx2);
        }

        String dname = fdname;
        String dlink = ar.retPath + "FolderDisplay.jsp?symbol="
            + URLEncoder.encode(symbol, "UTF-8");

        if(pageId != null){
            dlink = dlink + "&p=" + URLEncoder.encode(pageId, "UTF-8");
        }

        ar.write("  <a href=\"");
        ar.writeHtml(dlink);
        ar.write("\">");
        ar.writeHtml(dname);
        ar.write("</a>");

        if (folderId != null) {
            StringTokenizer st = new StringTokenizer(folderId, "/");
            while (st.hasMoreTokens()) {
                String tok = st.nextToken();
                dlink = dlink + "/" + URLEncoder.encode(tok, "UTF-8");
                ar.write("/");
                ar.write("<a href=\"");
                ar.writeHtml(dlink);
                if (folderId.endsWith("/"))
                    ar.writeHtml("/");
                ar.write("\">" + tok + "</a>");
            }
        }

    }


         public void displayRepositoryList(AuthRequest ar, String pageId)
                throws Exception {
        try {
            Writer out = ar.w;

            UserPage uPage = ar.getUserPage();
            ar.write("<table class=\"Design8\" width=\"98%\" id=\"folderTable\">");
            ar.write("<col width=\"300\"/>");
            ar.write("<col width=\"300\"/>");

            for (ConnectionSettings cSet : uPage.getAllConnectionSettings()) {

                ar.write("\n<tr>");
                ar.write("\n  <td align=\"left\">");
                ar.write("\n  <h3>");

                String dname = getShortName(cSet.getDisplayName(), 38);

                // note the slash for the root directory of the connection
                String fdLink = ar.retPath + "FolderDisplay.jsp?symbol="
                   + URLEncoder.encode(cSet.getId(), "UTF-8")
                   + "/&p=" + URLEncoder.encode(pageId, "UTF-8");

                ar.write("  <a href=\"");
                ar.writeHtml(fdLink);
                ar.write("\"");
                writeTitleAttribute(ar, cSet.getDisplayName(), 38);
                ar.write("><img allign=\"absbottom\" src=\"");
                ar.write(ar.retPath);
                ar.write("cfolder.gif");
                ar.write("\">");
                ar.writeHtml(dname);
                ar.write("</a>");
                ar.write("\n  </td>");
                ar.write("\n</tr>");
            }
            ar.write("</table>");
        } catch (Exception e) {
            throw new Exception("Unable to display root folders for project "+pageId, e);
        }

    }



    //used by header and pages to redirect to new UI
    public String getNewURL(AuthRequest ar, String resource)
    {
        return ar.baseURL+"t/"+ngb.getKey()+"/"+ngp.getKey()+"/"+resource;
    }


    private String composeFromAddress(NGPage ngp) throws Exception
    {
        StringBuffer sb = new StringBuffer("^");
        String baseName = ngp.getFullName();
        int last = baseName.length();
        for (int i=0; i<last; i++)
        {
            char ch = baseName.charAt(i);
            if ( (ch>='0' && ch<='9') || (ch>='A' && ch<='Z') || (ch>='a' && ch<='z') || (ch==' '))
            {
                sb.append(ch);
            }
        }
        String baseEmail = EmailSender.getProperty("mail.smtp.from", "xyz@example.com");

        //if there is angle brackets, take the quantity within the angle brackets
        int anglePos = baseEmail.indexOf("<");
        if (anglePos>=0)
        {
            baseEmail = baseEmail.substring(anglePos+1);
        }
        anglePos = baseEmail.indexOf(">");
        if (anglePos>=0)
        {
            baseEmail = baseEmail.substring(0, anglePos);
        }

        //now add email address in angle brackets
        sb.append(" <");
        sb.append(baseEmail);
        sb.append(">");
        return sb.toString();
    }%>
