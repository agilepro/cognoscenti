package org.socialbiz.cog;

import java.io.StringWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.mail.EmailSender;
import org.workcast.streams.HTMLWriter;

public class DailyDigest {


    /*
     * This method loops through all known users (with profiles) and sends an
     * email with their tasks on it.
     */
    public static void sendDailyDigest(AuthRequest arx, Cognoscenti cog) throws Exception {
        Writer debugEvidence = new StringWriter();

        try {
            NGPageIndex.assertNoLocksOnThread();
            long lastNotificationSentTime = arx.getSuperAdminLogFile().getLastNotificationSentTime();

            debugEvidence.write("\n<li>Previous send time: ");
            SectionUtil.nicePrintDateAndTime(debugEvidence,lastNotificationSentTime);

            // we pick up the time here, at the beginning, so that any new
            // events created AFTER this time, but before the end of this routine are
            // not lost during the processing.
            long processingStartTime = System.currentTimeMillis();
            debugEvidence.write("</li>\n<li>Email being sent at: ");
            SectionUtil.nicePrintDateAndTime(debugEvidence, processingStartTime);
            debugEvidence.write("</li>");


            // loop thru all the profiles to send out the email.
            UserProfile[] ups = UserManager.getAllUserProfiles();
            for (UserProfile up : ups) {
                handleOneUser(cog, arx, up, debugEvidence, processingStartTime);

                //this clears locks if there was an error during sending
                NGPageIndex.clearLocksHeldByThisThread();
            }

            // at the very last moment, if all was successful, mark down the
            // time that we sent it all.
            SuperAdminLogFile.getInstance(cog).setLastNotificationSentTime(processingStartTime,
                    debugEvidence.toString());

            //save all the times that we set on the user profiles
            UserManager.writeUserProfilesToFile();

        } catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.send.daily.digest", null, e);
        } finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
    }

    private static void handleOneUser(Cognoscenti cog, AuthRequest arx, UserProfile up,
            Writer debugEvidence, long processingStartTime) {
        try {
            NGPageIndex.assertNoLocksOnThread();

            String realAddress = up.getPreferredEmail();
            if (realAddress == null || realAddress.length() == 0) {
                debugEvidence.write("\n<li>User has no email address: ");
                HTMLWriter.writeHtml(debugEvidence, up.getUniversalId());
                debugEvidence.write("</li>");
                return;
            }

            long historyStartTime = up.getNotificationTime();

            //schema migration ... some users will not have this value set.
            //never go back more than twice the notification period.
            //This avoids getting a message with all possible history in it
            long earliestPossible = System.currentTimeMillis()-(up.getNotificationPeriod()*2*24*60*60*1000);
            if (historyStartTime<earliestPossible) {
                historyStartTime = earliestPossible;
            }

            //Calculate the time by adding the days and subtracting an hour to account for the time
            //it takes to run through all the users.  Don't want to kick a message to tomorrow just
            //because it is a few seconds earlier today.
            long nextNotificationMessageDue = historyStartTime + (up.getNotificationPeriod()*24*60*60*1000) - 3600000;
            if (processingStartTime < nextNotificationMessageDue ) {
                //not yet time to send another notification message
                return;
            }

            // if this address is configured, then all email will go to that
            // email address, instead of the address in the profile.
            //String overrideAddress = EmailSender.getProperty("overrideAddress");
            String toAddress = EmailSender.getProperty("overrideAddress");
            if (toAddress == null || toAddress.length() == 0) {
                toAddress = realAddress;
            }
            OptOutAddr ooa = new OptOutAddr(
                AddressListEntry.parseCombinedAddress(realAddress));


            StringWriter bodyOut = new StringWriter();
            AuthDummy clone = new AuthDummy(up, bodyOut, cog);
            clone.nowTime = processingStartTime;

            int numberOfUpdates = 0;

            clone.write("<html><body>\n");
            clone.write("<p>Hello ");
            up.writeLinkAlways(clone);
            clone.write(",</p>\n");

            clone.write("<p>This is a daily digest from Cognoscenti for the time period starting <b>");
            SectionUtil.nicePrintDateAndTime(clone.w,
                    historyStartTime);
            clone.write("</b> and ending <b>");
            SectionUtil.nicePrintDateAndTime(clone.w,
                    processingStartTime);
            clone.write("</b></p>\n");

            List<NGContainer> containers = new ArrayList<NGContainer>();
            for (NotificationRecord record : up.getNotificationList()) {
                NGContainer ngc = clone.getCogInstance().getProjectByKeyOrFail(record.getPageKey());

                // users might have items on the notification list that don't exist, because
                // they signed up for notification, and then the project was deleted.
                if (ngc != null) {
                    containers.add(ngc);
                }
            }

            if (containers.size() > 0) {
                clone.write("<div style=\"margin-top:15px;margin-bottom:20px;\"><span style=\"font-size:24px;font-weight:bold;\">Workspace Updates</span>&nbsp;&nbsp;&nbsp;");
                numberOfUpdates += constructDailyDigestEmail(clone, containers,
                        historyStartTime, processingStartTime);
            }

            if (clone.isSuperAdmin(up.getKey())) {
                String doublecheck = clone.getSystemProperty("superAdmin");
                if (up.getKey().equals(doublecheck)) {
                    List<SiteRequest> delayedSites = SiteReqFile.scanAllDelayedSiteReqs();
                    numberOfUpdates += delayedSites.size();
                    writeDelayedSiteList(clone, delayedSites);
                } else {
                    debugEvidence.write("\n<li>isSuperAdmin returned wrong result in double check test</li>");
                }
            }
            int numTasks = formatTaskListForEmail(clone, up);

            int numReminders = writeReminders(clone, up);

            clone.write("</body></html>");
            clone.flush();

            //very important.  Don't hold on to the locks while sending the email because if the
            //email server is slow (and we have one that is) then all those pages are locked
            //while talking to the email server.   This frees the locks that are no longer needed.
            NGPageIndex.clearLocksHeldByThisThread();

            if ((numberOfUpdates > 0) || numTasks > 0) {
                String thisSubj = "Daily Digest - " + numberOfUpdates
                        + " updates, " + numTasks + " tasks, "
                        + numReminders + " reminders.";

                //Actually SEND the email here
                EmailSender.quickEmail(ooa, null, thisSubj, bodyOut.toString(), cog);


                debugEvidence.write("\n<li>");
                HTMLWriter.writeHtml(debugEvidence, thisSubj);
                debugEvidence.write(" for ");
                HTMLWriter.writeHtml(debugEvidence, up.getPreferredEmail());
                debugEvidence.write("</li>");
                up.setNotificationTime(processingStartTime);
            } else {
                debugEvidence.write("\n<li>nothing for ");
                HTMLWriter.writeHtml(debugEvidence,
                        up.getPreferredEmail());
                debugEvidence.write("</li>");
            }
        } catch (Exception e) {
            EmailSender.threadLastMsgException = e;
            arx.logException(
                    "Error while sending daily update message", e);
            // for some reason if there an error sending an email to a particular person,
            // then just ignore that request and proceed with the other requests.
            try {
                debugEvidence
                        .write("\n\n<li>Unable to send the Email notification to the User : ");
                HTMLWriter.writeHtml(debugEvidence, up.getName());
                debugEvidence.write("[");
                HTMLWriter.writeHtml(debugEvidence, up.getUniversalId());
                debugEvidence.write("] because ");
                HTMLWriter.writeHtml(debugEvidence, e.toString());
            }
            catch (Exception eeeeee) {
                System.out.println("Exception while reporting an exception sending daily digest email to user: "+eeeeee);
            }
        }
    }

    /**
     * Returns the total number of history records actually found.
     */
    public static int constructDailyDigestEmail(AuthRequest clone,
            List<NGContainer> containers,
            long historyRangeStart, long historyRangeEnd) throws Exception {
        int totalHistoryCount = 0;
        boolean needsFirst = true;

        for (NGContainer container : containers) {
            List<HistoryRecord> histRecs = container.getHistoryRange(
                    historyRangeStart, historyRangeEnd);
            if (histRecs.size() == 0) {
                // skip this if there is nothing to show
                continue;
            }
            String url = clone.retPath
                    + clone.getDefaultURL(container);

            if (needsFirst) {
                clone.write("<a href=\"");
                clone.write(clone.baseURL);
                clone.write("v/");
                clone.writeURLData(clone.getUserProfile().getKey());
                clone.write("/userAlerts.htm\">View Latest</a></div>");

                needsFirst = false;
            }

            clone.write("\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">");
            clone.write("<thead>");
            clone.write("\n<tr>");
            clone.write("\n<td style=\"height:30px\" colspan=\"2\" valign=\"top\">");

            clone.write("<h4><img border=\"0\" align=\"middle\" src=\"");
            clone.write(clone.baseURL);
            clone.write("assets/iconProject.png");
            clone.write("\" alt=\"Workspace");
            clone.write("\"/>&nbsp;&nbsp;<a href=\"");

            clone.write(url);
            clone.write("\">");
            clone.writeHtml(container.getFullName());
            clone.write("</a></h4></td>");
            clone.write("\n</tr>");
            clone.write("\n</thead>");
            clone.write("<tbody>");

            for (HistoryRecord history : histRecs) {
                ++totalHistoryCount;

                clone.write("<tr>");
                clone.write("<td style=\"width:25px\"></td><td>&bull;&nbsp;&nbsp;");
                // dummy link for the sorting purpose.
                clone.write("<a href=\"");
                clone.write(Long.toString(history.getTimeStamp()));
                clone.write("\"></a>");

                // Get Localized string
                history.writeLocalizedHistoryMessage(container, clone);
                SectionUtil.nicePrintTime(clone.w, history.getTimeStamp(),
                        clone.nowTime);
                if (history.getContextType() != HistoryRecord.CONTEXT_TYPE_PERMISSIONS
                        && history.getComments() != null
                        && history.getComments().length() > 0) {
                    clone.write("<br/>Comments: &raquo;&nbsp;");
                    clone.writeHtml(history.getComments());
                }

                clone.write("</td>");
                clone.write("</tr>");
                clone.write("\n<tr>");
                clone.write("\n  <td style=\"height:5px\"></td>");
                clone.write("\n</tr>");
            }
            clone.write("\n<tr>");
            clone.write("\n  <td style=\"height:15px\"></td>");
            clone.write("\n</tr>");
            clone.write("</tbody>");
            clone.write("</table>");
        }
        return totalHistoryCount;
    }

    private static void writeDelayedSiteList(AuthRequest clone,
            List<SiteRequest> delayedSites) throws Exception {
        clone.write("<table width=\"80%\" class=\"Design8\">");
        clone.write("<thead>");
        clone.write("<tr>");
        clone.write("<th>Site Name</th>");
        clone.write("<th>Requested By</th>");
        clone.write("<th>Requested Date</th>");
        clone.write("<th>Action</th>");
        clone.write("</tr>");
        clone.write("</thead>");
        clone.write("<tbody>");
        for (int i = 0; i < delayedSites.size(); i++) {
            SiteRequest details = delayedSites.get(i);
            clone.write("\n <tr " + ((i % 2 == 0) ? "class=\"Odd\"" : " ")
                    + ">");
            clone.write("<td>");
            clone.write(details.getName());
            clone.write("</td>");
            clone.write("<td>");
            clone.write(details.getUniversalId());
            clone.write("</td>");
            clone.write("<td>");
            clone.writeHtml(SectionUtil.getNicePrintDate(details.getModTime()));
            clone.write("</td>");
            clone.write("<td>");
            clone.write("<a href=\"");
            clone.write(clone.baseURL);
            clone.write("v/approveAccountThroughMail.htm?requestId=");
            clone.writeURLData(details.getRequestId());
            clone.write("\">Click here to Accept/Deny this request</a>");
            clone.write("</td>");
            clone.write("</tr>");
        }
        clone.write("</tbody>");
        clone.write("</table>");
    }

    private static int formatTaskListForEmail(AuthRequest ar, UserProfile up)
            throws Exception {
        int taskNum = 0;
        List<ProjectGoal> tasks = getActiveTaskList(up, ar.getCogInstance());
        if (tasks.size() == 0) {
            return 0;
        }
        ar.write("<div style=\"margin-top:25px;margin-bottom:5px;\"><span style=\"font-size:24px;font-weight:bold;\">Task Updates</span>&nbsp;&nbsp;&nbsp;");

        ar.write("<a href=\"");
        ar.write(ar.baseURL);
        ar.write("v/");
        ar.writeURLData(up.getKey());
        ar.write("/userActiveTasks.htm\">View Latest</a></div>");
        ar.write("\n <table width=\"600\" class=\"Design8\">");
        ar.write("\n <col width=\"30\"/>");
        ar.write("\n <col width=\"500\"/>");
        ar.write("\n <col width=\"100\"/>");
        ar.write("\n <thead> ");
        ar.write("\n <tr>");
        ar.write("\n <th> </th> ");
        ar.write("\n <th>Name</th> ");
        ar.write("\n <th>Due</th>");
        ar.write("\n </tr> ");
        ar.write("\n </thead> ");
        ar.write("\n <tbody>");
        for (ProjectGoal pg : tasks) {
            taskNum++;
            NGPageIndex ngpi = pg.ngpi;
            GoalRecord task = pg.goal;

            ar.write("\n <tr");
            if (taskNum % 2 == 0) {
                ar.write(" class=\"Odd\"");
            }
            ar.write(" valign=\"top\">");

            // task state, name and the page link.
            ar.write("\n <td>");
            ar.write("<a href=\"");
            writeGoalLinkUrl(ar, ngpi, task, up);
            ar.write("\" title=\"access current status of task\">");
            ar.write("<img border=\"0\" align=\"absbottom\" src=\"");
            ar.write(ar.baseURL);
            ar.write(BaseRecord.stateImg(task.getState()));
            ar.write("\" alt=\"");
            ar.writeHtml(GoalRecord.stateName(task.getState()));
            ar.write("\"/></a>&nbsp;</td><td>");
            ar.write("<a href=\"");
            writeGoalLinkUrl(ar, ngpi, task, up);
            ar.write("\" title=\"access current status of task\">");
            ar.writeHtml(task.getSynopsis());
            ar.write("</a> - <a href=\"");
            writeProcessLinkUrl(ar, ngpi);
            ar.write("\" title=\"See the workspace containing this task\">");
            ar.writeHtml(ngpi.containerName);
            ar.write("</a>");
            ar.write("\n<br/>Status: ");
            ar.writeHtml(task.getStatus());
            ar.write("\n </td>");

            // due date column.
            ar.write("\n <td>");
            if (task.getDueDate() > 0) {
                ar.write(SectionUtil.getNicePrintDate(task.getDueDate()));
            }
            ar.write("\n </td>");
            ar.write("\n </tr>");
        }
        ar.write("\n </tbody>");
        ar.write("\n </table>");
        return taskNum;
    }

    /**
     * Writes a URL of the task details page for a given task
     * along with the magic number and user key for anonymous access.
     */
    private static void writeGoalLinkUrl(AuthRequest ar, NGPageIndex ngpi,
            GoalRecord gr, UserProfile up) throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(ngpi.pageBookKey);
        ar.write("/");
        ar.writeURLData(ngpi.containerKey);
        ar.write("/task");
        ar.writeURLData(gr.getId());
        ar.write(".htm");
        ar.write("?");
        NGPage ngp = (NGPage) ngpi.getContainer();
        ar.write(AccessControl.getAccessGoalParams(ngp, gr));
        ar.write("&ukey=");
        ar.writeURLData(up.getKey());
    }

    private static void writeProcessLinkUrl(AuthRequest ar, NGPageIndex ngpi)
            throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(ngpi.pageBookKey);
        ar.write("/");
        ar.writeURLData(ngpi.containerKey);
        ar.write("/goalList.htm");
    }

    private static int writeReminders(AuthRequest ar, UserProfile up) throws Exception {

        NGPageIndex.assertNoLocksOnThread();
        int noOfReminders = 0;

        for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers()) {
            // start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject()) {
                continue;
            }
            int count = 0;
            NGPage aPage = ngpi.getPage();

            ReminderMgr rMgr = aPage.getReminderMgr();
            Vector<ReminderRecord> rVec = rMgr.getUserReminders(up);
            for (ReminderRecord reminder : rVec) {
                if ("yes".equals(reminder.getSendNotification())) {
                    if (noOfReminders == 0) {
                        ar.write("<div style=\"margin-top:25px;margin-bottom:5px;\">");
                        ar.write("<span style=\"font-size:24px;font-weight:bold;\">");
                        ar.write("Reminders To Share Document</span>&nbsp;&nbsp;&nbsp;");

                        ar.write("<a href=\"");
                        ar.write(ar.baseURL);
                        ar.write("v/");
                        ar.writeURLData(up.getKey());
                        ar.write("/userActiveTasks.htm\">View Latest </a>");
                        ar.write("(Below is list of reminders of documents which you are requested to upload.)</div>");
                        ar.write("\n <table width=\"800\" class=\"Design8\">");
                        ar.write("\n <thead> ");
                        ar.write("\n <tr>");
                        ar.write("\n <th></th> ");
                        ar.write("\n <th>Document to upload</th> ");
                        ar.write("\n <th>Requested By</th> ");
                        ar.write("\n <th>Sent On</th>");
                        ar.write("\n <th>Workspace</th>");
                        ar.write("\n </tr> ");
                        ar.write("\n </thead> ");
                        ar.write("\n <tbody>");
                    }

                    ar.write("\n <tr");
                    if (count % 2 == 0) {
                        ar.write(" class=\"Odd\"");
                    }
                    ar.write(" valign=\"top\">");

                    ar.write("\n <td>");
                    ar.write("<a href=\"");
                    writeReminderLink(ar, up, aPage, reminder);
                    ar.write("\" title=\"access details of reminder\">");
                    ar.write("<img src=\"");
                    ar.write(ar.baseURL);
                    ar.write("assets/iconUpload.png\" />");
                    ar.write("</a> ");
                    ar.write("</td>");

                    ar.write("\n <td>");

                    ar.write("<a href=\"");
                    writeReminderLink(ar, up, aPage, reminder);
                    ar.write("\" title=\"access details of reminder\">");
                    ar.writeHtml(reminder.getSubject());
                    ar.write("</a> ");

                    ar.write("\n </td>");

                    ar.write("\n <td>");
                    (new AddressListEntry(reminder.getModifiedBy()))
                            .writeLink(ar);
                    // ar.write(reminder.getModifiedBy());
                    ar.write("\n </td>");

                    ar.write("\n <td>");
                    SectionUtil.nicePrintTime(ar, reminder.getModifiedDate(),
                            ar.nowTime);
                    ar.write("\n </td>");

                    ar.write("\n <td>");
                    ar.write("<a href='");
                    ar.write(ar.baseURL);
                    ar.write("t/");
                    ar.writeURLData(ngpi.pageBookKey);
                    ar.write("/");
                    ar.writeURLData(ngpi.containerKey);
                    ar.write("/reminders.htm' >");
                    ar.writeHtml(aPage.getFullName());
                    ar.write("</a>");
                    ar.write("\n </td>");

                    ar.write("\n </tr>");

                    noOfReminders++;
                }
            }
        }
        ar.write("\n </tbody>");
        ar.write("\n </table>");
        return noOfReminders;
    }

    private static void writeReminderLink(AuthRequest ar, UserProfile up,
            NGPage aPage, ReminderRecord reminder) throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(aPage.getSiteKey());
        ar.write("/");
        ar.writeURLData(aPage.getKey());
        ar.write("/remindAttachment.htm?rid=");
        ar.writeURLData(reminder.getId());
        ar.write("&");
        ar.write(AccessControl.getAccessReminderParams(aPage, reminder));
        ar.write("&emailId=");
        ar.writeURLData(up.getPreferredEmail());
    }

    // operation get task list.
    private static List<ProjectGoal> getActiveTaskList(UserProfile up, Cognoscenti cog) throws Exception {
        NGPageIndex.assertNoLocksOnThread();

        Vector<ProjectGoal> activeTask = new Vector<ProjectGoal>();

        if (up == null) {
            throw new Exception("can not get list of action items for userwhich is null");
        }

        for (NGPageIndex ngpi : cog.getAllContainers()) {
            // start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject()) {
                continue;
            }
            NGPage aPage = ngpi.getPage();
            for (GoalRecord gr : aPage.getAllGoals()) {
                if (gr.isPassive()) {
                    //ignore tasks that are from other servers
                    continue;
                }
                if (!gr.isAssignee(up)) {
                    continue;
                }
                int state = gr.getState();
                if (state == BaseRecord.STATE_ERROR) {
                    if (gr.isAssignee(up)) {
                        activeTask.add(new ProjectGoal(gr, aPage, cog));
                    }
                }
                else if (state == BaseRecord.STATE_ACCEPTED || state == BaseRecord.STATE_OFFERED
                        || state == BaseRecord.STATE_WAITING) {
                    // the assignee should see this task in the active task list.
                    if (gr.isAssignee(up)) {
                        activeTask.add(new ProjectGoal(gr, aPage, cog));
                    }
                }
            }
        }

        return activeTask;
    }

    private static class ProjectGoal {

        public GoalRecord goal;
        public NGPageIndex ngpi;


        public ProjectGoal(GoalRecord aGoal, NGPage aPage, Cognoscenti cog) throws Exception {
            goal = aGoal;
            ngpi = cog.getContainerIndexByKey(aPage.getKey());
        }
    }

}
