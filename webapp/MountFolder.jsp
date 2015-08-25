<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.dms.LocalFolderConfig"
%><%@page import="org.socialbiz.cog.dms.CVSConfig"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit this section.");
    pageTitle  = "Connect to Repository";
    Vector<LocalFolderConfig> lclConnections =  FolderAccessHelper.getLoclConnections();
    Vector<CVSConfig> cvsConnections =  FolderAccessHelper.getCVSConnections();
%>

<%@ include file="Header.jsp"%>

<%
    mounFolderForm(ar, lclConnections, cvsConnections);
%>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

<%!
    public void mounFolderForm(AuthRequest ar, Vector<LocalFolderConfig> lclConnections,
                Vector<CVSConfig> cvsConnections)throws Exception {
        Writer out = ar.w;
        ar.write("<form name=\"folderForm\" method=\"get\" action=\"");
        ar.write(ar.retPath);
        ar.write("createFolderAction.jsp\" enctype=\"multipart/form-data\">");
        ar.write("<br/><b>Add a new Document Repository.</b><br/><br/>");
        ar.write("\n<table width=\"80%\" class=\"Design8\" >");
        ar.write("<col width=\"20%\"/>");
        ar.write("<col width=\"80%\"/>");
ar.write("<input type=\"hidden\" name=\"fid\" value=\"CREATE\"");
        ar.write("\n<tr>");
        ar.write("<td><label id=\"protocol\">Protocol</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"ptcdiv\">");
        ar.write("<input type=\"radio\" name=\"ptc\" id=\"ptc\" onClick=\"changeForm()\" id=\"ptc\" value=\"CVS\"/>");
        ar.write("CVS <input type=\"radio\" id=\"ptc\" onClick=\"changeForm()\" name=\"ptc\" id=\"ptc\" value=\"WEBDAV\" checked=\"checked\"/>");
        ar.write("SharePoint <input type=\"radio\" id=\"ptc\" onClick=\"changeForm()\" name=\"ptc\" id=\"ptc\" value=\"SMB\"/>");
        ar.write("NetWorkShare <input type=\"radio\" id=\"ptc\" onClick=\"changeForm()\" name=\"ptc\" id=\"ptc\" value=\"LOCAL\"/>");
        ar.write("Local");
        ar.write("</div>");
        ar.write("</td></tr>");
        ar.write("\n<tr>");
        ar.write("<td><label id=\"nameLbl\">Display Name</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"dnamediv\"><input type=\"text\" name=\"displayname\" id=\"dname\" style=\"WIDTH:95%;\"/></div>");
        ar.write("</td></tr>");
        ar.write("\n<tr id=\"trspath\">");
        ar.write("<td><label id=\"pathLbl\">Server Path</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"fnamediv\"><input type=\"text\" name=\"serverpath\" id=\"fname\" style=\"WIDTH:95%;\"/></div>");
        ar.write("</td></tr>");

        ar.write("\n<tr  id=\"trlclroots\" style=\"display:none\">");
        ar.write("<td><label id=\"tdlclroot\">Local Root</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"lclrootdiv\"><select name=\"lclroot\" id=\"lclroot\" onchange=\"lclRootChange()\" style=\"WIDTH:95%;\"/>");
        String initlclfldr = "";
        for(int i=0; i<lclConnections.size(); i++){
            String key = lclConnections.get(i).getDisplayName();
            String val = lclConnections.get(i).getPath();
            if(initlclfldr.length() == 0)
                initlclfldr = val;
            ar.write("<option value=\"");
            ar.write(val);
            ar.write("\">");
            ar.write(key);
            ar.write("</option>");
        }

        ar.write("</select>");
        ar.write("</div>");
        ar.write("</td></tr>");
        ar.write("\n<tr  id=\"trlclfolder\" style=\"display:none\">");
        ar.write("<td><label>Local Folder</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"lclfolderdiv\"><input type=\"text\" name=\"lclfldr\" id=\"lclfldr\" value=\"");
        ar.write(initlclfldr);
        ar.write("\" style=\"WIDTH:95%;\"/></div>");
        ar.write("</td></tr>");


        ar.write("\n<tr  id=\"trcvsroots\" style=\"display:none\">");
        ar.write("<td><label id=\"tdcvsroot\">CVS Root</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"cvsrootdiv\"><select name=\"cvsroot\" id=\"cvsroot\" onchange=\"cvsRootChange()\" style=\"WIDTH:95%;\"/>");

        String initroot = "";
        String initmodule = "";
        for(int i=0; i<cvsConnections.size(); i++){
            String key = cvsConnections.get(i).getRoot();
            String val = cvsConnections.get(i).getRepository();
            if(initroot.length() == 0){
                initroot = key;
                initmodule = val;
            }
            ar.write("<option value=\"");
            ar.write(val);
            ar.write("\">");
            ar.write(key);
            ar.write("</option>");
        }

        ar.write("</select>");
        ar.write("<input type=\"hidden\" name=\"cvsserver\" value=\"");
        ar.write(initroot);
        ar.write("\"");
        ar.write("</div>");
        ar.write("</td></tr>");
        ar.write("\n<tr  id=\"trcvsmodule\" style=\"display:none\">");
        ar.write("<td><label id=\"tdcvsmodule\">CVS Module</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"cvsmodulediv\"><input type=\"text\" name=\"cvsmodule\" id=\"cvsmodule\" value=\"");
        ar.write(initmodule);
        ar.write("\" style=\"WIDTH:95%;\"/></div>");
        ar.write("</td></tr>");

        ar.write("\n<tr  id=\"truid\">");
        ar.write("<td><label id=\"userid\">User ID</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"uiddiv\"><input type=\"text\" name=\"uid\" id=\"uid\" style=\"WIDTH:95%;\"/></div>");
        ar.write("</td></tr>");
        ar.write("\n<tr id=\"trpwd\">");
        ar.write("<td><label id=\"password\">Password</label></td>");
        ar.write("<td class=\"odd\">");
        ar.write("<div id=\"pwddiv\"><input type=\"password\" name=\"pwd\" id=\"pwd\" style=\"WIDTH:95%;\"/></div>");
        ar.write("</td></tr>");

        ar.write("</table>");
        ar.write("<br/>");
        ar
                .write("<button type=\"submit\" id=\"actBtn1\" name=\"action\" value=\"Create New\">Create New</button>");
        ar
                .write("<button type=\"submit\" id=\"actBtn2\" name=\"action\" value=\"Cancel\">Cancel</button> ");
        ar.write("</form> ");

        ar.write("<script> ");
        ar.write("    var actBtn1 = new YAHOO.widget.Button(\"actBtn1\"); ");
        ar.write("    var actBtn2 = new YAHOO.widget.Button(\"actBtn2\"); ");
        ar.write(" </script> ");
    }

%>

<script type="text/javascript">
    function changeForm()
    {
        if(document.folderForm.ptc[3].checked){
            document.getElementById("trlclroots").style.display='';
            document.getElementById("trlclfolder").style.display='';
            document.getElementById("trspath").style.display='none';
            document.getElementById("truid").style.display='none';
            document.getElementById("trpwd").style.display='none';
            document.getElementById("trcvsroots").style.display='none';
            document.getElementById("trcvsmodule").style.display='none';
            document.folderForm.serverpath.value='local';
        }else if(document.folderForm.ptc[0].checked){
            document.getElementById("trcvsroots").style.display='';
            document.getElementById("trcvsmodule").style.display='';
            document.getElementById("truid").style.display='';
            document.getElementById("trpwd").style.display='';
            document.getElementById("trspath").style.display='none';
            document.getElementById("trlclroots").style.display='none';
            document.getElementById("trlclfolder").style.display='none';
            document.folderForm.serverpath.value='cvs';
        }else{
            document.folderForm.serverpath.value='';
            document.getElementById("trspath").style.display='';
            document.getElementById("truid").style.display='';
            document.getElementById("trpwd").style.display='';
            document.getElementById("trlclroots").style.display='none';
            document.getElementById("trlclfolder").style.display='none';
            document.getElementById("trcvsroots").style.display='none';
            document.getElementById("trcvsmodule").style.display='none';
        }
    }

function lclRootChange(){
    document.getElementById("lclfldr").value = document.folderForm.lclroot.value;
}

function cvsRootChange(){
    document.getElementById("cvsmodule").value = document.folderForm.cvsroot.value;
    document.getElementById("cvsserver").value = document.folderForm.cvsroot.name;
}

</script>
