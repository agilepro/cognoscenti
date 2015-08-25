<%@page errorPage="/spring/jsp/error.jsp"
%><%
    request.setAttribute("TypeOfGoalPage", "Active Goals");
%><%@include file="leaf_process.jsp"
%>
<div class="content tab01" style="display:block;" onmousedown="buttononIndex('1')">
    <div class="section_body">
        <div style="height:10px;"></div>
        <div id="paging0"></div>
        <div id="searchresultdiv0">
              <div class="taskListArea">
            <ul id="ActiveTask">
                <%
                 outputProcess(ar, ngp, taskList, subprocess,1);

                %>
            </ul>
        </div>
        <%if(ngp.getAllGoals().size()>0){ %>

        <div id="orderIndex1" style="border: 1px none #000000; display:none">
            <input type="button" class="btn btn-primary" value="Update Order" onclick="return reOrderIndex('ActiveTask'); ">
        </div>


        <%} %>
        </div>
    </div>
</div>
