<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameter:

    1. pageId         : This is the id of a Workspace and used to retrieve NGWorkspace.
    2. aid            : This is attachment id which is used to check if it is not null then
                        you are pushing it to repository and if null then you are browsing connection
                        to attach the document.
    3. fndDefLoctn    : This is true when admin wants to set a default location of repository folder.

*/

    String aid    = ar.defParam("aid", "");
    String fndDefLoctn    = ar.defParam("fndDefLoctn", "false");
    
    UserProfile uProf = ar.getUserProfile();
%>
<script type="text/javascript">

    function openModalDialogue(popupId,headerContent,panelWidth){
        var   header = headerContent;
        var bodyText= document.getElementById(popupId).innerHTML;
        createPanel(header, bodyText, panelWidth);
        myPanel.beforeHideEvent.subscribe(function() {
            if(!isConfirmPopup){
                window.location = "folderDisplay.htm";
            }
        });
    }

     function cancelPanel(){
        myPanel.hide();
        return false;
    }
</script>
<%
    displayRepositoryListX(ar, pageId, aid,fndDefLoctn);
%>
<%@ include file="functions.jsp"%>
<%!public void displayRepositoryListX(AuthRequest ar, String pageId, String aid, String fndDefLoctn)
    throws Exception {
        try {
            UserPage uPage = ar.getUserPage();
            NGWorkspace page = ar.getCogInstance().getWSByCombinedKeyOrFail(pageId).getWorkspace();

            ar.write("<div class=\"generalArea\">");
            ar.write("\n<div class=\"pageHeading\">");
            ar.write("\n Select a repository to browse within");
            ar.write("</div>");
            ar.write("\n<div class=\"pageSubHeading\">");
            ar.write("\n From here you can browse");
            ar.write("</div>");
            ar.write("\n<div class=\"generalSettings\">");
            ar.write("\n<table class=\"gridTable2\" width=\"100%\">");


            for (ConnectionSettings cSet : uPage.getAllConnectionSettings())
            {
                if(!cSet.isDeleted())
                {
                    String dname = getShortName(cSet.getDisplayName(), 38);
                    String fdLink = "";
                    if((aid != "")&&(aid.length()>0))
                    {
                        String vpath = "/";

                        fdLink = ar.retPath+ "t/"+ page.getSite().getKey()+ "/" +page.getKey()+ "/ChooseFolder.htm?path="
                                            + URLEncoder.encode(vpath, "UTF-8")
                                            +"&folderId="+cSet.getId()
                                            +"&aid="+aid;
                    }else if(fndDefLoctn.equals("true"))
                    {
                        String vpath = "/";

                        fdLink = ar.retPath+ "t/"+ page.getSite().getKey()+ "/" +page.getKey()+ "/ChooseFolder.htm?path="
                                            + URLEncoder.encode(vpath, "UTF-8")
                                            +"&folderId="+cSet.getId()
                                            +"&fndDefLoctn=true";
                    }else{
                        fdLink = ar.retPath+"v/"+ar.getUserProfile().getKey()+"/BrowseConnection"+cSet.getId()
                            +".htm?path=%2F&p="+URLEncoder.encode(pageId, "UTF-8");
                    }
                    ar.write("\n<tr>");
                    ar.write("\n<td width=\"20px\"><img src=\"");
                    ar.write(ar.retPath);
                    ar.write("assets/iconFolder.gif\" alt=\"\" /></td>");
                    ar.write("\n<td class=\"repositoryName\"><a <a href=\"");
                    ar.writeHtml(fdLink);
                    ar.write(" \"");
                    writeTitleAttribute(ar, cSet.getDisplayName(), 38);
                    ar.write(">" + dname + "</a></td>");
                    ar.write("\n</tr>");
                }
           }

           ar.write("\n</table>");
           ar.write("\n</div>");
           ar.write("\n</div>");
       } catch (Exception e) {
           throw new ProgramLogicError("Unable to display root folders for workspace "+pageId, e);
       }

    }%>
    
    
    <div class="guideVocal" >
        User <% uProf.writeLink(ar); %> has not created any Connections.<br/>
        <br/>
        A connection is a pre-authenticated link to a document repository.
        When you access a document repository that requires a user name and password,
        you can save your use name and password in a connection to use it in the future.
        The connection will be used when you 'synchronize' a document in this workspace 
        with the copy of it in the document repository.  This is saved with the attached
        document so that other workspace members can synchronize without you personally
        having to do it.
        <br/><br/>
        This is an advanced functionality used only with external document repositories
        and is not available for you at this time.
        
    </div>
    