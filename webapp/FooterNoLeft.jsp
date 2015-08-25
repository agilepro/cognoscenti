                            <div class="pagenavigation">
                                <div class="pagenav">
                                    <div class="left"><%writeMembershipStatus(ngp, ar);%></div>
                                    <div class="right"></div>
                                    <div class="clearer"></div>
                                </div>
                                <div class="pagenav_bottom"></div>

                            </div>

                        </div>


                    </div>

<div class="left" id="main_left">

    <div id="sidebar">
        <div class="box">
            <div class="box_title">Edit</div>
            <div class="box_body">
            <br/>
            <br/>
            Edit.  After saving close the window.<br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
            </div>
        </div>

    </div>
</div>
                    <div class="clearer">&nbsp;</div>


                </div>




                <div id="footer">
                    <div class="left">&#169; 2008 Fujitsu America - Advanced Software Design Lab</div>
                    <div class="right">&laquo; Dynamic Process Management &raquo;</div>
                    <div class="clearer">&nbsp;</div>
                </div>

            </div>
            <div id="layout_edgebottom"></div>
        </div>

    </body>
</html>

<%!
    private void writeMembershipStatus(NGPage ngp, AuthRequest ar)
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
                ar.write("\n<p>You are an honorary member of this project for this session ");
                ar.write("because you accessed this project with a special link.</p>");
                ar.write("\n<p>Log in in order to see member information on other projects.</p>");
            }
            else
            {
                ar.write("\n<p>You are not logged into the system at this time so we are not ");
                ar.write("able to determine your access to this project.  ");
                ar.write("There might be more information available to logged in users.");
                ar.write("You can log in with any OpenID, or with your Email Address and ");
                ar.write("a registered password.</p>\n");
            }
            ar.write("</td></tr></table>");
            return;
        }


        //after this point user is assured to be logged in.

        ar.write("\n<table><form action=\"");
        ar.write(ar.retPath);
        ar.write("LogoutAction.jsp\" method=\"post\"><tr><td>You are logged in as <b>");
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
        ar.write("\"/></td><td><input type=\"submit\" value=\"Logout\"/></td></tr></form></table>");

        if (ngp==null)
        {
            ar.write("</td></tr></table>");
            return;
        }

        ar.write("\n<p>");

        if (!ngp.primaryOrSecondaryPermission(uProf))
        {
            ar.write("You are not a member of this project.  ");
            ar.write("There is more information on this project that is available to members.  ");
            ar.write("Membership must be approved by other members.  ");
            ar.write("To request such approval, use the 'Request Membership' button.");
            requestMemberButton(ar, ngp, uProf);
        }
        else
        {
            ar.write("You are a member of this project, you can see all the main ");
            ar.write(" information on the project, and you may participate in member actions. ");
        }
        ar.write("\n</p>\n<p>");
        if (!ngp.secondaryPermission(uProf))
        {
            ar.write("There are some sections of the project that can be edited only by ");
            ar.write("admins, and you are not an admin.");
            ar.write("Depending upon circumstances, you may feel that you could contribute ");
            ar.write("more to this project by becoming an admin.");
        }
        else
        {
            ar.write("You are an admin of this project, you have read and ");
            ar.write("write access to all information on the project. ");
        }

        ar.write("\n</p>");


        if (ar.ngsession.isHonoraryMember(ngp.getKey()))
        {
            ar.write("\n<p>You are an honorary member of this project for this session.</p>");
        }


        //handle the license case
        if (ar.license!=null)
        {
            ar.write("\n<p>");
            int days = (int)((ar.license.getTimeout() - ar.nowTime)/24000/3600) + 1;
            ar.write("You have invoked a 'free pass' license to access this project.");
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

%>
