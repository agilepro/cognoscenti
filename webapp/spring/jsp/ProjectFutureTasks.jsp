<%@page errorPage="/spring/jsp/error.jsp"
%><%request.setAttribute("TypeOfGoalPage", "Future Goals");%><%@ include file="leaf_process.jsp"
%>
<div class="content tab03" style="display:block;" onmousedown="buttononIndex('3')">
    <div class="section_body">
        <div style="height:10px;"></div>
        <div id="paging2"></div>
        <div id="searchresultdiv2">
              <div class="taskListArea">

                <ul id="FutureTask">
                <%
                    outputProcess(ar, ngp, taskList, subprocess,3);
                %>
                </ul>

        </div>
          <%if(ngp.getAllGoals().size()>0){ %>
          <div id="orderIndex3" style="border: 1px none #000000; display:none">
            <input type="button" class="btn btn-primary" value="Update Order" onclick="return reOrderIndex('FutureTask');">
         </div>
         <%} %>
        </div>
    </div>
</div>
