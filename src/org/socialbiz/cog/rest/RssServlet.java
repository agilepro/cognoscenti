/*
 * Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.rest;

import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Writer;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.UtilityMethods;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.streams.HTMLWriter;


/**
* This servlet serves up pages using the following URL format:
*
* http://machine:port/{application}/Tasks.rss?user=...&status=...
*
*/
@SuppressWarnings("serial")
public class RssServlet extends javax.servlet.http.HttpServlet
{

    public static final String STATUS_ALL = "all";
    public static final String STATUS_ACTIVE = "active";
    public static final String STATUS_COMPLETED = "completed";
    public static final String STATUS_FUTURE = "future";

    public void doGet(HttpServletRequest req, HttpServletResponse resp)
    {
        OutputStream out = null;
        try {
            Cognoscenti cog = Cognoscenti.getInstance(req);
            cog.assertInitialized();

            String requrl = req.getRequestURL().toString();
            out = resp.getOutputStream();

            // serverURL
            String ctxtroot = req.getContextPath();
            requrl = URLDecoder.decode(requrl, "UTF-8");
            int indx = requrl.indexOf(ctxtroot);
            String serverURL = requrl.substring(0, indx) + ctxtroot + "/";

            String userid = req.getParameter("user");

            String status = req.getParameter("status");
            if (status == null) {
                status = RssServlet.STATUS_ALL;
            }

            TaskHelper th = new TaskHelper(userid, serverURL);
            th.scanAllTask(cog);

            Document doc = DOMUtils.createDocument("rss");
            Element rssEle = doc.getDocumentElement();
            rssEle.setAttribute("version", "2.0");
            rssEle.setAttribute("xmlns:ng", "http://nugen.fujitsu.com");

            Element channelEle = DOMUtils.createChildElement(doc, rssEle, "channel");
            if (status.equals(RssServlet.STATUS_ALL))
            {
                Vector<GoalRecord> allTask = th.getAllTasks();
                DOMUtils.createChildElement(doc, channelEle, "title", "My All Tasks");
                DOMUtils.createChildElement(doc, channelEle, "link", serverURL+"MyTaskList.jsp");
                DOMUtils.createChildElement(doc, channelEle, "description", "List of all tasks");
                createItems(doc, channelEle, allTask, serverURL, th);
            }
            else if (status.equals(RssServlet.STATUS_ACTIVE))
            {
                Vector<GoalRecord> activeTask = th.getActiveTasks();
                DOMUtils.createChildElement(doc, channelEle, "title", "My Active Tasks");
                DOMUtils.createChildElement(doc, channelEle, "link", serverURL+"MyTaskList.jsp");
                DOMUtils.createChildElement(doc, channelEle, "description", "List of active tasks");
                createItems(doc, channelEle, activeTask, serverURL, th);
            }
            else if (status.equals(RssServlet.STATUS_COMPLETED))
            {
                Vector<GoalRecord> completedTask = th.getCompletedTasks();
                DOMUtils.createChildElement(doc, channelEle, "title", "My Completed Tasks");
                DOMUtils.createChildElement(doc, channelEle, "link", serverURL+"MyTaskList.jsp");
                DOMUtils.createChildElement(doc, channelEle, "description", "List of completed tasks");
                createItems(doc, channelEle, completedTask, serverURL, th);
            }
            else if (status.equals(RssServlet.STATUS_FUTURE))
            {
                Vector<GoalRecord> futureTask = th.getFutureTasks();
                DOMUtils.createChildElement(doc, channelEle, "title", "My Future Tasks");
                DOMUtils.createChildElement(doc, channelEle, "link", serverURL+"MyTaskList.jsp");
                DOMUtils.createChildElement(doc, channelEle, "description", "List of future tasks");
                createItems(doc, channelEle, futureTask, serverURL, th);
            }

            resp.setContentType("text/xml;charset=UTF-8");
            DOMUtils.writeDom(doc, out);
            out.flush();
            out.close();
        }
        catch (Exception e) {
            handleException(resp, e);
        }
    }

    private void createItems(Document doc, Element channelEle, Vector<GoalRecord> items,
            String serverURL, TaskHelper th) throws Exception {
        if (doc == null || channelEle == null || items == null) {
            return;
        }
        for (GoalRecord tr : items) {
            NGContainer ngp = th.getPageForTask(tr);

            Element itemEle = DOMUtils.createChildElement(doc, channelEle, "item");

            DOMUtils.createChildElement(doc, itemEle, "title", tr.getSynopsis());

            String linkVal = serverURL + "WorkItem.jsp?p="
                    + URLEncoder.encode(ngp.getKey(), "utf-8") + "&s=Tasks&id=" + tr.getId();

            DOMUtils.createChildElement(doc, itemEle, "link", linkVal);
            DOMUtils.createChildElement(doc, itemEle, "description", tr.getDescription());

            int state = tr.getState();
            String stateStr = "";
            if (state == BaseRecord.STATE_ERROR) {
                stateStr = "open.notrunning.suspended";
            }
            else if (state == BaseRecord.STATE_UNSTARTED) {
                stateStr = "open.notrunning";
            }
            else if (state == BaseRecord.STATE_STARTED) {
                stateStr = "open.running.offered";
            }
            else if (state == BaseRecord.STATE_ACCEPTED) {
                stateStr = "open.running.accepted";
            }
            else if (state == BaseRecord.STATE_WAITING) {
                stateStr = "open.running.waiting";
            }
            else if (state == BaseRecord.STATE_COMPLETE) {
                stateStr = "closed.completed";
            }
            else if (state == BaseRecord.STATE_SKIPPED) {
                stateStr = "closed.skipped";
            }
            DOMUtils.createChildElement(doc, itemEle, "ng:state", stateStr);

            DOMUtils.createChildElement(doc, itemEle, "ng:duedate",
                    UtilityMethods.getXMLDateFormat(tr.getDueDate()));
            DOMUtils.createChildElement(doc, itemEle, "ng:expectedstartdate",
                    UtilityMethods.getXMLDateFormat(tr.getStartDate()));
            DOMUtils.createChildElement(doc, itemEle, "ng:expectedenddate",
                    UtilityMethods.getXMLDateFormat(tr.getEndDate()));

            long durationDays = tr.getDuration();
            long durationSeconds = durationDays * 8 * 60 * 60; // 1 day = 8
                                                               // hours
            DOMUtils.createChildElement(doc, itemEle, "ng:duration",
                    String.valueOf(durationSeconds));

            DOMUtils.createChildElement(doc, itemEle, "ng:priority",
                    String.valueOf(tr.getPriority()));
            DOMUtils.createChildElement(doc, itemEle, "ng:assignee", tr.getAssigneeCommaSeparatedList());
            DOMUtils.createChildElement(doc, itemEle, "ng:progress", tr.getStatus());

            DOMUtils.createChildElement(doc, itemEle, "ng:process", serverURL + "p/" + ngp.getKey()
                    + "/process.xml");

            String sub = getFullyQualifiedUrl(tr.getSub(),
                    serverURL.substring(0, serverURL.length() - 1));

            DOMUtils.createChildElement(doc, itemEle, "ng:subprocess", sub);
        }
    }

    private static String getFullyQualifiedUrl(String urlFragment,
            String contextPath) {

        if (urlFragment != null) {
            // incase of a relative URL name append the context root to the URL.
            if ((urlFragment.toUpperCase().indexOf("HTTP://") == -1)
                    && (urlFragment.toUpperCase().indexOf("WWW.") == -1)) {
                if (!urlFragment.startsWith("/")) {
                    urlFragment = "/" + urlFragment;
                }
                urlFragment = contextPath + urlFragment;
            }
        }
        return urlFragment;
    }

    private void handleException(HttpServletResponse resp, Exception e)
    {
        try {
            OutputStream out = resp.getOutputStream();
            resp.setContentType("text/html;charset=UTF-8");
            if (out == null) {
                out = resp.getOutputStream();
            }
            Writer w = new OutputStreamWriter(out);
            w.write("<html><body><ul><li>Exception: ");
            HTMLWriter.writeHtml(w, e.toString());
            w.write("</li></ul>\n");
            w.write("<hr/>\n");
            w.write("<a href=\"main.jsp\">Main</a>\n");
            w.write("<hr/>\n<pre>");
            e.printStackTrace(new PrintWriter(new HTMLWriter(w)));
            w.write("</pre></body></html>\n");
            w.flush();
        }
        catch (Exception eeeee) {
            //nothing we can do here...
        }
    }


}