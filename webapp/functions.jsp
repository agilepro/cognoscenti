<%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.AddressListEntry"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.TopicRecord"
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
%><%@page import="org.socialbiz.cog.mail.EmailSender"
%><%@page import="org.socialbiz.cog.dms.ConnectionSettings"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.dms.ResourceEntity"
%><%@page import="org.socialbiz.cog.spring.NGWebUtils"
%><%@page import="java.io.File"
%><%@page import="java.io.Writer"
%><%@page import="java.io.Writer"
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


    /**
     * displayOldLeaflet will display a single comment record. index "i" denotes
     * the index on the page, when there are multiple entries on the page. This
     * is important for being able to open and close the sections. Pass a -1 for
     * the index to disable this, and leave it only open and without controls
     * for opening or zooming.
     */
    public void displayOldLeaflet(AuthRequest ar, NGPage ngp, TopicRecord cr, int i) throws Exception {
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
            ar.write("\" title=\"Edit this topic\"  target=\"_blank\">EDIT</a>");
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
        ar.write(" viz="+cr.isPublic());
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
        if (s == null) {
            return null;
        }
        if (s.length() == 0) {
            return "";
        }

        int ilen = s.length();
        StringBuilder sOut = new StringBuilder(ilen);
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


    public void appendUsersF(List<AddressListEntry> members, List<AddressListEntry> collector)
                throws Exception {
        for (AddressListEntry ale : members) {
            boolean found = false;
            for (AddressListEntry coll : collector) {
                if (coll.hasAnyId(ale.getUniversalId())) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                collector.add(ale);
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
            //TODO: get rid of StringTokenizer
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
        StringBuilder sb = new StringBuilder("^");
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
