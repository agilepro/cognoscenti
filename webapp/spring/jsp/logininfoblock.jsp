<%@page import="org.socialbiz.cog.NGBook"%>
<%@page import="org.socialbiz.cog.NGContainer"%>
<%!
    private void writeMembershipStatus(NGContainer ngp, AuthRequest ar)
        throws Exception
    {
        /*
        Writer w = ar.w;
        UserProfile uProf = ar.getUserProfile();

        //this table is an attempt to eliminate the problem with wordwrapping in IE
        //IE 6.0 wraps words too late, making the text area bigger than it should be, pushing
        //the table over, and causing a layout conflict with the other column.
        //By shrinking the wordwrap area, we avoid the problem, but there is still some deeper
        //problem
        ar.write("\n<table width=\"700\"><tr><td>");

        if (!ar.isLoggedIn())
        {
            if (!pageTitle.equals("Login Page"))
            {
                writeLoginPrompt(ar);
            }
            if (ngp!=null && ar.ngsession.isHonoraryMember(ngp.getKey()))
            {
                ar.write("\n<p>You are an honorary member of this Project for this session ");
                ar.write("because you accessed this Project with a special link.</p>");
                ar.write("\n<p>Log in in order to see member information on other Projects.</p>");
            }
            else
            {
                //ar.write("\n<p>You are not logged into the system at this time so we are not ");
                //ar.write("able to determine your access to this page.  ");
                //ar.write("There might be more information available to logged in users.");
                //ar.write("You can log in with any OpenID, or with your Email Address and ");
                //ar.write("a registered password.</p>\n");
            }
            ar.write("</td></tr></table>");
            return;
        }


        ar.write("\n<table><form action=\"");
        ar.write(ar.retPath);
        ar.write("t/LogoutAction.htm\" method=\"post\"><tr><td>You are logged in as <b>");
        if (uProf!=null)
        {
            uProf.writeLink(ar);
        }
        else
        {
            ar.writeHtml(ar.getBestUserId());
        }
        ar.write("</b> &nbsp; &nbsp; <input type=\"hidden\" name=\"go\" value=\"");
        ar.writeHtml(ar.getCompleteURL());
        ar.write("\"/></td><td><input type=\"submit\" class=\"btn btn-primary\" value=\"Logout\"/></td></tr></form></table>");

        //TODO for now ignoring rest for the NGBook
        if (ngp==null || ngp instanceof NGBook)
        {
            ar.write("</td></tr></table>");
            return;
        }

        ar.write("\n<p>");
        if (ar.isAdmin())
        {
            if(ngp.isFrozen()){
                ar.write("You are an admin of this project, but ");
                ar.writeHtmlMessage("nugen.project.freezed.msg", null);
            }else{
                ar.write("You are an admin of this project, you have read and");
                ar.write("write access to all (non private)");
                ar.write("information on the project.");
            }
        }
        else if (ar.isMember())
        {
            ar.write("You are a member of this project, you can see all the main");
            ar.write("information on the project, and you may participate in member actions.");
            ar.write("There are some sections of the project that can be edited only by");
            ar.write("admins, and you are not an admin.");
            ar.write("Depending upon circumstances, you may feel that you could contribute");
            ar.write("more to this project by becoming an admin.");
        }
        else
        {
            ar.write("You are not a member of this project.");
            ar.write("There is more information on this project that is available to members.");
            ar.write("Membership must be approved by other members.");
        }
        ar.write("\n</p>");

        if (ar.ngsession.isHonoraryMember(ngp.getKey()))
        {
            ar.write("\n<p>You are an honorary member of this Project for this session.</p>");
        }

        //handle the license case
        if (ar.license!=null)
        {
            ar.write("\n<p>");
            int days = (int)((ar.license.getTimeout() - ar.nowTime)/24000/3600) + 1;
            //TODO: this needs to be translatable
            ar.write("You have invoked a 'free pass' license to access this Project.");
            ar.write("\nLicense ");
            ar.write(ar.license.getId());
            if (days>0)
            {
                ar.write(" will be valid for ");
                ar.write(Integer.toString(days));
                ar.write(" more days.");
            }
            else
            {
                ar.write(" is no longer valid.");
            }
            ar.write("\n</p>");
        }

        //end of the IE workaround table
        ar.write("\n</td></tr></table>");
        */
    }

    public boolean suppressLogin = false;



    private void writeLoginPrompt(AuthRequest ar)
        throws Exception
    {
        if (suppressLogin)
        {
            return;
        }

        String currentPageURL = ar.getCompleteURL();

        //not logged in, but might have claimed to be someone in the past, and so
        //use that as a convenient starting value.
        String [] possibleIds = ar.getBestGuessId(null);
        String possibleOpenId = possibleIds[0];
        String possibleEmail = possibleIds[1];
        String possibleName = null;
        if (possibleEmail.length()>0)
        {
            UserProfile formerUser = UserManager.findUserByAnyId(possibleEmail);
            if (formerUser!=null)
            {
                possibleName = formerUser.getName();
            }
        }


        ar.write("\n<table >");
        if (possibleName!=null && possibleName.length()>0)
        {
            //TODO: this needs to be translatable
            ar.write("\n<tr><td></td><td>Welcome back, ");
            ar.writeHtml(possibleName);
            ar.write("!  Please log in.<br/>&nbsp;</td></tr>");
        }

        String loginPageUrl = ar.baseURL + "t/EmailLoginForm.htm?go="+URLEncoder.encode(currentPageURL, "UTF-8");

        //OpenId login form
        ar.write("\n<form action=\"");
        ar.write(ar.retPath);
        ar.write("t/openIdLogin.form\" method=\"post\" name=\"loginForm\">");
        ar.write("<input type=\"hidden\" name=\"go\" value=\"");
        ar.writeHtml(currentPageURL);
        ar.write("\"/><input type=\"hidden\" name=\"err\" value=\"");
        ar.writeHtml(loginPageUrl);
        ar.write("\"/>");
        ar.write("\n<tr><td>OpenID:</td>");
        ar.write("<td><input type=\"text\" name=\"openid\" value=\"");
        ar.writeHtml(possibleOpenId);
        ar.write("\" size=\"50\"/>  ");
        ar.write("</td>");
        ar.write("<td></td><td> &nbsp; <input name=\"option\" type=\"submit\" class=\"btn btn-primary\" value=\"Login with OpenId\"/>");
        ar.write("</td></tr></form>");

        ar.write("<tr><td>&nbsp;</td></tr>");

        //Email Login Form
        ar.write("<form action=\"");
        ar.write(ar.retPath);
        ar.write("t/EmailLoginAction.form\" method=\"post\">");
        ar.write("<input type=\"hidden\" name=\"go\" value=\"");
        ar.writeHtml(currentPageURL);
        ar.write("\"/><input type=\"hidden\" name=\"err\" value=\"");
        ar.writeHtml(loginPageUrl);
        ar.write("\"/>");
        ar.write("\n<tr><td>Email:</td>");
        ar.write("<td><input type=\"text\" name=\"email\" value=\"");
        ar.writeHtml(possibleEmail);
        ar.write("\" size=\"50\"/>  ");
        ar.write("</td><td></td></tr>");
        ar.write("\n<tr><td>Password:</td>");
        ar.write("<td><input type=\"password\" name=\"password\" size=\"50\"/></td>");
        ar.write("<td></td><td> &nbsp; <input name=\"option\" type=\"submit\" class=\"btn btn-primary\" value=\"Login with Email\"/>");
        ar.write("</td></tr>");
        ar.write("</form>");

        //TODO: this needs to be translatable
        ar.write("\n<tr><td></td><td><br/>Log in if you have a profile.  Otherwise you can ");
        ar.write("<a href=\"");
        ar.write(ar.retPath);
        ar.write("t/EmailLoginForm.htm?go=");
        ar.writeURLData(currentPageURL);
        ar.write("\">register or reset your password.</a></td></tr>");
        ar.write("</table>");
    }


%>
