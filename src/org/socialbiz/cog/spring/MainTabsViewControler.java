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

package org.socialbiz.cog.spring;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AgendaItem;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.LeafletResponseRecord;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.MicroProfileMgr;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NoteRecord;
import org.socialbiz.cog.ProfileRequest;
import org.socialbiz.cog.SearchManager;
import org.socialbiz.cog.SearchResultRecord;
import org.socialbiz.cog.SectionUtil;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

@Controller
public class MainTabsViewControler extends BaseController {

    private ApplicationContext context;
    @Autowired
    public void setContext(ApplicationContext context) {
        this.context = context;
    }


    @RequestMapping(value = "/{siteId}/{pageId}/projectHome.htm", method = RequestMethod.GET)
    public ModelAndView projectHome(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar, "frontPage.htm");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/notesList.htm", method = RequestMethod.GET)
    public ModelAndView notesList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);

            return new ModelAndView("NotesList");
        }catch(Exception ex){
            System.out.println("An exception occurred in public_htm"+ex.toString());
            throw new NGException("nugen.operation.fail.project.public.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/public.htm", method = RequestMethod.GET)
    public ModelAndView publicssssss(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar, "frontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/member.htm", method = RequestMethod.GET)
    public ModelAndView member(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar, "frontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/deletedNotes.htm", method = RequestMethod.GET)
    public ModelAndView deletedNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar, "frontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/draftNotes.htm", method = RequestMethod.GET)
    public ModelAndView draftNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar, "frontPage.htm");
    }



    @RequestMapping(value = "/{siteId}/{pageId}/automaticLinks.htm", method = RequestMethod.GET)
    public ModelAndView automaticLinks(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
           throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }

            modelAndView=new ModelAndView("AutomaticLinks");
            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.draft.notes.page", new Object[]{pageId,siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/searchAllNotes.htm", method = RequestMethod.GET)
    public ModelAndView searchAllNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
           throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if ("$".equals(pageId)) {
                prepareSiteView(ar, siteId);
            }
            else {
                registerRequiredProject(ar, siteId, pageId);
            }
            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }
            return new ModelAndView("SearchAllNotes");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.draft.notes.page", new Object[]{pageId,siteId} , ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/process.htm", method = RequestMethod.GET)
    public ModelAndView showProcessTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar, "projectActiveTasks.htm");
    }



    @RequestMapping(value = "/{siteId}/{pageId}/history.htm", method = RequestMethod.GET)
    public ModelAndView showHistoryTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            registerRequiredProject(ar, siteId, pageId);
            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }

            request.setAttribute("messages", context);
            return new ModelAndView("history");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.history.page", new Object[]{pageId,siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/frontPage.htm", method = RequestMethod.GET)
    public ModelAndView frontPage(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            registerRequiredProject(ar, siteId, pageId);
            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }

            request.setAttribute("messages", context);
            return new ModelAndView("FrontPage");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.history.page", new Object[]{pageId,siteId} , ex);
        }
    }


     @RequestMapping(value = "/index.htm", method = RequestMethod.GET)
     public ModelAndView showLandingPage(HttpServletRequest request, HttpServletResponse response)
                throws Exception {
         ModelAndView modelAndView = null;
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             ar.getCogInstance().assertInitialized();
             //if the user is logged in, redirect to their own home page instead
             if (ar.isLoggedIn())
             {
                 response.sendRedirect(ar.retPath+"v/"+ar.getUserProfile().getKey()+"/watchedProjects.htm");
                 return null;
             }

             modelAndView=new ModelAndView("landingPage");
             request.setAttribute("realRequestURL", ar.getRequestURL());
             List<NGBook> list=new ArrayList<NGBook>();
             for (NGBook ngb : NGBook.getAllSites()) {
                 list.add(ngb);
             }

             request.setAttribute("headerType", "user");
             //TODO: see if bookList is really needed
             modelAndView.addObject("bookList",list);
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.project.welcome.page", null , ex);
         }
         return modelAndView;
     }



     @RequestMapping(value = "/{siteId}/{pageId}/editNote.htm", method = RequestMethod.GET)
     public ModelAndView editNote(@PathVariable String pageId,
            @PathVariable String siteId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             if(!ar.isLoggedIn()){
                 return showWarningView(ar, "message.loginalert.see.page");
             }
             registerRequiredProject(ar, siteId, pageId);
             ModelAndView modelAndView = memberCheckViews(ar);
             if (modelAndView!=null) {
                 return modelAndView;
             }

             NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
             ar.setPageAccessLevels(ngp);
             ar.assertMember("Need Member Access to Edit a Topic.");
             modelAndView = new ModelAndView("EditNote");
             modelAndView.addObject("pageTitle",ngp.getFullName());
             request.setAttribute("title","Edit Topic: "+ ngp.getFullName());
             return modelAndView;
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.project.create.note.page", null , ex);
         }
     }

     @RequestMapping(value = "/{siteId}/{pageId}/noteHtmlUpdate.json", method = RequestMethod.POST)
     public void noteHtmlUpdate(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngp);
             ar.assertMember("Must be a member to update a topic contents.");
             nid = ar.reqParam("nid");
             JSONObject noteInfo = getPostedObject(ar);

             NoteRecord note = null;
             int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
             if ("~new~".equals(nid)) {
                 note = ngp.createNote();
                 noteInfo.put("universalid", note.getUniversalId());
                 eventType = HistoryRecord.EVENT_TYPE_CREATED;
             }
             else {
                 note = ngp.getNote(nid);
             }

             note.updateNoteFromJSON(noteInfo, ar);
             note.updateHtmlFromJSON(ar, noteInfo);
             note.setLastEdited(ar.nowTime);
             note.setModUser(new AddressListEntry(ar.getBestUserId()));
             HistoryRecord.createHistoryRecord(ngp, note.getId(), HistoryRecord.CONTEXT_TYPE_LEAFLET,
                     0, eventType, ar, "");

             ngp.saveFile(ar, "Updated Topic Contents");

             JSONObject repo = note.getJSONWithHtml(ar);
             repo.write(ar.w, 2, 2);
             ar.flush();
         }catch(Exception ex){
             Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/{siteId}/{pageId}/updateNote.json", method = RequestMethod.POST)
     public void updateNote(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngp);
             ar.assertMember("Must be a member to update a topic contents.");
             nid = ar.reqParam("nid");
             JSONObject noteInfo = getPostedObject(ar);
             NoteRecord note = ngp.getNote(nid);

             boolean isCreateComment = noteInfo.has("newComment");
             if (isCreateComment) {
                 JSONObject newComment = noteInfo.getJSONObject("newComment");
                 String comment = newComment.getString("html");
                 comment = GetFirstHundredNoHtml(comment);
                 HistoryRecord.createHistoryRecord(ngp, note.getId(),
                         HistoryRecord.CONTEXT_TYPE_LEAFLET,
                         HistoryRecord.EVENT_COMMENT_ADDED, ar, comment);
             }


             note.updateNoteFromJSON(noteInfo, ar);

             ngp.saveFile(ar, "Updated Topic Contents");

             JSONObject repo = note.getJSONWithHtml(ar);
             repo.write(ar.w, 2, 2);
             ar.flush();
         }catch(Exception ex){
             Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }

     /*
      * Pull the first 100 character max from the string, but ignore anything
      * that looks like an HTML tag, and anything inside those tags.
      * Does not handle script tags or other expressions in attributes ... but there should not be any.
      */
     private String GetFirstHundredNoHtml(String input) {
         int limit = 100;
         boolean inTag = false;
         StringBuffer res = new StringBuffer();
         for (int i=0; i<input.length() && limit>0; i++) {
             char ch = input.charAt(i);
             if (inTag) {
                 if ('>' == ch) {
                     inTag=false;
                 }
                 //ignore all other characters while in the tag
             }
             else {
                 if ('<' == ch) {
                     inTag=true;
                 }
                 else {
                     res.append(ch);
                     limit--;
                 }
             }
         }
         return res.toString();
     }

    //allow a user to change their email subscriptions, including opt out
    //even when not logged in.
    @RequestMapping(value = "/EmailAdjustment.htm", method = RequestMethod.GET)
    public ModelAndView emailAdjustment(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.preserveRealRequestURL();
            return new ModelAndView("EmailAdjustment");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
        }
    }

    //allow a user to change their email subscriptions, including opt out
    //even when not logged in.
    @RequestMapping(value = "/EmailAdjustmentAction.form", method = RequestMethod.POST)
    public void emailAdjustmentActionForm(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.preserveRealRequestURL();

            String p = ar.reqParam("p");
            String email = ar.reqParam("email");
            String mn = ar.reqParam("mn");
            String go = ar.defParam("go", ar.baseURL);

            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
            String expectedMn = ngp.emailDependentMagicNumber(email);
            if (!expectedMn.equals(mn)) {
                throw new Exception("Something is wrong, improper request for email address "+email);
            }

            String cmd = ar.reqParam("cmd");
            if ("Remove Me".equals(cmd)) {
                String role = ar.reqParam("role");
                NGRole specRole = ngp.getRoleOrFail(role);
                specRole.removePlayer(new AddressListEntry(email));
            }
            else {
                throw new Exception("emailAdjustmentActionForm does not understand the cmd "+cmd);
            }

            response.sendRedirect(go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
        }
    }


     @RequestMapping(value = "/{siteId}/{pageId}/noteZoom{lid}.htm", method = RequestMethod.GET)
     public ModelAndView displayOneLeaflet(@PathVariable String lid, @PathVariable String pageId,
            @PathVariable String siteId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            NoteRecord note = ngp.getNoteOrFail(lid);

            boolean canAccessNote  = AccessControl.canAccessNote(ar, ngp, note);
            if (!canAccessNote) {
                ModelAndView modelAndView= memberCheckViews(ar);
                if (modelAndView!=null) {
                    return modelAndView;
                }
            }

            request.setAttribute("lid", lid);
            return new ModelAndView("NoteZoom");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.zoom.note.page", new Object[]{lid,pageId,siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/leafletResponse.htm", method = RequestMethod.POST)
    public ModelAndView handleLeafletResponse(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = null;
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);

            String go = ar.reqParam("go");
            String action = ar.reqParam("action");

            String lid = ar.reqParam("lid");
            String data = ar.defParam("data", null);
            String choice = ar.defParam("choice", null);

            NoteRecord note = ngp.getNoteOrFail(lid);
            LeafletResponseRecord llr;

            String uid = ar.reqParam("uid");
            UserProfile designatedUser = UserManager.findUserByAnyId(uid);
            if (designatedUser == null) {
                // As Micro-profile concept has been introduced, so
                // Micro-profile will be created
                // instead of creating a new user profile.
                MicroProfileMgr.setDisplayName(uid, uid);
                MicroProfileMgr.save();
                //finds or creates a response for a user ID that has no profile.
                llr = note.accessResponse(uid);
            }
            else {
                //finds the response for a user with a profile
                llr = note.getOrCreateUserResponse(designatedUser);
            }

            if (action.startsWith("Update")) {
                //Note: we do not need to have "topic edit" permission here
                //because we are only changing a response record.  We only need
                //topic 'access' permissions which might come from magic number
                if (AccessControl.canAccessNote(ar, ngp, note)) {
                    llr.setData(data);
                    llr.setChoice(choice);
                    llr.setLastEdited(ar.nowTime);
                    ngp.saveFile(ar, "Updated response to topic");
                }
            }
            modelAndView = new ModelAndView(new RedirectView(go));
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.note.response", new Object[] {
                    pageId, siteId }, ex);
        }
        return modelAndView;
    }





    /**
     * This is search page that you get when NOT LOGGED IN from the
     * landing page.  However, you can also see this when logged in.
     */
    @RequestMapping(value = "/searchPublicNotes.htm")
    public ModelAndView searchPublicNotes(
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            String searchText   = ar.defParam("searchText", "");
            String b = ar.defParam("b", null);
            if ("All Books".equals(b)) {
                b = null;
            }
            String pf = ar.defParam("pf", "all");

            SearchManager.initializeIndex(ar.getCogInstance());
            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = SearchManager.performSearch(ar, searchText, pf, b);
            }
            else {
                searchResults = new Vector<SearchResultRecord>();
            }
            request.setAttribute("searchResults",searchResults);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.search.public.note.page", null , ex);
        }
        return  new ModelAndView("showSearchResult");
    }


    /**
     * This is LOGGED IN search page.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/searchNotes.json", method = RequestMethod.POST)
    public void searchPublicNotesJSON(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to search the topics");

            JSONObject query = getPostedObject(ar);

            String searchText    = query.getString("searchFilter");
            String searchSite    = query.getString("searchSite");
            String searchProject = query.getString("searchProject");

            if ("all".equals(searchSite)) {
                siteId = null;
            }

            SearchManager.initializeIndex(ar.getCogInstance());
            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = SearchManager.performSearch(ar, searchText, searchProject, siteId);
            }
            else {
                searchResults = new Vector<SearchResultRecord>();
            }

            JSONArray resultList = new JSONArray();
            for (SearchResultRecord srr : searchResults) {
                resultList.put(srr.getJSON());
            }
            resultList.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to search for topics.", ex);
            streamException(ee, ar);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/subprocess.htm", method = RequestMethod.GET)
    public ModelAndView showSubProcessTab(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response,@RequestParam String subprocess)
              throws Exception {

        ModelAndView modelAndView = null;
        try{
            request.setAttribute("book", siteId);
            request.setAttribute("pageId", pageId);
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.getCogInstance().getSiteByIdOrFail(siteId);
            modelAndView=new ModelAndView("ProjectActiveTasks");

            request.setAttribute("subprocess", subprocess);
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Tasks");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.subprocess.page", new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;
    }

      /**
       * This is a view that prompts the user to specify how they want the PDF to be produced.
       */
    @RequestMapping(value = "/{siteId}/{pageId}/exportPDF.htm", method = RequestMethod.GET)
    public ModelAndView exportPDF(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String pageId,
            @PathVariable String siteId)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "nugen.project.export.pdf.login.msg");
            }
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Notes");
            return new ModelAndView("exportPDF");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.export.pdf.page", new Object[]{pageId,siteId} , ex);
        }
    }

      @RequestMapping(value = "/isNoteDeleted.ajax", method = RequestMethod.POST)
      public void isNoteDeleted(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         String responseText = null;
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try {
             ar.assertLoggedIn("Must be logged in to create a topic.");
             String p = ar.reqParam("p");
             NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( p );
             ar.setPageAccessLevels(ngp);

             String oid = ar.reqParam("oid");
             JSONObject paramMap = new JSONObject();
             NoteRecord note = ngp.getNoteOrFail(oid);
             if(note.isDeleted()){
                 paramMap.put(Constant.MSG_TYPE, Constant.YES);
             }else{
                 paramMap.put(Constant.MSG_TYPE, Constant.No);
             }

             responseText = paramMap.toString();
         }
         catch (Exception ex) {
             responseText = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
             ar.logException("Caught by isNoteDeleted.ajax", ex);
         }
         NGWebUtils.sendResponse(ar, responseText);
     }

      @RequestMapping(value = "/closeWindow.htm", method = RequestMethod.GET)
      public ModelAndView closeWindow(HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          ModelAndView modelAndView = null;
          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              if(!ar.isLoggedIn()){
                  return showWarningView(ar, "message.loginalert.see.page");
              }
              modelAndView=new ModelAndView("closeWindow");
              request.setAttribute("realRequestURL", ar.getRequestURL());
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.close.window", null , ex);
          }
          return modelAndView;
      }


      @RequestMapping(value = "/{siteId}/{pageId}/meetingList.htm", method = RequestMethod.GET)
      public ModelAndView meetingList(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              registerRequiredProject(ar, siteId, pageId);
              ModelAndView modelAndView= memberCheckViews(ar);
              if (modelAndView!=null) {
                  return modelAndView;
              }

              return new ModelAndView("MeetingList");
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
          }

      }

      @RequestMapping(value = "/{siteId}/{pageId}/meetingCreate.json", method = RequestMethod.POST)
      public void meetingCreate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a meeting.");
              JSONObject meetingInfo = getPostedObject(ar);
              String name = meetingInfo.getString("name");
              if (name==null || name.length()==0) {
                  throw new Exception("You must supply a meeting name to create a meeting.");
              }
              MeetingRecord newMeeting = ngp.createMeeting();
              newMeeting.setOwner(ar.getBestUserId());
              removeCompletedActionItems(ngp, meetingInfo);
              newMeeting.updateFromJSON(meetingInfo, ar);
              newMeeting.createAgendaFromJSON(meetingInfo, ar, ngp);
              newMeeting.setState(1);
              HistoryRecord.createHistoryRecord(ngp, newMeeting.getId(),
                      HistoryRecord.CONTEXT_TYPE_MEETING,
                      HistoryRecord.EVENT_TYPE_CREATED, ar, "");

              ngp.saveFile(ar, "Created new Meeting");
              JSONObject repo = newMeeting.getFullJSON(ar, ngp);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create meeting.", ex);
              streamException(ee, ar);
          }
      }

      /*
       * The point is that uncompleted action items should get dragged to the next copy
       * of the meeting.  Completed or skipped action items should NOT be dragged along.
       * They are no longer useful.
       */
      private void removeCompletedActionItems(NGPage ngp, JSONObject meetingInfo) throws Exception {
          if (!meetingInfo.has("agenda")) {
              return;
          }
          JSONArray agenda = meetingInfo.getJSONArray("agenda");
          for (int i=0; i<agenda.length(); i++) {
              JSONObject agendaItem = agenda.getJSONObject(i);
              if (!agendaItem.has("actionItems")) {
                  continue;
              }
              JSONArray actionItems = agendaItem.getJSONArray("actionItems");
              JSONArray approvedItems = new JSONArray();
              for (int j=0; j<actionItems.length(); j++) {
                  String universalId = actionItems.getString(j);
                  GoalRecord gr = ngp.getGoalOrNull(universalId);
                  if (gr==null) {
                      continue;
                  }
                  if (gr.getState()==BaseRecord.STATE_COMPLETE) {
                      continue;
                  }
                  if (gr.getState()==BaseRecord.STATE_SKIPPED) {
                      continue;
                  }
                  approvedItems.put(universalId);
              }
              agendaItem.put("actionItems", approvedItems);
          }

      }

      @RequestMapping(value = "/{siteId}/{pageId}/meetingUpdate.json", method = RequestMethod.POST)
      public void meetingUpdate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a meeting.");
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);
              JSONObject meetingInfo = getPostedObject(ar);

              meeting.updateFromJSON(meetingInfo, ar);
              meeting.updateAgendaFromJSON(meetingInfo, ar, ngp);

              if (meetingInfo.has("agenda")) {
                  JSONArray agenda = meetingInfo.getJSONArray("agenda");
                  for (int i=0; i<agenda.length(); i++) {
                      JSONObject aItem = agenda.getJSONObject(i);
                      if (aItem.has("newComment")) {
                          JSONObject newComment = aItem.getJSONObject("newComment");
                          if (newComment.has("html")) {
                              String comment = newComment.getString("html");
                              comment = GetFirstHundredNoHtml(comment);
                              HistoryRecord.createHistoryRecord(ngp, meeting.getId(),
                                      HistoryRecord.CONTEXT_TYPE_MEETING,
                                      HistoryRecord.EVENT_COMMENT_ADDED, ar, comment);
                          }
                      }
                  }
              }


              ngp.saveFile(ar, "Updated Meeting");
              JSONObject repo = meeting.getFullJSON(ar, ngp);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create meeting.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/meetingDelete.json", method = RequestMethod.POST)
      public void meetingDelete(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          String meetingId = "";
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to delete a meeting.");
              JSONObject meetingInfo = getPostedObject(ar);
              meetingId = meetingInfo.getString("id");
              ngp.removeMeeting(meetingId);
              ngp.saveFile(ar, "Deleted new Meeting");
              ar.write("deleted Meeting "+meetingId);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to delete meeting "+meetingId, ex);
              streamException(ee, ar);
          }
      }



      @RequestMapping(value = "/{siteId}/{pageId}/meeting.htm", method = RequestMethod.GET)
      public ModelAndView meeting(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              registerRequiredProject(ar, siteId, pageId);
              ModelAndView modelAndView= memberCheckViews(ar);
              if (modelAndView!=null) {
                  return modelAndView;
              }

              return new ModelAndView("Meeting");
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
          }
      }

      @RequestMapping(value = "/{siteId}/{pageId}/agendaAdd.json", method = RequestMethod.POST)
      public void agendaAdd(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a meeting.");
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);
              JSONObject agendaInfo = getPostedObject(ar);

              String subject = agendaInfo.getString("subject");
              if (subject==null || subject.length()==0) {
                  throw new Exception("You must supply a agenda subject to create an agenda item.");
              }
              AgendaItem ai = meeting.createAgendaItem(ngp);
              ai.setPosition(99999);
              ai.setSubject(subject);
              ai.updateFromJSON(ar, agendaInfo);

              meeting.renumberItems();
              ngp.saveFile(ar, "Created new Agenda Item");
              JSONObject repo = ai.getJSON(ar);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create agenda item.", ex);
              streamException(ee, ar);
          }
      }

      @RequestMapping(value = "/{siteId}/{pageId}/agendaDelete.json", method = RequestMethod.POST)
      public void agendaDelete(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to delete a meeting.");
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);
              JSONObject agendaInfo = getPostedObject(ar);

              String agendaId = agendaInfo.getString("id");
              meeting.removeAgendaItem(agendaId);
              meeting.renumberItems();
              ngp.saveFile(ar, "Deleted Agenda Item");
              ar.write("deleted agenda item "+agendaId);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to delete agenda item.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/agendaMove.json", method = RequestMethod.POST)
      public void agendaMove(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to move an agenda item.");
              String src = ar.reqParam("src");
              String dest = ar.reqParam("dest");
              MeetingRecord meeting = ngp.findMeeting(src);
              MeetingRecord destMeeting = ngp.findMeeting(dest);
              JSONObject agendaInfo = getPostedObject(ar);
              String agendaId = agendaInfo.getString("id");
              meeting.removeAgendaItem(agendaId);
              meeting.renumberItems();

              AgendaItem ai = destMeeting.findAgendaItemOrNull(agendaId);
              if (ai==null) {
                  ai = destMeeting.createAgendaItem(ngp);
              }
              agendaInfo.put("position", 99999);
              ai.updateFromJSON(ar,agendaInfo);
              destMeeting.renumberItems();
              ngp.saveFile(ar, "Move Agenda Item");
              JSONObject repo = ai.getJSON(ar);
              repo.write(ar.w, 2, 2);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to movee agenda item.", ex);
              streamException(ee, ar);
          }
      }



      @RequestMapping(value = "/{siteId}/{pageId}/agendaItem.htm", method = RequestMethod.GET)
      public ModelAndView agendaItem(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              registerRequiredProject(ar, siteId, pageId);
              ModelAndView modelAndView= memberCheckViews(ar);
              if (modelAndView!=null) {
                  return modelAndView;
              }

              return new ModelAndView("AgendaItem");
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
          }
      }



      @RequestMapping(value = "/{siteId}/{pageId}/agendaUpdate.json", method = RequestMethod.POST)
      public void agendaUpdate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to update an agenda item.");
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);
              String aid = ar.reqParam("aid");
              AgendaItem ai = null;
              if (!"~new~".equals(aid)) {
                  ai = meeting.findAgendaItem(aid);
                  if (ai==null) {
                      throw new Exception("Can not find an agenda item ("+aid+") in meeting ("+id+")");
                  }
              }
              else {
                  ai = meeting.createAgendaItem(ngp);
              }
              JSONObject agendaInfo = getPostedObject(ar);

              //handle the position here to update the meeting order correctly
              int newPos = agendaInfo.optInt("position");
              int oldPos = ai.getPosition();
              if (newPos>0 && newPos!=oldPos) {
                  meeting.openPosition(newPos);
                  ai.setPosition(newPos);
                  meeting.renumberItems();
                  //put the final position (wherever it ended up)
                  //back into the JSON for the update below
                  agendaInfo.optInt("position", ai.getPosition());
              }

              //everything else updated here
              ai.updateFromJSON(ar, agendaInfo);

              ngp.saveFile(ar, "Updated Agenda Item");
              JSONObject repo = ai.getJSON(ar);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create agenda item.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/createMinutes.json", method = RequestMethod.POST)
      public void createMinutes(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to update an agenda item.");
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);

              NoteRecord nr = null;
              String minId =  meeting.getMinutesId();
              if (minId!=null && minId.length()>0) {
                  nr = ngp.getNoteByUidOrNull(minId);
              }
              if (nr==null) {
                  nr = ngp.createNote();
                  nr.setSubject("Minutes for Meeting: "+meeting.getName());
                  meeting.setMinutesId(nr.getUniversalId());
              }
              nr.setWiki(meeting.generateMinutes(ar,  ngp));
              nr.setModUser(ar.getUserProfile());

              //now copy all the attachment references across
              for (AgendaItem ai : meeting.getAgendaItems()) {
                  for (String aid : ai.getDocList()) {
                      AttachmentRecord att = ngp.findAttachmentByID(aid);
                      if (att!=null) {
                          nr.addDocId(aid);
                      }
                  }
              }
              nr.setLastEdited(ar.nowTime);

              ngp.saveFile(ar, "Created Topic for minutes of meeting.");
              JSONObject repo = meeting.getFullJSON(ar, ngp);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Topic for minutes of meeting.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/agendaBacklog.htm", method = RequestMethod.GET)
      public ModelAndView agendaBacklog(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              registerRequiredProject(ar, siteId, pageId);
              ModelAndView modelAndView= memberCheckViews(ar);
              if (modelAndView!=null) {
                  return modelAndView;
              }

              return new ModelAndView("AgendaBacklog");
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
          }
      }


      /*
       * Creates an action item that is associated with a meeting
       */
      @RequestMapping(value = "/{siteId}/{pageId}/createActionItem.json", method = RequestMethod.POST)
      public void createActionItem(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a action item.");
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);
              String aid = ar.reqParam("aid");
              AgendaItem ai = meeting.findAgendaItem(aid);

              JSONObject goalInfo = getPostedObject(ar);
              GoalRecord gr = ngp.createGoal();

              //create the history record here.
              HistoryRecord.createHistoryRecord(ngp, gr.getId(),
                      HistoryRecord.CONTEXT_TYPE_TASK, HistoryRecord.EVENT_TYPE_CREATED, ar,
                      "on meeting: "+meeting.getName());

              //currently the update from JSON is designed for upstream sync.
              //There is a check that requires this to do the update.
              goalInfo.put("universalid", gr.getUniversalId());
              gr.updateGoalFromJSON(goalInfo);
              ai.addActionItemId(gr.getUniversalId());

              ngp.saveFile(ar, "Created action item for minutes of meeting.");
              JSONObject repo = gr.getJSON4Goal(ngp);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Action Item for minutes of meeting.", ex);
              streamException(ee, ar);
          }
      }

      @RequestMapping(value = "/{siteId}/{pageId}/updateGoal.json", method = RequestMethod.POST)
      public void updateGoal(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          String gid = "";
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a action item.");
              gid = ar.reqParam("gid");
              JSONObject goalInfo = getPostedObject(ar);
              GoalRecord gr = null;
              int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
              boolean isNew = "~new~".equals(gid);
              if (isNew) {
                  gr = ngp.createGoal();
                  goalInfo.put("universalid", gr.getUniversalId());
                  eventType = HistoryRecord.EVENT_TYPE_CREATED;
              }
              else {
                  gr = ngp.getGoalOrFail(gid);
              }

              int previousState = gr.getState();
              String previousStatus = gr.getStatus();
              long previousDue = gr.getDueDate();

              gr.updateGoalFromJSON(goalInfo);

              //now make the history description of what just happened
              StringBuffer inventedComment = new StringBuffer(goalInfo.optString("newAccomplishment"));
              if (previousState != gr.getState()) {
                  inventedComment.append(" State:");
                  inventedComment.append(BaseRecord.stateName(gr.getState()));
              }
              if (!previousStatus.equals(gr.getStatus())) {
                  inventedComment.append(" Status:");
                  inventedComment.append(gr.getStatus());
              }
              if (previousDue != gr.getDueDate()) {
                  inventedComment.append(" DueDate:");
                  inventedComment.append(SectionUtil.getNicePrintDate(gr.getDueDate()));
              }
              String comments = inventedComment.toString();

              //create the history record here.
              HistoryRecord.createHistoryRecord(ngp, gr.getId(),
                      HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar,
                      comments);

              ngp.saveFile(ar, "Updated action item "+gid);
              JSONObject repo = gr.getJSON4Goal(ngp);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to update Action Item ("+gid+")", ex);
              streamException(ee, ar);
          }
      }

      @RequestMapping(value = "/{siteId}/{pageId}/getGoalHistory.json", method = RequestMethod.GET)
      public void getGoalHistory(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a action item.");
              String gid = ar.reqParam("gid");
              GoalRecord gr = ngp.getGoalOrFail(gid);

              JSONArray repo = new JSONArray();
              for (HistoryRecord hist : gr.getTaskHistory(ngp)) {
                  repo.put(hist.getJSON(ngp, ar));
              }
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Action Item for minutes of meeting.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/cloneMeeting.htm", method = RequestMethod.GET)
      public ModelAndView cloneMeeting(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              registerRequiredProject(ar, siteId, pageId);
              ModelAndView modelAndView= memberCheckViews(ar);
              if (modelAndView!=null) {
                  return modelAndView;
              }

              return new ModelAndView("CloneMeeting");
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/meetingFull.htm", method = RequestMethod.GET)
      public ModelAndView meetingFull(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response)
              throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              registerRequiredProject(ar, siteId, pageId);
              ModelAndView modelAndView= memberCheckViews(ar);
              if (modelAndView!=null) {
                  return modelAndView;
              }

              return new ModelAndView("MeetingFull");
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
          }
      }













      //A very simple form with a prompt for a user's display name  (dName)
      //and the user name is set with whatever is posted in.
      //Can only set the current logged in user name.
      //User session must be logged in (so you have a profile to set)
      @RequestMapping(value = "/requiredName.form", method = RequestMethod.POST)
      public void requireName_form(HttpServletRequest request, HttpServletResponse response)
          throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              String go = ar.defParam("go", ar.baseURL);
              if (ar.isLoggedIn()) {
                  UserProfile up = ar.getUserProfile();
                  String dName = ar.reqParam("dName");
                  up.setName(dName);
                  up.setLastUpdated(ar.nowTime);
                  UserManager.writeUserProfilesToFile();
              }
              response.sendRedirect(go);
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
          }
      }


      //A very simple form with a prompt for a user's email address which is
      //user to send a confirmation message, and another prompt to enter the
      //confirmation message.
      @RequestMapping(value = "/requiredEmail.form", method = RequestMethod.POST)
      public void requiredEmail_form(HttpServletRequest request, HttpServletResponse response)
          throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              String go = ar.defParam("go", ar.baseURL);
              String cmd = ar.reqParam("cmd");
              if (ar.isLoggedIn()) {
                  UserProfile up = ar.getUserProfile();
                  UserPage uPage = ar.getAnonymousUserPage();
                  if ("Send Email".equals(cmd)) {
                      String email = ar.reqParam("email");
                      ProfileRequest newReq = uPage.createProfileRequest(
                              ProfileRequest.ADD_EMAIL, email, ar.nowTime);
                      newReq.sendEmail(ar, go);
                      newReq.setUserKey(up.getKey());
                      uPage.save();
                  }
                  else if ("Confirmation Key".equals(cmd)) {
                      String cKey = ar.reqParam("cKey");

                      //look through the requests by email, and if the confirmation key matches
                      //then add the email, and remove the profile request.
                      for (ProfileRequest profi : uPage.getProfileRequests()) {
                          if (cKey.equals(profi.getSecurityToken())  &&
                                  up.getKey().equals(profi.getUserKey())) {
                              //ok, can only happen if same person received the message
                              String email = profi.getEmail();
                              String id = profi.getId();

                              //use it only ONCE
                              uPage.removeProfileRequest(id);
                              uPage.save();

                              //go ahead and add email to profile.
                              up.addId(email);
                              up.setPreferredEmail(email);
                              up.setLastUpdated(ar.nowTime);
                              UserManager.writeUserProfilesToFile();

                              break;
                          }
                      }
                  }
              }
              response.sendRedirect(go);
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
          }
      }


}
