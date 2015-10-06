<%!public void ProjectTasksEmailBody(AuthRequest ar, NGPage ngp, int level, String thisPageAddress, int max)
        throws Exception
    {
        ar.write("\n<table width=\"580\">");
        ar.write("\n<col width=\"20\">");
        ar.write("\n<col width=\"20\">");
        ar.write("\n<col width=\"20\">");
        ar.write("\n<col width=\"20\">");
        ar.write("\n<col width=\"20\">");
        ar.write("\n<col width=\"20\">");
        ar.write("\n<col width=\"170\">");
        ar.write("\n<col width=\"150\">");
        ar.write("\n<col width=\"70\">");
        ar.write("\n<col width=\"70\">");
        ar.write("\n<tr><td colspan=\"10\">&nbsp;<br/></td></tr>");
        ar.write("\n<tr><td colspan=\"10\"><hr/></td></tr>");
        ar.write("\n<tr><td colspan=\"7\">Task</td>");
        ar.write("\n<td>assignee</td>");
        ar.write("\n<td>due</td>");
        ar.write("\n<td>estimated</td>");
        ar.write("\n</tr>");
        ar.write("\n<tr><td colspan=\"10\"><hr/></td></tr>");
        outputProcess(ar,ngp,level,thisPageAddress,max);
        ar.write("\n</table>");
    }


    public void outputProcess(AuthRequest ar, NGPage ngp, int level, String thisPageAddress, int max)
        throws Exception
    {
        ProcessRecord pr = ngp.getProcess();
        List<GoalRecord> grlist = ngp.getAllGoals();
        GoalRecord.sortTasksByRank(grlist);

        if (grlist.length>0)
        {
            for (GoalRecord goal : grlist)
            {
                //tasks with parents will be handled recursively
                //as long as parent setting is valid
                if (!goal.hasParentGoal())
                {
                    outputTask(ar, ngp, goal, level, thisPageAddress, max);
                }
            }
        }
        else
        {
            indentToLevel(ar, level);
            ar.write("<i>no tasks in this process</i></td></tr>");
        }
    }

    public void indentToLevel(AuthRequest ar, int level)
        throws Exception
    {
        ar.write("\n<tr>");
        for (int j=1; j<level; j++)
        {
            ar.write("<td></td>");
        }
        ar.write("<td colspan=\"");
        ar.write(Integer.toString(8-level));
        ar.write("\">");
    }


    public void outputTask(AuthRequest ar, NGPage ngp,
                  GoalRecord task, int level, String thisPageAddress, int max)
        throws Exception
    {
        int ts = task.getState();
        if (ts!=BaseRecord.STATE_ACCEPTED && ts!=BaseRecord.STATE_OFFERED)
        {
            //not interested in task if not started or accepted
            return;
        }
        indentToLevel(ar, level);
        ar.write("<a href=\"");
        ar.writeHtml(ar.retPath);
        ar.write("WorkItem.jsp?p=");
        ar.writeURLData(ngp.getKey());
        ar.write("&amp;s=Tasks&amp;id=");
        ar.write(task.getId());
        ar.write("&amp;go=");
        ar.writeURLData(thisPageAddress);
        ar.write("\" title=\"View details and modify activity state\"><img src=\"");
        ar.writeHtml(ar.retPath);
        ar.writeHtml(task.stateImg(task.getState()));
        ar.write("\"></a> ");

        ar.writeHtml(task.getSynopsis());

        String dlink = task.getDisplayLink();
        if (dlink!=null && dlink.length()>0)
        {
            ar.write(" <a href=\"");
            ar.writeHtml(task.getDisplayLink());
            ar.write("\"><img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("drilldown.gif\"></a>");
        }
        ar.write("</td><td>");
        task.writeUserLinks(ar);
        ar.write("</td><td>");
        SectionUtil.nicePrintDate(ar.w, task.getDueDate());
        ar.write("</td><td>");
        SectionUtil.nicePrintDate(ar.w, task.getEndDate());
        ar.write("</td></tr>");

        //check for subtasks
        List<GoalRecord> children = task.getSubGoals();
        for (GoalRecord child : children) {
            outputTask(ar, ngp, child, level+1, thisPageAddress, max);
        }

        String sub = task.getSub();
        if (sub==null ||sub.length()==0)
        {
            return;
        }

        if (level>=max)
        {
            return;  //don't even try to go that many levels, avoid infinite recursion
        }

        //fake it without doing the HTTP fetch, instead get the id from the URL

        String pageid = getKeyFromURL(sub);
        if (pageid==null)
        {
            throw new Exception("pageid is null for sub="+sub);
        }

        NGPageIndex subpage = ar.getCogInstance().getContainerIndexByKey(pageid);

        if (subpage==null)
        {
            //try again with lower case ... old URL with uppercase in data still
            //in the data set.   Should clean up data.
            subpage = ar.getCogInstance().getContainerIndexByKey(pageid.toLowerCase());
            if (subpage==null)
            {
                return;  //ignore it, bad URL
            }
        }

        outputProcess(ar, subpage.getPage(), level+1, thisPageAddress, max);

    }

    public String getKeyFromURL(String url)
    {
        int ppos = url.indexOf("/p/")+3;
        if (ppos<3)
        {
            if (!url.startsWith("p/"))
            {
                return null;   //no p slashes, ignore this
            }
            ppos = 2;
        }
        int secondSlash = url.indexOf("/", ppos);
        if (secondSlash<=0)
        {
            return null;   //no second slash, ignore this
        }
        return url.substring(ppos, secondSlash);
    }%>
