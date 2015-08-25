<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"%>
<%

    if (!Cognoscenti.getInstance(request).isInitialized())
    {
        String go = ar.getCompleteURL();
        String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go);
        response.sendRedirect(configDest);
    }

 %>
<body class="yui-skin-sam">

<div class="generalHeading">
<fmt:message key="nugen.generatInfo.main.welcome.page" />
</div>
<div class="generalContent">
<p>Cognoscenti Console will help you organize your time, your meetings,
your work, and your knowledge resources.</p>
</div>

<div class="generalContent">
<p>Cognoscenti Console is better than email. Email works fine when you
need to send a note to someone, a file to someone, or even when you are
sending to a group of people. Email is best when the communications is
one way, but if you need to work together with a group, the separate
messages get hard to track. You end up with lost of messages, lots of
versions of documents, and it is hard to piece together the final
results from this exchange.</p>

<img src="../Avatar.png" align="right">

<p>Imagine a simple case of a sales proposal. Let's say that one
person gets a hold of an RFP for a potential deal, and wants to know
whether their organization can put together a competitive bit. Using
email, the RFP questions would be emails to a group of people. Different
people on the team will read through the RFP questions, and provide
answers, and email the marked up document to everyone. Other may comment
on, or extend the answers. Even in a small group you could end up with
10 to 20 copies of the RFP with various answers to various questions.
When it comes to making a decision, it is hard to collect everything
together in one place and to keep a handle on what is happening. Just
receiving all the email and organizing it is a tremendous burden on each
member of the team.</p>

<p>This is where Cognoscenti Console comes in. Instead of starting with
an email message, that person would start by creating a "Project". Each
project has a goal, and the goal of this project is to "Determine whether or
not to respond to the RFP". The project is a single place where everything
necessary to reach this goal can be placed. The original RFP document is
attached to the project. As people answer questions, the modified document
is attached in place of the original, so when each person go to access,
they always get the latest version. The main part of the project is
editable by anyone at any time without needing anything more than a
browser installed. Individuals can make and discuss comments about
aspcted of the proposal. Action items can be created and assigned to
people, and tracked through to completion. As actions are completed, the
results are visible to all. In order to decide whether or not to respond
to the RFP, a poll question can be constructed, and each person involved
can register a vote for or against. Cognoscenti Console keeps everything
together in one place, so that it is all there and can easily be found
by all members without having to spend endless hours wading through
email.</p>

<p>Another use for Cognoscenti Console is to help you run great meetings.
Whether you are dial in phone conference or just a weekly local get
together, Cognoscenti Console can help you make your meeting more effective.
When you are thinking about having a meeting, the first thing you do is
create a Project for the meeting. On that project you put the date, time,
agenda, meeting room, or call in details. All the people you want to
invite to the meeting are added to the "member" role of the project. As
people prepare for the meeting, they attach to the project any
presentations they are planning to give at the meeting. No worries, if
they want to change their presentation at the last minute, they can
simply update the attachment with the latest revision. People attending
the meeting can see the presentation just by cliking on a link, and
there is no need for anyone to "promise" to send the documents after the
meeting. During the meeting, notes are taken directly on the project.
Others can review the notes, and suggest corrections, before the meeting
has ended. As action items are identified, they are entered as tasks,
and assigned to people. The worklist capability makes is easy for
everyone to find those tasks until they are finally marked as completed.
The project remains around as a permanent record of what was accomplished
at the meeting and as a result of the meeting.</p>

<p>You are not logged in currently, and to get more from Process
Leaves you need to log in with any OpenID.</p>
</div>




  <script type="text/javascript">
        YAHOO.util.Event.addListener(window, "load", function()
        {


            YAHOO.example.EnhanceFromMarkup = function()
            {
                var myColumnDefs = [
                    {key:"bookid",label:"<fmt:message key='nugen.generatInfo.main.BookId'/>",sortable:true,resizeable:true},
                    {key:"members",label:"<fmt:message key='nugen.generatInfo.main.Members' />",sortable:true,resizeable:true},
                    {key:"desc",label:"<fmt:message key='nugen.generatInfo.main.Description' />",sortable:false,resizeable:true}];

                var myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("pagelist"));
                myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE;
                myDataSource.responseSchema = {
                    fields: [{key:"bookid"},
                            {key:"members"},
                            {key:"desc"}]
                };

                var oConfigs = {
                    paginator: new YAHOO.widget.Paginator({
                        rowsPerPage: 200
                    }),
                    initialRequest: "results=999999"
                };


                var myDataTable = new YAHOO.widget.DataTable("listofpagesdiv", myColumnDefs, myDataSource, oConfigs,
                {caption:"",sortedBy:{key:"bookid",dir:"desc"}});

                return {
                    oDS: myDataSource,
                    oDT: myDataTable
                };
            }();
        });
    </script>

<%@ include file="functions.jsp"%>
</body>
