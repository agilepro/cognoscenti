<%@page errorPage="/spring/jsp/error.jsp"
%><%request.setAttribute("TypeOfGoalPage", "Completed Goals");%><%@ include file="leaf_process.jsp"
%>
<div class="content tab02" style="display:block;" onmousedown="buttononIndex('2')" >
    <div class="section_body">
        <div style="height:10px;"></div>
        <div id="paging1"></div>
        <div id="searchresultdiv1">
              <div class="taskListArea">

            <ul id="CompletedTask">
            <%
                outputProcess(ar, ngp, taskList, subprocess,2);
            %>
        </ul>

        </div>
         <%if(ngp.getAllGoals().size()>0){ %>
         <div id="orderIndex2" style="border: 1px none #000000; display:none" >
            <input type="button" class="btn btn-primary" value="Update Order" onclick="return reOrderIndex('CompletedTask');">
        </div>
        <%} %>
        </div>
    </div>
</div>
