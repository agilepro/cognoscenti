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
 */

package org.socialbiz.cog.api;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AttachmentVersion;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.IdGenerator;
import org.socialbiz.cog.License;
import org.socialbiz.cog.LicenseForUser;
import org.socialbiz.cog.MimeTypes;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NoteRecord;
import org.socialbiz.cog.SectionWiki;
import org.socialbiz.cog.UtilityMethods;
import org.socialbiz.cog.WikiConverter;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;

/**
 * This servlet serves up pages using the following URL format:
 *
 * http://{machine:port}/{application}/api/{site}/{project}/{resource}
 *
 * http://{machine:port}/{application} is whatever you install the application to on
 * Tomcat could be multiple levels deep.
 *
 * "api" is fixed. This is the indicator within the system that says
 * this servlet will be invoked.
 *
 * {site} unique identifier for the site.
 *
 * {project} unique identifier for the project.
 *
 * All of the stuff above can be abbreviated {site-proj}
 * so the general pattern is:
 * {site-proj}/{resource}
 *
 * {resource} specifies the resource you are trying to access.
 * See below for the details.  NOTE: you only receive resources
 * that you have access to.  Resources you do not have access
 * to will not be included in the list, and will not be accessible
 * in any way.
 *
 * {site-proj}/summary.json
 * This will list all the goals, notes, and attachments to this project.
 * and include some info like modified date, owner, and file size.
 *
 * {site-proj}/doc{docid}/docname.ext
 * documents can be accessed directly with this, the docname and extension
 * is the name of the document and the proper extension, but can actually
 * be anything.  The only thing that matters is the docid.
 * A PUT to this address will create a new version of the document.
 *
 * {site-proj}/doc{docid}-{version}/docname.ext
 * Gets a version of the document directly if that version exists.
 * Again, the name is just so the browser works acceptably, the
 * document is found using docid and version alone.
 * You can not PUT to this, versions are immutable.
 *
 * If you want to create a new document attachment, this takes
 * three steps.
 * (1) get a temp file name to sent to.
 * {site-proj}/tempFile
 * this returns a file name and a file path for temp storage
 * (2) PUT the file to the temp URL
 * This file will remain there for a few minutes or hours
 * (3) POST to create the document with the details
 * {site-proj}/newDoc
 * This is passed the temp name, and the real name, only after
 * this call, the attachment is made permanent.
 *
 * {site-proj}/note{noteid}/note1.html
 * This will retrieve the contents of a note in HTML format
 * A PUT to this address will update the note
 *
 * {site-proj}/note{noteid}/note1.sp
 * This will retrieve the contents of a note in SmartPage Wiki format
 * A PUT to this address will update the note
 *
 * {site-proj}/goal{goalid}/goal.json
 * Will retrieve a goal in JSON format
 * A POST to this address will update the goal in JSON format
 */
@SuppressWarnings("serial")
public class APIServlet extends javax.servlet.http.HttpServlet {

    @Override
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        //this is an API to be read by others, so you have to set the CORS to
        //allow scripts to read this data from a browser.
        resp.setHeader("Access-Control-Allow-Origin",      req.getHeader("Origin"));
        resp.setHeader("Access-Control-Allow-Credentials", "true");
        resp.setHeader("Access-Control-Allow-Methods",     "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers",     "Authorization");

        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            System.out.println("API_GET: "+ar.getCompleteURL());
            if (!ar.getCogInstance().isInitialized()) {
                throw new Exception("Server is not ready to handle requests.");
            }

            doAuthenticatedGet(ar);
        }
        catch (Exception e) {
            streamException(e, ar);
        }
        finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }

    private void doAuthenticatedGet(AuthRequest ar)  throws Exception {

        try {
            ResourceDecoder resDec = new ResourceDecoder(ar);

            if (resDec.isSwagger){
                genSwagger(ar, resDec);
            }
            else if (resDec.isSite){
                genSiteListing(ar, resDec);
            }
            else if (resDec.isListing){
                genProjectListing(ar, resDec);
            }
            else if (resDec.isDoc) {
                streamDocument(ar, resDec);
            }
            else if (resDec.isGoal) {
                genGoalInfo(ar, resDec);
            }
            else if (resDec.isNote) {
                streamNote(ar, resDec);
            }
            else {
                throw new Exception("don't understand that resource URL: "+ar.getCompleteURL());
            }
            ar.flush();

        } catch (Exception e) {
            streamException(e, ar);
        }
    }

    @Override
    public void doPut(HttpServletRequest req, HttpServletResponse resp) {
        //this is an API to be read by others, so you have to set the CORS to
        //allow scripts to read this data from a browser.
        resp.setHeader("Access-Control-Allow-Origin","*");

        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        ar.resp.setContentType("application/json");
        try {
            System.out.println("API_PUT: "+ar.getCompleteURL());
            ResourceDecoder resDec = new ResourceDecoder(ar);

            if (resDec.isTempDoc) {
                receiveTemp(ar, resDec);
                System.out.println("    PUT: file written: "+resDec.tempName);
                JSONObject result = new JSONObject();
                result.put("responseCode", 200);
                result.write(ar.resp.getWriter(), 2, 0);
            }
            else {
                throw new Exception("Can not do a PUT to that resource URL: "+ar.getCompleteURL());
            }
            ar.flush();
        }
        catch (Exception e) {
            streamException(e, ar);
        }
    }

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse resp) {
        //this is an API to be read by others, so you have to set the CORS to
        //allow scripts to read this data from a browser.
        resp.setHeader("Access-Control-Allow-Origin","*");

        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        ar.resp.setContentType("application/json");
        try {
            System.out.println("API_POST: "+ar.getCompleteURL());
            ResourceDecoder resDec = new ResourceDecoder(ar);

            InputStream is = ar.req.getInputStream();
            JSONTokener jt = new JSONTokener(is);
            JSONObject objIn = new JSONObject(jt);
            is.close();

            String op = objIn.getString("operation");
            System.out.println("API_POST: operation="+op);
            if (op==null || op.length()==0) {
                throw new Exception("Request object needs to have a specified 'operation'."
                        +" None found.");
            }

            JSONObject responseObj = null;
            if (resDec.isSite) {
                responseObj = getSitePostResponse(ar, resDec, op, objIn);
            }
            else {
                responseObj = getProjectPostResponse(ar, resDec, op, objIn);
            }
            responseObj.write(ar.resp.getWriter(), 2, 0);
            ar.flush();
        }
        catch (Exception e) {
            streamException(e, ar);
        }
    }

    private void genSwagger(AuthRequest ar, ResourceDecoder resDec) throws Exception {

        JSONObject root = new JSONObject("{\"swagger\": \"2.0\"}");

        JSONObject info = new JSONObject("{\"title\": \"Cognoscenti\"}");
        info.put("description", "A collaborative application platform.");
        info.put("termsOfService", "This is the terms of service.");
        info.put("contact", "Cognoscenti");
        info.put("license", new JSONObject("{\"name\": \"Apache 2.0\",\"url\": \"http://www.apache.org/licenses/LICENSE-2.0.html\"}"));
        info.put("version", "Cognoscenti");
        root.put("info", info);

        String myUrl = ar.baseURL;
        int slashPos = myUrl.indexOf("://");
        if (slashPos<0) {
            throw new Exception("The BaseURL needs to look like a URL, and it must have a :// in it, but does not:  "+myUrl);
        }
        int slash2 = myUrl.indexOf("/", slashPos+3);
        if (slashPos<0) {
            throw new Exception("The BaseURL needs to look like a URL, and it must have a second slash in it, but does not:  "+myUrl);
        }
        root.put("host", myUrl.substring(slashPos+3, slash2));
        //swagger spec says that partial paths start with a slash, and don't end with them...
        root.put("basePath",  myUrl.substring(slash2));
        root.put("schemes", singleStringArray(myUrl.substring(0, slashPos)));
        root.put("consumes", singleStringArray("application/json"));
        root.put("produces", singleStringArray("application/json"));

        root.put("produces", getPathsObject());
        root.put("definitions", getDefinitionsObject());
        root.put("parameters", getParametersObject());
        root.put("responses", getResponsesObject());
        root.put("securityDefinitions", getSecurityDefinitionsArray());
        root.put("tags", getTagsArray());
        root.put("externalDocs", getExternalDocObject());

        ar.resp.setContentType("application/json");
        root.write(ar.resp.getWriter(), 2, 0);
        ar.flush();
    }


    private JSONArray singleStringArray(String input) {
        JSONArray theArray = new JSONArray();
        theArray.put(input);
        return theArray;
    }
    private JSONObject getPathsObject() throws Exception {
        JSONObject allPaths = new JSONObject();

        JSONObject aPath = new JSONObject();
        allPaths.put("/api/{site}/{proj}/summary.json", aPath);
        JSONObject gets = new JSONObject();
        gets.put("description", "Entire Project Summary");

        return allPaths;
    }
    private JSONObject getDefinitionsObject() throws Exception {
        return new JSONObject();
    }
    private JSONObject getParametersObject() throws Exception {
        return new JSONObject();
    }
    private JSONObject getResponsesObject() throws Exception {
        return new JSONObject();
    }
    private JSONArray getSecurityDefinitionsArray() throws Exception {
        return new JSONArray();
    }
    private JSONArray getTagsArray() throws Exception {
        return new JSONArray();
    }
    private JSONObject getExternalDocObject() throws Exception {
        return new JSONObject();
    }


    private JSONObject getSitePostResponse(AuthRequest ar, ResourceDecoder resDec,
            String op, JSONObject objIn) throws Exception {
        JSONObject responseOK = new JSONObject();
        responseOK.put("responseCode", 200);

        if ("ping".equals(op)) {
            objIn.put("responseCode", 200);
            return objIn;
        }

        if (resDec.site==null) {
            throw new Exception("Unable to fine a site with the id: "+resDec.siteId);
        }
        if (!resDec.site.isSiteFolderStructure()) {
            throw new Exception("This operation requires a site that is structured with site-folder structure");
        }
        if (!resDec.site.isValidLicense(resDec.lic, ar.nowTime)) {
            throw new Exception("The license ("+resDec.licenseId+") has expired.  "
                    +"To exchange information, you will need to get an updated license");
        }
        if (resDec.lic.isReadOnly()) {
            throw new Exception("The license ("+resDec.licenseId+") is a read-only license and "
                    +"can not be used to update information on this server.");
        }

        responseOK.put("license", getLicenseInfo(resDec.lic));
        if ("createProject".equals(op)) {
            if (!"$".equals(resDec.projId)) {
                throw new Exception("create project can only be called on a site URL, not project: "+resDec.projId);
            }
            NGBook site = resDec.site;
            String projectName = objIn.getString("projectName");
            String projectKey = SectionWiki.sanitize(projectName);
            projectKey = site.findUniqueKeyInSite(ar.getCogInstance(), projectKey);
            NGPage ngp = site.createProjectByKey(ar, projectKey);

            License lr = ngp.createLicense(ar.getBestUserId(), "Admin",
                    ar.nowTime + 1000*60*60*24*365, false);
            ngp.saveFile(ar, "project created through API by "+ar.getBestUserId());

            String newLink = ar.baseURL + "api/" + resDec.siteId + "/" + ngp.getKey()
                    + "/summary.json?lic=" + lr.getId();

            responseOK.put("key", ngp.getKey());
            responseOK.put("site", site.getKey());
            responseOK.put("name", ngp.getFullName());
            responseOK.put("link", newLink);
            return responseOK;
        }

        throw new Exception("API does not understand operation: "+op);
    }


    private JSONObject getProjectPostResponse(AuthRequest ar, ResourceDecoder resDec,
            String op, JSONObject objIn) throws Exception {
        JSONObject responseOK = new JSONObject();
        responseOK.put("responseCode", 200);
        String urlRoot = ar.baseURL + "api/" + resDec.siteId + "/" + resDec.projId + "/";

        if ("ping".equals(op)) {
            objIn.put("responseCode", 200);
            return objIn;
        }

        NGPage ngp = resDec.project;
        if (ngp == null) {
            throw new Exception("Unable to find a project with the id "+resDec.projId);
        }
        if (resDec.lic == null) {
            throw new Exception("Unable to find a license with the id "+resDec.licenseId);
        }
        if (!ngp.isValidLicense(resDec.lic, ar.nowTime)) {
            throw new Exception("The license ("+resDec.licenseId+") has expired.  "
                    +"To exchange information, you will need to get an updated license");
        }
        if (resDec.lic.isReadOnly()) {
            throw new Exception("The license ("+resDec.licenseId+") is a read-only license and "
                    +"can not be used to update information on this server.");
        }
        if (!resDec.site.isSiteFolderStructure()) {
            throw new Exception("This operation requires a site that is structured with site-folder structure");
        }

        responseOK.put("license", getLicenseInfo(resDec.lic));

        if ("tempFile".equals(op)) {
            String fileName = "~tmp~"+IdGenerator.generateKey()+"~tmp~";
            responseOK.put("tempFileName", fileName);
            responseOK.put("tempFileURL", urlRoot + "temp/" + fileName + "?lic=" + resDec.licenseId);
            return responseOK;
        }

        if ("newNote".equals(op)) {
            JSONObject newNoteObj = objIn.getJSONObject("note");
            if (!resDec.hasFullMemberAccess()) {
                throw new Exception("The license ("+resDec.licenseId
                        +") does not have full member access which is needed in order to create a new note.");
            }
            NoteRecord newNote = resDec.project.createNote();
            newNote.setUniversalId(newNoteObj.getString("universalid"));
            newNote.updateNoteFromJSON(newNoteObj, ar);
            HistoryRecord.createNoteHistoryRecord(resDec.project, newNote, HistoryRecord.EVENT_TYPE_CREATED, ar,
                    "From downstream project by synchronization license "+resDec.licenseId);
            resDec.project.saveFile(ar, "New note synchronized from downstream linked project.");
            return responseOK;
        }
        if ("updateNote".equals(op)) {
            JSONObject newNoteObj = objIn.getJSONObject("note");
            String noteUID = newNoteObj.getString("universalid");
            NoteRecord note = resDec.project.getNoteByUidOrNull(noteUID);
            if (note==null) {
                throw new Exception("Unable to find an existing note with UID ("+noteUID+")");
            }
            if (!resDec.canAccessNote(note)) {
                throw new Exception("The license ("+resDec.licenseId
                        +") does not have right to access note ("+noteUID+").");
            }
            note.updateNoteFromJSON(newNoteObj, ar);
            HistoryRecord.createNoteHistoryRecord(resDec.project, note, HistoryRecord.EVENT_TYPE_MODIFIED, ar,
                    "From downstream project by synchronization license "+resDec.licenseId);
            resDec.project.saveFile(ar, "Note synchronized from downstream linked project.");
            return responseOK;
        }
        if ("updateDoc".equals(op) || "newDoc".equals(op)) {
            JSONObject newDocObj = objIn.getJSONObject("doc");
            String tempFileName = objIn.getString("tempFileName");

            File folder = resDec.project.getContainingFolder();
            File tempFile = new File(folder, tempFileName);
            if (!tempFile.exists()) {
                throw new Exception("Attemped operation failed because the temporary file "
                        +"does not exist: "+tempFile);
            }

            AttachmentRecord att;
            int historyEventType = HistoryRecord.EVENT_TYPE_CREATED;
            String newUid = newDocObj.optString("universalid");
            if ("updateDoc".equals(op)) {
                historyEventType = HistoryRecord.EVENT_TYPE_MODIFIED;
                att = resDec.project.findAttachmentByUidOrNull(newUid);
                if (!resDec.canAccessAttachment(att)) {
                    tempFile.delete();
                    throw new Exception("The license ("+resDec.licenseId
                            +") does not have right to access document ("+newUid+").");
                }
            }
            else {
                if (!resDec.hasFullMemberAccess()) {
                    tempFile.delete();
                    throw new Exception("The license ("+resDec.licenseId
                            +") does not have right to create new documents.");
                }
                String newName = newDocObj.getString("name");
                att = ngp.findAttachmentByName(newName);
                if (att!=null && newUid!=null && !newUid.equals(att.getUniversalId())) {
                    throw new Exception("Attempt to update a document with the name "+newName
                            +" with information from another document wiht the same name, but different universal ID. "
                            +" Something is wrong with upstream/downstream exchange.");
                }
                if (att==null) {
                    att = resDec.project.createAttachment();
                    if (newUid==null || newUid.length()==0) {
                        newUid = ngp.getContainerUniversalId() + "@" + att.getId();

                    }
                    att.setUniversalId(newUid);
                }
                //TODO: review this need for uid to match
                //this silly statement is needed to make updateDocFromJSON work....
                newDocObj.put("universalid", att.getUniversalId());
            }
            att.updateDocFromJSON(newDocObj, ar);
            String userUpdate = newDocObj.optString("modifieduser");
            if (userUpdate==null) {
                userUpdate = resDec.lic.getCreator();
            }
            long timeUpdate = newDocObj.optLong("modifiedtime");
            if (timeUpdate == 0) {
                timeUpdate = ar.nowTime;
            }

            FileInputStream fis = new FileInputStream(tempFile);
            att.streamNewVersion(resDec.project, fis, userUpdate, timeUpdate);
            fis.close();
            tempFile.delete();

            //send all the info back for a reasonable response
            responseOK.put("doc",  att.getJSON4Doc(resDec.project, ar, urlRoot, resDec.lic));

            //TODO: determine how to tell if the source was using the web UI or actually from
            //a downstream synchronization.  Commenting out for now since it is inaccurate.
            HistoryRecord.createAttHistoryRecord(resDec.project, att, historyEventType, ar,
                      "");
//                    "From downstream project by synchronization license "+resDec.licenseId);
            resDec.project.saveFile(ar, "Document synchronized from downstream linked project.");
            return responseOK;
        }

        throw new Exception("API does not understand operation: "+op);
    }

    @Override
    public void doDelete(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        streamException(new Exception("not implemented yet"), ar);
    }

    @Override
    public void init(ServletConfig config) throws ServletException {
        //don't initialize here.  Instead, initialize in SpringServlet!
    }

    private void streamException(Exception e, AuthRequest ar) {
        try {
            //all exceptions are delayed by 3 seconds to avoid attempts to
            //mine for valid license numbers
            Thread.sleep(3000);

            System.out.println("API_ERROR: "+ar.getCompleteURL());

            ar.logException("API Servlet", e);

            JSONObject errorResponse = new JSONObject();
            errorResponse.put("responseCode", 500);
            JSONObject exception = new JSONObject();
            errorResponse.put("exception", exception);

            JSONArray msgs = new JSONArray();
            Throwable runner = e;
            while (runner!=null) {
                System.out.println("    ERROR: "+runner.toString());
                msgs.put(runner.toString());
                runner = runner.getCause();
            }
            exception.put("msgs", msgs);

            StringWriter sw = new StringWriter();
            e.printStackTrace(new PrintWriter(sw));
            exception.put("stack", sw.toString());

            ar.resp.setContentType("application/json");
            errorResponse.write(ar.resp.writer, 2, 0);
            ar.flush();
        } catch (Exception eeeee) {
            // nothing we can do here...
            ar.logException("API Servlet Error Within Error", eeeee);
        }
    }



    @SuppressWarnings("unused")
    private void genSiteListing(AuthRequest ar, ResourceDecoder resDec) throws Exception {

        NGBook site = resDec.site;
        String licenseId = resDec.licenseId;
        if (site==null) {
            //this is probably unnecessary, having hit an exception earlier, but just begin sure
            throw new Exception("Something is wrong, can not find a site object.");
        }
        if (false==true) {
            if (licenseId == null || licenseId.length()==0 || resDec.lic==null) {
                throw new Exception("All operations on the site need to be licensed, but did not get a license id in that URL.");
            }
            if (!site.isValidLicense(resDec.lic, ar.nowTime)) {
                throw new Exception("The license ("+resDec.licenseId+") has expired.  "
                        +"To exchange information, you will need to get an updated license");
            }
        }
        JSONObject root = new JSONObject();

        String urlRoot = ar.baseURL + "api/" + resDec.siteId + "/$/?lic="+licenseId;
        root.put("siteinfo", urlRoot);
//        root.put("hostinfo", ar.baseURL + "api/$/$/");
        root.put("name", resDec.site.getFullName());
        root.put("id", resDec.site.getKey());
        root.put("deleted", resDec.site.isDeleted());
        root.put("frozen", resDec.site.isFrozen());
        root.put("license", getLicenseInfo(resDec.lic));

        ar.resp.setContentType("application/json");
        root.write(ar.resp.getWriter(), 2, 0);
        ar.flush();
    }

    private void genProjectListing(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        JSONObject root = new JSONObject();

        NGPage ngp = resDec.project;
        if (ngp==null) {
            //this is probably unnecessary, having hit an exception earlier, but just begin sure
            throw new Exception("Something is wrong, can not find a site object.");
        }
        if (resDec.licenseId == null || resDec.licenseId.length()==0 || resDec.lic==null) {
            throw new Exception("All operations on the site need to be licensed, but did not get a license id in that URL.");
        }
        if (!ngp.isValidLicense(resDec.lic, ar.nowTime)) {
            throw new Exception("The license ("+resDec.licenseId+") has expired.  "
                    +"To exchange information, you will need to get an updated license");
        }
        root.put("license", getLicenseInfo(resDec.lic));
        NGBook site = ngp.getSite();

        String urlRoot = ar.baseURL + "api/" + resDec.siteId + "/" + resDec.projId + "/";
        root.put("projectname", ngp.getFullName());
        root.put("projectinfo", urlRoot+"?lic="+resDec.licenseId);
        root.put("sitename", site.getFullName());

        LicenseForUser lfu = LicenseForUser.getUserLicense(resDec.lic);
        String siteRoot = ar.baseURL + "api/" + resDec.siteId + "/$/?lic="+lfu.getId();
        root.put("siteinfo", siteRoot);

        String uiUrl = ar.baseURL + ar.getDefaultURL(ngp);
        root.put("projectui", uiUrl);
        String siteUI = ar.baseURL + ar.getDefaultURL(ngp.getSite());
        root.put("siteui", siteUI);

        JSONArray goals = new JSONArray();
        if (resDec.hasFullMemberAccess()) {
            for (GoalRecord goal : resDec.project.getAllGoals()) {
                goals.put(goal.getJSON4Goal(resDec.project, ar.baseURL, resDec.lic));
            }
        }
        root.put("goals", goals);

        JSONArray docs = new JSONArray();
        for (AttachmentRecord att : ngp.getAllAttachments()) {
            if (att.isDeleted()) {
                continue;
            }
            if (att.isUnknown()) {
                continue;
            }
            if (!"FILE".equals(att.getType())) {
                continue;
            }
            if (!resDec.canAccessAttachment(att)) {
                continue;
            }
            JSONObject thisDoc = att.getJSON4Doc(resDec.project, ar, urlRoot, resDec.lic);
            docs.put(thisDoc);
        }
        root.put("docs", docs);

        JSONArray notes = new JSONArray();
        for (NoteRecord note : resDec.project.getAllNotes()) {
            if (!resDec.canAccessNote(note)) {
                continue;
            }
            notes.put(note.getJSON4Note(urlRoot, false, resDec.lic, resDec.project));
        }
        root.put("notes", notes);

        ar.resp.setContentType("application/json");
        root.write(ar.resp.getWriter(), 2, 0);
        ar.flush();
    }

    private void streamDocument(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        AttachmentRecord att = resDec.project.findAttachmentByIDOrFail(resDec.docId);
        if (!resDec.canAccessAttachment(att)) {
            throw new Exception("Specified license ("+resDec.licenseId
                    +") is not able to access document ("+resDec.docId+")");
        }

        ar.resp.setContentType(MimeTypes.getMimeType(att.getNiceName()));
        AttachmentVersion aVer = att.getLatestVersion(resDec.project);
        File realPath = aVer.getLocalFile();
        UtilityMethods.streamFileContents(realPath, ar.resp.out);
    }

    private void genGoalInfo(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        GoalRecord goal = resDec.project.getGoalOrFail(resDec.goalId);
        JSONObject goalObj = goal.getJSON4Goal(resDec.project, ar.baseURL, resDec.lic);
        ar.resp.setContentType("application/json");
        goalObj.write(ar.resp.getWriter(), 2, 0);
        ar.flush();
    }

    private void streamNote(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        NoteRecord note = resDec.project.getNoteOrFail(resDec.noteId);
        if (!resDec.canAccessNote(note)) {
            throw new Exception("Specified license ("+resDec.licenseId
                    +") is not able to access note ("+resDec.noteId+")");
        }
        String contents = note.getWiki();
        if (contents.length()==0) {
            contents = "-no contents-";
        }
        if (resDec.isHtmlFormat) {
            ar.resp.setContentType("text/html;charset=UTF-8");
            WikiConverter.writeWikiAsHtml(ar, contents);
        }
        else {
            ar.resp.setContentType("text");
            ar.write(contents);
        }
        ar.flush();
    }

    private void receiveTemp(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        File folder = resDec.project.getContainingFolder();
        File tempFile = new File(folder, resDec.tempName);
        InputStream is = ar.req.getInputStream();
        FileOutputStream fos = new FileOutputStream(tempFile);
        UtilityMethods.streamToStream(is,fos);
        fos.flush();
        fos.close();
    }

    private JSONObject getLicenseInfo(License lic) throws Exception {
        JSONObject licenseInfo = new JSONObject();
        if (lic == null) {
            throw new Exception("Program Logic Error: null license passed to getLicenseInfo");
        }
        licenseInfo.put("id", lic.getId());
        licenseInfo.put("timeout", lic.getTimeout());
        licenseInfo.put("creator", lic.getCreator());
        licenseInfo.put("role", lic.getRole());
        return licenseInfo;
    }
}
