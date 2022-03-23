package com.purplehillsbooks.weaver.mail;

import java.io.File;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthDummy;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.BaseRecord;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.OptOutAddr;
import com.purplehillsbooks.weaver.ReminderMgr;
import com.purplehillsbooks.weaver.ReminderRecord;
import com.purplehillsbooks.weaver.SectionUtil;
import com.purplehillsbooks.weaver.SiteReqFile;
import com.purplehillsbooks.weaver.SiteRequest;
import com.purplehillsbooks.weaver.SuperAdminLogFile;
import com.purplehillsbooks.weaver.UserCache;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.NGException;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;
import com.purplehillsbooks.streams.HTMLWriter;
import com.purplehillsbooks.streams.MemFile;

public class DailyDigest {

    private static boolean forceIt = false;

    public static void forceDailyDigest(AuthRequest arx, Cognoscenti cog) throws Exception {
        forceIt = true;
        sendDailyDigest(arx, cog);
        forceIt = false;
    }


    /*
     * This method loops through all known users (with profiles) and sends an
     * email with their tasks on it.
     */
    public static void sendDailyDigest(AuthRequest arx, Cognoscenti cog) throws Exception {
        MemFile debugStuff = new MemFile();
        Writer debugWriter = debugStuff.getWriter();
        System.out.println("DAILYDIGEST: called at "+SectionUtil.currentTimeString());
        JSONObject logFile = new JSONObject();
        JSONArray logEntries = new JSONArray();
        logFile.put("events", logEntries);
        File dailyDigestFile = new File(cog.getConfig().getUserFolderOrFail(), "DailyDigestLog.json");

        try {
            NGPageIndex.assertNoLocksOnThread();
            long lastNotificationSentTime = arx.getSuperAdminLogFile().getLastNotificationSentTime();

            debugWriter.write("\n<li>Previous send time: ");
            SectionUtil.nicePrintDateAndTime(debugWriter,lastNotificationSentTime);
            logFile.put("PreviousSend", lastNotificationSentTime);

            // we pick up the time here, at the beginning, so that any new
            // events created AFTER this time, but before the end of this routine are
            // not lost during the processing.
            long processingStartTime = System.currentTimeMillis();
            long threeYearsAgo = processingStartTime - (3L*365L*24L*3600L*1000L);

            debugWriter.write("</li>\n<li>Email being sent at: ");
            SectionUtil.nicePrintDateAndTime(debugWriter, processingStartTime);
            debugWriter.write("</li>\n<li>Disabling users who have not accessed since: ");
            SectionUtil.nicePrintDateAndTime(debugWriter, threeYearsAgo);
            debugWriter.write("</li>");
            logFile.put("CurrentSend", processingStartTime);
            logFile.put("UserDisableLimit", threeYearsAgo);


            // loop thru all the profiles to send out the email.
            for (UserProfile up : arx.getCogInstance().getUserManager().getAllUserProfiles()) {
                JSONObject userObject = new JSONObject();
                logEntries.put(userObject);
                userObject.put("key",  up.getKey());
                userObject.put("name",  up.getName());
                userObject.put("email",  up.getUniversalId());

                if (up.getDisabled()) {
                    userObject.put("conclusion", "Disabled");
                    //skip all disabled users
                    continue;
                }
                if (up.getLastLogin() > 0 && up.getLastLogin() < threeYearsAgo) {
                    //automatically disable users who have not logged in in three years
                    //TODO: what should be do if they have NEVER logged in?
                    debugWriter.write("\n<li>User automatically disabled after three years no access: "+up.getUniversalId()+"</li>");
                    System.out.println("DAILYDIGEST: User automatically disabled after three years no access: "+up.getUniversalId());
                    up.setDisabled(true);
                    userObject.put("conclusion", "Disabled Now");
                    continue;
                }

                handleOneUser(cog, arx, up, debugWriter, processingStartTime, userObject);

                //this clears locks if there was an error during sending
                NGPageIndex.clearLocksHeldByThisThread();
            }

            debugWriter.flush();
            // at the very last moment, if all was successful, mark down the
            // time that we sent it all.
            SuperAdminLogFile.getInstance(cog).setLastNotificationSentTime(processingStartTime,
                    debugStuff.toString());

            //save all the times that we set on the user profiles
            cog.getUserManager().saveUserProfiles();



        } catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.send.daily.digest", null, e);
        } finally {
            NGPageIndex.clearLocksHeldByThisThread();
            logFile.writeToFile(dailyDigestFile);
        }
    }

    private static void handleOneUser(Cognoscenti cog, AuthRequest arx, UserProfile up,
            Writer debugEvidence, long processingStartTime, JSONObject userLog) {
        try {
            NGPageIndex.assertNoLocksOnThread();

            String realAddress = up.getPreferredEmail();
            if (realAddress == null || realAddress.length() == 0) {
                debugEvidence.write("\n<li>User has no email address: ");
                HTMLWriter.writeHtml(debugEvidence, up.getUniversalId());
                debugEvidence.write("</li>");
                userLog.put("conclusion", "No Email Address");
                return;
            }

            //this is the last time they were notified.
            long historyStartTime = up.getNotificationTime();

            //schema migration ... some users will not have this value set.
            //never go back more than twice the notification period.
            //This avoids getting a message with all possible history in it
            long earliestPossible = System.currentTimeMillis()-(up.getNotificationPeriod()*2L*24*60*60*1000);
            if (historyStartTime<earliestPossible) {
                historyStartTime = earliestPossible;
            }

            //Calculate the time by adding the days and subtracting an hour to account for the time
            //it takes to run through all the users.  Don't want to kick a message to tomorrow just
            //because it is a few seconds earlier today.
            long timeSinceLastSend = processingStartTime - historyStartTime;
            long hoursSinceLastSend = timeSinceLastSend / (1000*60*60);

            //due to processing delays and integer arithmetic this will be either 23 or 24
            //add a couple hours before dividing by 24 to round to the number of days
            long daysSinceLastSend = ((hoursSinceLastSend+2) / 24);

            if (daysSinceLastSend < up.getNotificationPeriod() && !forceIt) {
                //not yet time to send another notification message
                debugEvidence.write("\n<li>not yet time to send to user ");
                HTMLWriter.writeHtml(debugEvidence, up.getPreferredEmail());
                debugEvidence.write("with period "+up.getNotificationPeriod()+", only been "+daysSinceLastSend+" days.</li>");
                userLog.put("conclusion", "Too Soon");
                return;
            }

            MemFile body = new MemFile();
            AuthDummy clone = new AuthDummy(up, body.getWriter(), cog);
            clone.nowTime = processingStartTime;

            //the user cache contains all the action items, open rounds, and proposals for a user
            UserCache userCache = cog.getUserCacheMgr().getCache(up.getKey());
            //because this is background, it is a good time to refresh the data in the cache
            userCache.refreshCache(cog);

            userLog.put("ActionItems", userCache.getActionItems().length());
            userLog.put("OpenRounds",  userCache.getOpenRounds().length());
            userLog.put("Proposals",   userCache.getProposals().length());

            JSONObject data = userCache.getAsJSON();
            MemFile mf = new MemFile();
            Writer memWriter = mf.getWriter();
            data.write(memWriter);
            memWriter.flush();
            data = new JSONObject(new JSONTokener(mf.getReader()));

            data.put("baseURL", clone.baseURL);
            data.put("to",up.getJSON());
            data.put("timeStart",historyStartTime);
            data.put("timeEnd",processingStartTime);

            JSONArray notifyList = new JSONArray();
            for (String noteKey : up.getNotificationList()) {
                NGPageIndex ngpi = cog.getWSByCombinedKey(noteKey);
                if (ngpi == null) {
                    //ignoring any reference to a workspace that no longer exists
                    continue;
                }
                if (!ngpi.isWorkspace()) {
                    //ignore site objects
                    continue;
                }
                if (ngpi.isDeleted) {
                    //ignore any deleted workspaces
                    continue;
                }
                NGWorkspace ngp = ngpi.getWorkspace();
                if (ngp.isDeleted()) {
                    //ignore any deleted workspaces
                    continue;
                }
                NGBook site = ngp.getSite();
                if (site.isDeleted() || site.isMoved()) {
                    //ignore any workspaces in deleted or moved sites.
                    continue;
                }

                List<HistoryRecord> histRecs = ngp.getHistoryRange(
                        historyStartTime, processingStartTime);
                if (histRecs.size() == 0) {
                    // skip this if there is no history
                    continue;
                }
                JSONObject oneWorkspace = ngpi.getJSON4List();
                JSONArray history = new JSONArray();
                for (HistoryRecord oneHist : histRecs) {
                    history.put(oneHist.getJSON(ngp, clone));
                }
                oneWorkspace.put("history",history);
                notifyList.put(oneWorkspace);
            }
            data.put("notifyList", notifyList);

            OptOutAddr ooa = new OptOutAddr(
                AddressListEntry.parseCombinedAddress(realAddress));

            int numberOfUpdates = 0;

            clone.write("<html><body>\n");
            clone.write("<p>Hello ");
            up.writeLinkAlways(clone);
            clone.write(",</p>\n");

            clone.write("<p>This is a daily digest from Weaver for the time period starting <b>");
            SectionUtil.nicePrintDateAndTime(clone.w,
                    historyStartTime);
            clone.write("</b> and ending <b>");
            SectionUtil.nicePrintDateAndTime(clone.w,
                    processingStartTime);
            clone.write("</b></p>\n");

            int numTasks = 0;

            {
                List<NGPageIndex> containers = new ArrayList<NGPageIndex>();
                for (String noteKey : up.getNotificationList()) {
                    NGPageIndex ngci = clone.getCogInstance().getWSByCombinedKey(noteKey);

                    // users might have items on the notification list that don't exist, because
                    // they signed up for notification, and then the project was deleted.
                    //Or because it was moved and we don't know the new name.
                    if (ngci != null) {
                        //apparently it is possible for people to get a 'Site' in their
                        //notify list.
                        if (ngci.isWorkspace()) {
                            containers.add(ngci);
                        }
                    }
                }
                userLog.put("notifyCount", containers.size());

                if (containers.size() > 0) {
                    clone.write("<div style=\"margin-top:15px;margin-bottom:20px;\"><span style=\"font-size:24px;font-weight:bold;\">Workspace Updates</span>&nbsp;&nbsp;&nbsp;");
                    NGPageIndex.clearLocksHeldByThisThread();
                    numberOfUpdates += constructDailyDigestEmail(clone, containers,
                            historyStartTime, processingStartTime);
                    clone.write("</div>");
                }

                if (clone.isSuperAdmin(up.getKey())) {
                    
                    //TODO: not sure that this double check is valid.   I think 
                    //superadmin value can have multiple ids now, so this is wrong
                    //however I am not seeing the error message in debug out put so not sure.
                    String doublecheck = clone.getSystemProperty("superAdmin");
                    if (up.getKey().equals(doublecheck)) {
                        SiteReqFile siteReqFile = new SiteReqFile(cog);
                        List<SiteRequest> delayedSites = siteReqFile.scanAllDelayedSiteReqs();
                        numberOfUpdates += delayedSites.size();
                        writeDelayedSiteList(clone, delayedSites);
                    } else {
                        debugEvidence.write("\n<li>isSuperAdmin returned wrong result in double check test</li>");
                    }
                }

                //formatTaskListForEmail is going to clear locks, so clear here before entering
                NGPageIndex.clearLocksHeldByThisThread();
                numTasks = formatTaskListForEmail(clone, up);
                userLog.put("tasks", numTasks);

                //writeReminders will walk through a bunch of pages and all locks must be
                //cleared before entering it.  Clean up locks from containers processing.
                NGPageIndex.clearLocksHeldByThisThread();
            }

            int numReminders = writeReminders(clone, up);
            userLog.put("reminders", numReminders);

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
                EmailSender.generalMailToOne(ooa, up.getAddressListEntry(), thisSubj, body.toString(), cog);


                debugEvidence.write("\n<li>");
                HTMLWriter.writeHtml(debugEvidence, thisSubj);
                debugEvidence.write(" for ");
                HTMLWriter.writeHtml(debugEvidence, up.getPreferredEmail());
                debugEvidence.write("</li>");
                up.setNotificationTime(processingStartTime);
                userLog.put("conclusion", "Email Sent");
            } else {
                debugEvidence.write("\n<li>nothing for ");
                HTMLWriter.writeHtml(debugEvidence,
                        up.getPreferredEmail());
                debugEvidence.write("</li>");
                userLog.put("conclusion", "Nothing to Report");
            }

        } catch (Exception e) {
            EmailSender.threadLastMsgException = e;
            arx.logException(
                    "Error while sending daily update message", e);
            // for some reason if there an error sending an email to a particular person,
            // then just ignore that request and proceed with the other requests.
            try {
                userLog.put("conclusion", "Error");
                userLog.put("error", e.toString());
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
            List<NGPageIndex> containers,
            long historyRangeStart, long historyRangeEnd) throws Exception {
        NGPageIndex.assertNoLocksOnThread();
        int totalHistoryCount = 0;
        boolean needsFirst = true;

        for (NGPageIndex ngpi : containers) {
            if (ngpi==null) {
                throw new Exception("How did I get a null value by iterating a List collection?");
            }
            if (!ngpi.isWorkspace()) {
                //ignore sites
                continue;
            }
            try {
                NGWorkspace container = ngpi.getWorkspace();
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
                    clone.write("/UserAlerts.htm\">View Latest</a></div>");

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
            catch (Exception e) {
                throw new JSONException("Error while processing container: {0}", e, ngpi.containerName);
            }
            finally {
                NGPageIndex.clearLocksHeldByThisThread();
            }
        }
        return totalHistoryCount;
    }

    
    /** 
     * this is a reminder to super admins that there are sites waiting to be 
     * granted or not.   Not sure this is needed.
     * @param clone
     * @param delayedSites
     * @throws Exception
     */
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
            clone.write(details.getSiteName());
            clone.write("</td>");
            clone.write("<td>");
            clone.write(details.getRequester());
            clone.write("</td>");
            clone.write("<td>");
            clone.writeHtml(SectionUtil.getNicePrintDate(details.getModTime()));
            clone.write("</td>");
            clone.write("<td>");
            clone.write("<a href=\"");
            clone.write(clone.baseURL);
            clone.write("v/su/requestedAccounts.htm\">Click here to review list</a>");
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
        ar.write("/UserActiveTasks.htm\">View Latest</a></div>");
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
        ar.writeURLData(ngpi.wsSiteKey);
        ar.write("/");
        ar.writeURLData(ngpi.containerKey);
        ar.write("/task");
        ar.writeURLData(gr.getId());
        ar.write(".htm");
        ar.write("?");
        NGWorkspace ngp = ngpi.getWorkspace();
        ar.write(AccessControl.getAccessGoalParams(ngp, gr));
        ar.write("&ukey=");
        ar.writeURLData(up.getKey());
    }

    private static void writeProcessLinkUrl(AuthRequest ar, NGPageIndex ngpi)
            throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(ngpi.wsSiteKey);
        ar.write("/");
        ar.writeURLData(ngpi.containerKey);
        ar.write("/goalList.htm");
    }

    private static int writeReminders(AuthRequest ar, UserProfile up) throws Exception {

        int noOfReminders = 0;

        for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers()) {

            noOfReminders = writeOneReminder(ar, up, ngpi, noOfReminders);

        }
        ar.write("\n </tbody>");
        ar.write("\n </table>");
        return noOfReminders;
    }

    private static int writeOneReminder(AuthRequest ar, UserProfile up, NGPageIndex ngpi, int noOfReminders)
            throws Exception {

        NGPageIndex.assertNoLocksOnThread();
        if (!ngpi.isWorkspace()) {
            return noOfReminders;
        }
        int count = 0;
        NGWorkspace aPage = ngpi.getWorkspace();

        ReminderMgr rMgr = aPage.getReminderMgr();
        List<ReminderRecord> rVec = rMgr.getUserReminders(up);
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
                    ar.write("/UserActiveTasks.htm\">View Latest </a>");
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
                ar.writeURLData(ngpi.wsSiteKey);
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

        // clear any locks made in this handling
        NGPageIndex.clearLocksHeldByThisThread();
        return noOfReminders;
    }



    private static void writeReminderLink(AuthRequest ar, UserProfile up,
            NGWorkspace aPage, ReminderRecord reminder) throws Exception {
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

        ArrayList<ProjectGoal> activeTask = new ArrayList<ProjectGoal>();

        if (up == null) {
            throw new Exception("can not get list of action items for userwhich is null");
        }

        for (NGPageIndex ngpi : cog.getAllContainers()) {
            // start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();
            if (!ngpi.isWorkspace() || ngpi.isDeleted) {
                continue;
            }
            NGWorkspace aPage = ngpi.getWorkspace();
            if (aPage.isDeleted() || aPage.isFrozen()) {
                continue;
            }
            NGBook site = aPage.getSite();
            if (site.isDeleted() || site.isMoved() || site.isFrozen()) {
                //ignore any workspaces in deleted, frozen, or moved sites.
                continue;
            }
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


        public ProjectGoal(GoalRecord aGoal, NGWorkspace aPage, Cognoscenti cog) throws Exception {
            goal = aGoal;
            ngpi = cog.getWSBySiteAndKey(aPage.getSiteKey(), aPage.getKey());
        }
    }

}
