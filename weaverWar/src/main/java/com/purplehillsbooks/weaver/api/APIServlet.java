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

package com.purplehillsbooks.weaver.api;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;

import jakarta.servlet.ServletConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AttachmentVersion;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.IdGenerator;
import com.purplehillsbooks.weaver.License;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.SectionWiki;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.util.MimeTypes;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;
import com.purplehillsbooks.streams.StreamHelper;

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
 * This will list all the action items, notes, and attachments to this project.
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
 * A POST to this address will update the action item in JSON format
 */
@SuppressWarnings("serial")
public class APIServlet extends jakarta.servlet.http.HttpServlet {

    @Override
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
         //this is an API to be read by others, so you have to set the CORS to
        //allow scripts to read this data from a browser.
        String origin = req.getHeader("Origin");
        if (origin==null || origin.length()==0) {
            //this does not always work, but what else can we do?
            origin="*";
        }
        resp.setHeader("Access-Control-Allow-Origin",      origin);
        resp.setHeader("Access-Control-Allow-Credentials", "true");
        resp.setHeader("Access-Control-Allow-Methods",     "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers",     "Origin, X-Requested-With, Content-Type, Accept, Authorization");
        resp.setHeader("Access-Control-Max-Age",           "1");
        resp.setHeader("Vary",                             "*");

        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            NGPageIndex.assertNoLocksOnThread();
            System.out.println("API_GET: "+ar.getCompleteURL());
            if (!ar.getCogInstance().isInitialized()) {
                throw WeaverException.newBasic("Server is not ready to handle requests.");
            }

            doAuthenticatedGet(ar);
        }
        catch (Exception e) {
            Exception ctx = WeaverException.newWrap("Unable to handle GET to %s", e, ar.getCompleteURL());
            streamException(ctx, ar);
        }
        finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }

    private void doAuthenticatedGet(AuthRequest ar)  throws Exception {

        try {
            ResourceDecoder resDec = new ResourceDecoder(ar);

            if (resDec.isDoc) {
                streamDocument(ar, resDec);
            }
            else if (resDec.isSwagger){
                throw WeaverException.newBasic("don't understand that isSwagger resource URL: %s", ar.getCompleteURL());
                //genSwagger(ar, resDec);
            }
            else if (resDec.isSite){
                throw WeaverException.newBasic("don't understand that isSite resource URL: %s ", ar.getCompleteURL());
                //genSiteListing(ar, resDec);
            }
            else if (resDec.isListing){
                throw WeaverException.newBasic("don't understand that isListing resource URL: %s", ar.getCompleteURL());
                //getWorkspaceListing(ar, resDec);
            }
            else if (resDec.isGoal) {
                throw WeaverException.newBasic("don't understand that isGoal resource URL: %s", ar.getCompleteURL());
                //genGoalInfo(ar, resDec);
            }
            else if (resDec.isNote) {
                throw WeaverException.newBasic("don't understand that isNote resource URL: %s", ar.getCompleteURL());
                //streamNote(ar, resDec);
            }
            else {
                throw WeaverException.newBasic("don't understand that resource URL: %s", ar.getCompleteURL());
            }
            ar.flush();

        } 
        catch (Exception e) {
            Exception ctx = WeaverException.newWrap("Unable to handle GET to %s", e, ar.getCompleteURL());
            streamException(ctx, ar);
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
                //don't want to hold any locks during the upload.
                NGPageIndex.clearLocksHeldByThisThread();
                receiveTemp(ar, resDec);
                System.out.println("    PUT: file written: "+resDec.tempName);
                JSONObject result = new JSONObject();
                result.put("responseCode", 200);
                result.write(ar.resp.getWriter(), 2, 0);
            }
            else {
                throw WeaverException.newBasic("Can not do a PUT to that resource URL: %s", ar.getCompleteURL());
            }
            ar.flush();
        }
        catch (Exception e) {
            Exception ctx = WeaverException.newWrap("Unable to handle PUT to %s", e, ar.getCompleteURL());
            streamException(ctx, ar);
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
                throw WeaverException.newBasic("Request object needs to have a specified 'operation'."
                        +" None found.");
            }

            JSONObject responseObj = null;
            if (resDec.isSite) {
                responseObj = getSitePostResponse(ar, resDec, op, objIn);
            }
            else {
                responseObj = getWorkspacePostResponse(ar, resDec, op, objIn);
            }
            responseObj.write(ar.resp.getWriter(), 2, 0);
            ar.flush();
        }
        catch (Exception e) {
            Exception ctx = WeaverException.newWrap("Unable to handle POST to %s", e, ar.getCompleteURL());
            streamException(ctx, ar);
        }
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
            throw WeaverException.newBasic("Unable to fine a site with the id: %s",resDec.siteId);
        }
        if (!resDec.site.isValidLicense(resDec.lic, ar.nowTime)) {
            throw WeaverException.newBasic("The license (%s) has expired.  "
                    +"To exchange information, you will need to get an updated license", resDec.licenseId);
        }
        if (resDec.lic.isReadOnly()) {
            throw WeaverException.newBasic("The license (%s) is a read-only license and "
                    +"can not be used to update information on this server.", resDec.licenseId);
        }

        responseOK.put("license", getLicenseInfo(resDec.lic));
        if ("createProject".equals(op)) {
            if (!"$".equals(resDec.projId)) {
                throw WeaverException.newBasic("create workspace can only be called on a site URL, not workspace: %s ",resDec.projId);
            }
            NGBook site = resDec.site;
            String projectName = objIn.getString("projectName");
            String projectKey = SectionWiki.sanitize(projectName);
            projectKey = site.genUniqueWSKeyInSite(projectKey);
            NGWorkspace ngw = site.createWorkspaceByKey(ar, projectKey);

            License lr = ngw.createLicense(ar.getBestUserId(), "Admin",
                    ar.nowTime + 1000*60*60*24*365, false);
            ngw.saveFile(ar, "workspace created through API by "+ar.getBestUserId());

            String newLink = ar.baseURL + "api/" + resDec.siteId + "/" + ngw.getKey()
                    + "/summary.json?lic=" + lr.getId();

            responseOK.put("key", ngw.getKey());
            responseOK.put("site", site.getKey());
            responseOK.put("name", ngw.getFullName());
            responseOK.put("link", newLink);
            return responseOK;
        }

        throw WeaverException.newBasic("API does not understand operation: %s",op);
    }


    private JSONObject getWorkspacePostResponse(AuthRequest ar, ResourceDecoder resDec,
            String op, JSONObject objIn) throws Exception {
        JSONObject responseOK = new JSONObject();
        responseOK.put("responseCode", 200);
        String urlRoot = ar.baseURL + "api/" + resDec.siteId + "/" + resDec.projId + "/";

        if ("ping".equals(op)) {
            objIn.put("responseCode", 200);
            return objIn;
        }

        NGWorkspace ngw = resDec.workspace;
        if (ngw == null) {
            throw WeaverException.newBasic("Unable to find a workspace with the id %s",resDec.projId);
        }
        if (resDec.lic == null) {
            throw WeaverException.newBasic("Unable to find a license with the id %s",resDec.licenseId);
        }
        if (!ngw.isValidLicense(resDec.lic, ar.nowTime)) {
            throw WeaverException.newBasic("The license (%s) has expired.  "
                    +"To exchange information, you will need to get an updated license", resDec.licenseId);
        }
        if (resDec.lic.isReadOnly()) {
            throw WeaverException.newBasic("The license (%s) is a read-only license and "
                    +"can not be used to update information on this server.", resDec.licenseId);
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
            if (!ar.canUpdateWorkspace()) {
                throw WeaverException.newBasic("The license (%s) does not have full member access which is needed in order to create a new topic.", 
                        resDec.licenseId);
            }
            TopicRecord newNote = resDec.workspace.createTopic();
            newNote.setUniversalId(newNoteObj.getString("universalid"));
            newNote.updateNoteFromJSON(newNoteObj, ar);
            HistoryRecord.createNoteHistoryRecord(resDec.workspace, newNote, HistoryRecord.EVENT_TYPE_CREATED, ar,
                    "From downstream workspace by synchronization license "+resDec.licenseId);
            resDec.workspace.saveFile(ar, "New topic synchronized from downstream linked workspace.");
            return responseOK;
        }
        if ("updateNote".equals(op)) {
            JSONObject newNoteObj = objIn.getJSONObject("note");
            String noteUID = newNoteObj.getString("universalid");
            TopicRecord note = resDec.workspace.getDiscussionTopic(noteUID);
            if (note==null) {
                throw WeaverException.newBasic("Unable to find an existing topic with UID (%s)", noteUID);
            }
            if (!resDec.canAccessNote(note)) {
                throw WeaverException.newBasic("The license (%s) does not have right to access topic (%s).", resDec.licenseId, noteUID);
            }
            note.updateNoteFromJSON(newNoteObj, ar);
            HistoryRecord.createNoteHistoryRecord(resDec.workspace, note, HistoryRecord.EVENT_TYPE_MODIFIED, ar,
                    "From downstream workspace by synchronization license "+resDec.licenseId);
            resDec.workspace.saveFile(ar, "Topic synchronized from downstream linked workspace.");
            return responseOK;
        }
        if ("updateDoc".equals(op) || "newDoc".equals(op) || "uploadDoc".equals(op)) {
            JSONObject newDocObj = objIn.getJSONObject("doc");
            String tempFileName = objIn.getString("tempFileName");
            long size = newDocObj.optLong("size", -1);

            File folder = resDec.workspace.getContainingFolder();
            File tempFile = new File(folder, tempFileName);
            
            //we had a problem where requests were getting here but the temp file did not exist
            //but inspection showed the file to exist.  There might be a delay in uploading the 
            //file due to caching delays.   This just waits for up to 4 seconds to see if the
            //file appears in the file system after a delay.
            int count = 0;
            while (!tempFile.exists()) {
                if (count++ > 20) {
                    throw WeaverException.newBasic("Operation '%s' failed because the temporary file does not exist: %s", op, tempFile);
                }
                System.out.println("WAITING "+count+" FOR TEMPFILE: "+tempFile.toString());
                Thread.sleep(300);
                
            }
            while (tempFile.length()<size) {
                if (count++ > 20) {
                    throw WeaverException.newBasic("Operation '%s' failed because file size is %s, should be %s", 
                            op, Long.toString(tempFile.length()), Long.toString(size));
                }
                System.out.println("WAITING "+count+" FOR ("+tempFile.toString()
                    +") to get from "+tempFile.length()+" to "+size+" bytes.");
                Thread.sleep(300);
            }

            AttachmentRecord att;
            int historyEventType = HistoryRecord.EVENT_TYPE_CREATED;
            String newUid = newDocObj.optString("universalid");
            String updateReason = "";
            if ("updateDoc".equals(op)) {
                historyEventType = HistoryRecord.EVENT_TYPE_MODIFIED;
                att = resDec.workspace.findAttachmentByUidOrNull(newUid);
                if (!resDec.canAccessAttachment(att)) {
                    tempFile.delete();
                    throw WeaverException.newBasic("The license (%s) does not have right to access document (%s).", resDec.licenseId, newUid);
                }
            }
            else {
                if (!ar.canUpdateWorkspace()) {
                    tempFile.delete();
                    throw WeaverException.newBasic("The license (%s) does not have right to create new documents.", resDec.licenseId);
                }
                String newName = newDocObj.getString("name");
                att = ngw.findAttachmentByName(newName);
                if (att==null) {
                    att = resDec.workspace.createAttachment();
                    if (newUid==null || newUid.length()==0) {
                        newUid = ngw.getContainerUniversalId() + "@" + att.getId();

                    }
                    att.setUniversalId(newUid);
                }
                else {
                    //ignore any label settings when working with existing doc.
                    //labels should only apply on newly created docs.
                    newDocObj.remove("labelMap");
                }
                //TODO: review this need for uid to match
                //this silly statement is needed to make updateDocFromJSON work....
                newDocObj.put("universalid", att.getUniversalId());
                att.setModifiedBy(ar.getBestUserId());
                att.setModifiedDate(ar.nowTime);
            }
            att.updateDocFromJSON(newDocObj, ar);

            String userUpdate = null;
            if (ar.isLoggedIn()) {
                userUpdate = ar.getBestUserId();
            }
            else {
                //this needed for license style
                userUpdate = newDocObj.optString("modifieduser");
                if (userUpdate==null) {
                    //TODO: for some reason this is not working, and user is not getting set
                    userUpdate = resDec.lic.getCreator();
                }
            }

            long timeUpdate = newDocObj.optLong("modifiedtime");
            if (timeUpdate <= 0) {
                timeUpdate = ar.nowTime;
            }

            FileInputStream fis = new FileInputStream(tempFile);
            att.streamNewVersion(resDec.workspace, fis, userUpdate, timeUpdate);
            fis.close();
            tempFile.delete();

            //send all the info back for a reasonable response
            responseOK.put("doc",  att.getJSON4Doc(resDec.workspace, ar, urlRoot, resDec.lic));

            //TODO: determine how to tell if the source was using the web UI or actually from
            //a downstream synchronization.  Commenting out for now since it is inaccurate.
            HistoryRecord.createHistoryRecord(resDec.workspace, att.getId(),  HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                    0, historyEventType, ar, updateReason);
            System.out.println("DOCUMENT: updated: "+att.getNiceName()+" ("+size+" bytes) and history created.");
            resDec.workspace.saveFile(ar, "Document created or updated.");
            return responseOK;
        }

        throw WeaverException.newBasic("API does not understand operation: %s",op);
    }

    @Override
    public void doDelete(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        streamException(WeaverException.newBasic("not implemented yet"), ar);
    }

    @Override
    public void init(ServletConfig config) throws ServletException {
        //don't initialize here.  Instead, initialize in SpringServlet!
    }

    public static void streamException(Exception e, AuthRequest ar) {
        try {
            //all exceptions are delayed by 3 seconds to avoid attempts to
            //mine for valid license numbers
            Thread.sleep(3000);

            System.out.println("API_ERROR: "+ar.getCompleteURL());

            ar.logException("API Servlet", e);

            JSONObject errorResponse = JSONException.convertToJSON(e, "API Exception");
            ar.resp.setContentType("application/json");
            errorResponse.write(ar.resp.writer, 2, 0);
            ar.flush();
        } 
        catch (Exception eeeee) {
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
            throw WeaverException.newBasic("Something is wrong, can not find a site object.");
        }
        if (false==true) {
            if (licenseId == null || licenseId.length()==0 || resDec.lic==null) {
                throw WeaverException.newBasic("All operations on the site need to be licensed, but did not get a license id in that URL.");
            }
            if (!site.isValidLicense(resDec.lic, ar.nowTime)) {
                throw WeaverException.newBasic("The license (%s) has expired.   To exchange information, you will need to get an updated license", resDec.licenseId);
            }
        }
        JSONObject root = new JSONObject();

        String urlRoot = ar.baseURL + "api/" + resDec.siteId + "/$/?lic="+licenseId;
        root.put("siteinfo", urlRoot);
        root.put("name", resDec.site.getFullName());
        root.put("id", resDec.site.getKey());
        root.put("deleted", resDec.site.isDeleted());
        root.put("frozen", resDec.site.isFrozen());
        root.put("license", getLicenseInfo(resDec.lic));

        ar.resp.setContentType("application/json");
        root.write(ar.resp.getWriter(), 2, 0);
        ar.flush();
    }



    private void streamDocument(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        AttachmentRecord att = resDec.workspace.findAttachmentByIDOrFail(resDec.docId);
        if (!resDec.canAccessAttachment(att)) {
            throw WeaverException.newBasic("Specified license (%s) is not able to access document (%s)", resDec.licenseId, resDec.docId);
        }

        ar.resp.setContentType(MimeTypes.getMimeType(att.getNiceName()));
        AttachmentVersion aVer = att.getLatestVersion(resDec.workspace);
        File realPath = aVer.getLocalFile();
        StreamHelper.copyFileToOutput(realPath, ar.resp.out);
    }



    private void receiveTemp(AuthRequest ar, ResourceDecoder resDec) throws Exception {
        File folder = resDec.workspace.getContainingFolder();
        File tempFile = new File(folder, resDec.tempName);
        InputStream is = ar.req.getInputStream();
        FileOutputStream fos = new FileOutputStream(tempFile);
        StreamHelper.copyInputToOutput(is, fos);
        fos.flush();
        fos.close();
        
        //now wait to make sure it is actually there in the file system
        if (!tempFile.exists()) {
            //we had a problem where requests were getting here but the temp file did not exist
            //but inspection showed the file to exist.  There might be a delay in uploading the 
            //file due to caching delays.   This just waits for up to 4 seconds to see if the
            //file appears in the file system after a delay.
            int count = 0;
            while (!tempFile.exists() && count++ < 20) {
                System.out.println("WAITING "+count+" FOR PUT FILE: "+tempFile.toString());
                Thread.sleep(200);
            }
            throw WeaverException.newBasic("PUT temp file failed.  Can't see it in file system: %s", tempFile);
        }
    }

    private JSONObject getLicenseInfo(License lic) throws Exception {
        JSONObject licenseInfo = new JSONObject();
        if (lic == null) {
            throw WeaverException.newBasic("Program Logic Error: null license passed to getLicenseInfo");
        }
        licenseInfo.put("id", lic.getId());
        licenseInfo.put("timeout", lic.getTimeout());
        licenseInfo.put("creator", lic.getCreator());
        licenseInfo.put("role", lic.getRole());
        return licenseInfo;
    }
}
