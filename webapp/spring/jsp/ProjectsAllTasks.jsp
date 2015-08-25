<%@page errorPage="/spring/jsp/error.jsp"
%><%request.setAttribute("TypeOfGoalPage", "All Goals");%><%@ include file="leaf_process.jsp"
%>
<div class="content tab04" style="display:block;" onmousedown="buttononIndex('4')">
    <div class="section_body">
        <div style="height:10px;"></div>
        <div id="paging3"></div>
        <div id="searchresultdiv3">

        <div class="taskListArea">

            <ul id="AllTask">
                <%
                outputProcess(ar, ngp, taskList, subprocess,4);
                %>
            </ul>

        </div>
        <%if(ngp.getAllGoals().size()>0){ %>
        <div id="orderIndex4" style="border: 1px none #000000; display:none">
            <input type="button" class="btn btn-primary" value="Update Order" onclick="return reOrderIndex('AllTask');">
        </div>
        <%} %>
        </div>
    </div>
</div>
