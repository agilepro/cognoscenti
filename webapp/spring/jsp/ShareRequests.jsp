<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.rest.RssServlet"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a user");

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.  No one appears to be logged in.");
    }

    boolean viewingSelf = uProf.getKey().equals(operatingUser.getKey());

    String rssLink = "Tasks.rss?user="+ java.net.URLEncoder.encode(uProf.getUniversalId(), "UTF-8");
    String loggingUserName=uProf.getName();


%>
<body class="yui-skin-sam">
    <div class="generalHeadingBorderLess">Reminders To Share Document</div>
    <div id="paging5"></div>
    <div id="reminderDiv">
        <table id="reminderTable">
            <thead>
                <tr>From</tr>
                <tr>Subject</tr>
                <tr>Sent On</tr>
                <th>Workspace</th>
                <th>timePeriod</th>
                <th>rid</th>
                <th>projectKey</th>
                <th>bookKey</th>
            </thead>
        <%
            for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers())
                {
            //start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject())
            {
                continue;
            }
            NGPage aPage = ngpi.getPage();

            ReminderMgr rMgr = aPage.getReminderMgr();
            List<ReminderRecord> rVec = rMgr.getUserReminders(ar.getUserProfile());
            AddressListEntry ale = null;
            for(ReminderRecord reminder : rVec)
            {
                ale = new AddressListEntry(reminder.getModifiedBy());
        %>

            <tr>
                <td><%
                    ale.writeLink(ar);
                %></td>
                <td><%
                    ar.write(reminder.getSubject());
                %></td>
                <td><%
                    SectionUtil.nicePrintTime(ar, reminder.getModifiedDate(), ar.nowTime);
                %></td>
                <td><%
                    ar.write(aPage.getFullName());
                %></td>
                <td><%
                    ar.writeHtml(String.valueOf((ar.nowTime - reminder.getModifiedDate())/1000 ));
                %></td>
                <td><%
                    ar.writeHtml(reminder.getId());
                %></td>
                <td><%
                    ar.writeHtml(aPage.getKey());
                %></td>
                <td><%
                    ar.writeHtml(aPage.getSite().getKey());
                %></td>
            </tr>
        <%
            }
        }
        %>
        </table>
    </div>
    <!-- Display the search results here -->

    <form name="taskList">
        <input type="hidden" name="filter" value="<%ar.writeHtml(DataFeedServlet.COMPLETEDTASKS);%>"/>
        <input type="hidden" name="rssfilter" value="<%ar.writeHtml(RssServlet.STATUS_COMPLETED);%>"/>
    </form>

    <script type="text/javascript">

    </script>

<script type="text/javascript">

    function invokeRSSLink(link) {
        window.location.href = "<%=ar.retPath + rssLink%>&status=" + document.taskList.rssfilter.value ;
    }

    YAHOO.util.Event.addListener(window, "load", function()
    {

        YAHOO.example.EnhanceFromMarkup = function()
        {
            var myColumnDefs = [
                {key:"from",label:"Requested By",sortable:true,resizeable:true},
                {key:"subject",label:"Document to upload",formatter:reminderNameFormater,sortable:true,resizeable:true},
                {key:"sentOn",label:"Sent On",sortable:true,sortOptions:{sortFunction:sortDates},resizeable:true},
                {key:"projectName",label:"Workspace Name",formatter:prjectNameFormater,sortable:true,resizeable:true},
                {key:"timePeriod",label:"timePeriod",sortable:true,resizeable:false,hidden:true},
                {key:"rid",label:"rid",sortable:true,resizeable:false,hidden:true},
                {key:"pageKey",label:"pageKey",sortable:true,resizeable:false,hidden:true},
                {key:"bookKey",label:"bookKey",sortable:true,resizeable:false,hidden:true}
                ];

            var myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("reminderTable"));
            myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE;
            myDataSource.responseSchema = {
                fields: [
                        {key:"from"},
                        {key:"subject"},
                        {key:"sentOn"},
                        {key:"projectName"},
                        {key:"timePeriod", parser:YAHOO.util.DataSource.parseNumber},
                        {key:"rid"},
                        {key:"pageKey"},
                        {key:"bookKey"}]
            };

             var oConfigs = {
                paginator: new YAHOO.widget.Paginator({
                    rowsPerPage: 200,
                    containers: 'paging5'
                }),
                initialRequest: "results=999999"

            };

            var myDataTable = new YAHOO.widget.DataTable("reminderDiv", myColumnDefs, myDataSource, oConfigs,
            {caption:""});

            myDataTable.sortColumn(myDataTable.getColumn(4));
            return {
                oDS: myDataSource,
                oDT: myDataTable
            };
        }();
    });
    var reminderNameFormater = function(elCell, oRecord, oColumn, sData)
    {
        var name = oRecord.getData("subject");
        var pageKey = oRecord.getData("pageKey");
        var bookKey = oRecord.getData("bookKey");
        var rid = oRecord.getData("rid");
        elCell.innerHTML = '<a href="<%=ar.baseURL%>t/'+bookKey+'/'+pageKey+'/viewEmailReminder.htm?rid='+rid+'" ><div style="color:gray;">'+name+'</a></div>';

    };
    var prjectNameFormater = function(elCell, oRecord, oColumn, sData)
    {
        var name = oRecord.getData("subject");
        var pageKey = oRecord.getData("pageKey");
        var bookKey = oRecord.getData("bookKey");
        var projectName = oRecord.getData("projectName");
        elCell.innerHTML = '<a href="<%=ar.baseURL%>t/'+bookKey+'/'+pageKey+'/frontPage.htm" >'+projectName+'</a>';

    };

</script>
