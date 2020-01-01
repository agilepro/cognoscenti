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

package org.socialbiz.cog;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.analysis.standard.StandardAnalyzer;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.TextField;
import org.apache.lucene.index.DirectoryReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.IndexWriterConfig;
import org.apache.lucene.queryparser.classic.QueryParser;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.Query;
import org.apache.lucene.search.ScoreDoc;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.store.Directory;
import org.apache.lucene.store.FSDirectory;
import org.apache.lucene.util.Version;


public class SearchManager {

    private Directory directory = null;
    private Analyzer analyzer = null;
    private Cognoscenti cog = null;

    public SearchManager(Cognoscenti _cog) {
        cog = _cog;
    }

    public synchronized void initializeIndex() throws Exception {
        analyzer = new StandardAnalyzer(Version.LUCENE_42);

        File directoryFolder = new File(cog.getConfig().getUserFolderOrFail(), ".search");

        //directory = new RAMDirectory();
        if (directory==null) {
            directory = FSDirectory.open(directoryFolder);
        }

        long startTime = System.currentTimeMillis();
        System.out.println("SearchManager - starting to build the internal index.");

        AuthRequest ar = AuthDummy.serverBackgroundRequest();

        IndexWriterConfig config = new IndexWriterConfig(Version.LUCENE_42, analyzer);
        IndexWriter iWriter = new IndexWriter(directory, config);

        //get rid of all the existing files.   Make sure that search methods
        //are synchronized so you don't have any searches  while updating the index.
        iWriter.deleteAll();

        for (NGPageIndex ngpi : cog.getAllContainers()) {

            if (ngpi.isProject()) {

                NGWorkspace ngp = ngpi.getWorkspace();
                if (ngp.isDeleted()) {
                    //skip all deleted workspaces
                    continue;
                }

                NGBook site = ngp.getSite();
                if (site.isDeleted()) {
                    //skip all deleted sites
                    continue;
                }
                if (site.isMoved()) {
                    //skip all moved sites
                    continue;
                }


                String projectKey = ngp.getKey();
                String siteKey = ngp.getSiteKey();
                String projectName = ngp.getFullName();
                String accountName = ngp.getSite().getFullName();

                //add a record for the project as a whole
                {
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Project", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", projectKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("NOTEID", "$", TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(ngp.getLastModifyTime()), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDUSER", ngp.getLastModifyUser(), TextField.TYPE_STORED));
                    StringBuilder bodyStuff = new StringBuilder();
                    bodyStuff.append(ngp.getFullName());
                    bodyStuff.append("\n");
                    for (GoalRecord goal : ngp.getAllGoals()) {
                        //put each goal in
                        bodyStuff.append(goal.getSynopsis());
                        bodyStuff.append("\n");
                    }
                    ProcessRecord process = ngp.getProcess();
                    String s = process.getScalar("description");
                    System.out.println("INDEXING: aim for "+ngp.getFullName()+" IS "+s);
                    bodyStuff.append(s);   //a.k.a. "aim"
                    bodyStuff.append("\n");
                    bodyStuff.append(process.getScalar("mission"));
                    bodyStuff.append("\n");
                    bodyStuff.append(process.getScalar("vision"));
                    bodyStuff.append("\n");
                    bodyStuff.append(process.getScalar("domain"));
                    bodyStuff.append("\n");
                    // put the name in a few times to increase those scores
                    bodyStuff.append(ngp.getFullName());
                    bodyStuff.append("\n");
                    bodyStuff.append(ngp.getFullName());
                    doc.add(new Field("BODY", bodyStuff.toString(), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                }



                for (TopicRecord note : ngp.getAllDiscussionTopics()) {
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Project", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", projectKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("NOTEID", note.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("NOTESUBJ", note.getSubject(), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(note.getLastEdited()), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDUSER", note.getModUser().getName(), TextField.TYPE_STORED));

                    //first add the subject, then add the text of the note, then all the comments
                    doc.add(new Field("BODY", note.getSubject(), TextField.TYPE_STORED));
                    doc.add(new Field("BODY", note.getWiki(), TextField.TYPE_STORED));
                    for (CommentRecord cr : note.getComments()) {
                        doc.add(new Field("BODY", cr.getContent(), TextField.TYPE_STORED));
                    }
                    iWriter.addDocument(doc);
                }
                for (MeetingRecord meet : ngp.getMeetings()) {
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Project", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", projectKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("MEETID", meet.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("MEETNAME", meet.getName(), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(meet.getStartTime()), TextField.TYPE_STORED));

                    doc.add(new Field("BODY", meet.getName(), TextField.TYPE_STORED));
                    doc.add(new Field("BODY", meet.generateWikiRep(ar, ngp), TextField.TYPE_STORED));
                    for (AgendaItem ai : meet.getSortedAgendaItems()) {
                        for (CommentRecord cr : ai.getComments()) {
                            doc.add(new Field("BODY", cr.getContent(), TextField.TYPE_STORED));
                        }
                    }
                    iWriter.addDocument(doc);
                }

                for (DecisionRecord dec : ngp.getDecisions()) {
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Project", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", projectKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("DECISIONID", Integer.toString(dec.getNumber()), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(dec.getTimestamp()), TextField.TYPE_STORED));

                    doc.add(new Field("BODY", dec.getDecision(), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                }
            }
        }
        System.out.println("SearchManager - finished building index: "+(System.currentTimeMillis()-startTime)+" ms");
        iWriter.commit();
        iWriter.close();
    }


    public synchronized List<SearchResultRecord> performSearch(AuthRequest ar,
                String queryStr, String relationship, String siteId, String workspaceId) throws Exception {

        long startTime = System.currentTimeMillis();
        System.out.println("SearchManager - actually performing a search for "+queryStr);
        List<SearchResultRecord> vec = new ArrayList<SearchResultRecord>();

        boolean onlyOwner  = ("owner".equals(relationship));
        boolean onlyMember = ("member".equals(relationship));
        boolean onlyOne    = ("one".equals(relationship));

        DirectoryReader ireader = DirectoryReader.open(directory);
        IndexSearcher isearcher = new IndexSearcher(ireader);
        // Parse a simple query that searches for "text":
        QueryParser parser = new QueryParser(Version.LUCENE_42, "BODY", analyzer);
        Query query = parser.parse(queryStr);
        TopDocs td = isearcher.search(query, null, 1000);
        ScoreDoc[] hits = td.scoreDocs;

        UserProfile up = ar.getUserProfile();
        boolean isLoggedIn = (up!=null);

        for (int i = 0; i < hits.length; i++)
        {
            Document hitDoc = isearcher.doc(hits[i].doc);
            String key = hitDoc.get("PAGEKEY");
            String siteKey = hitDoc.get("SITEKEY");
            String noteId = hitDoc.get("NOTEID");
            String meetId = hitDoc.get("MEETID");
            String decId = hitDoc.get("DECISIONID");
            String linkAddr = null;
            String noteSubject = null;

            //if restricted to one site, check that site first and skip if not matching
            if (siteId!=null) {
                if (!siteId.equals(siteKey)) {
                    continue;
                }
            }
            //if restricted to one workspace, check that first as well
            if (onlyOne && workspaceId!=null) {
                if (!workspaceId.equals(key)) {
                    continue;
                }
            }            
            
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteKey, key).getWorkspace();

            if (onlyOwner) {
                if (!ngp.secondaryPermission(up)) {
                    continue;
                }
            }
            if (onlyMember) {
                if (!ngp.primaryOrSecondaryPermission(up)) {
                    continue;
                }
            }

            if ("$".equals(noteId)) {
                //this is the case of the entire page search record
                linkAddr = ar.getDefaultURL(ngp);
                noteSubject = "Workspace: "+ngp.getFullName();
            }
            else if (noteId!=null && noteId.length()==4) {
                TopicRecord note = ngp.getNoteOrFail(noteId);

                if (note.getVisibility()==SectionDef.PUBLIC_ACCESS) {
                    //ok to access public topic
                }
                else if (!isLoggedIn) {
                    continue;   //don't include this result if not logged in
                }
                else if (ngp.primaryOrSecondaryPermission(up)) {
                    //OK no problem, user is a member or admin
                }
                else {
                    continue; //no access to non members
                }
                noteSubject = note.getSubject();
                linkAddr = ar.getResourceURL(ngp, note);
            }
            else if (meetId!=null && meetId.length()==4) {
                if (!isLoggedIn) {
                    continue;   //don't include this result if not logged in
                }
                else if (ngp.primaryOrSecondaryPermission(up)) {
                    //OK no problem, user is a member or admin
                }
                else {
                    continue; //no access to non members
                }
                MeetingRecord meet = ngp.findMeeting(meetId);

                noteSubject = meet.getName();
                linkAddr = ar.getResourceURL(ngp, "meetingFull.htm?id="+meetId);
            }
            else if (decId!=null) {
                if (!isLoggedIn) {
                    continue;   //don't include this result if not logged in
                }
                else if (ngp.primaryOrSecondaryPermission(up)) {
                    //OK no problem, user is a member or admin
                }
                else {
                    continue; //no access to non members
                }
                //DecisionRecord dec = ngp.findDecisionOrFail(DOMFace.safeConvertInt(decId));

                noteSubject = "Decision "+decId;
                linkAddr = ar.getResourceURL(ngp, "decisionList.htm#DEC"+decId);
            }


            SearchResultRecord sr = new SearchResultRecord();
            sr.setPageName(hitDoc.get("PAGENAME"));
            sr.setPageKey(key);
            sr.setBookName(hitDoc.get("ACCTNAME"));
            sr.setNoteSubject(noteSubject);
            sr.setNoteLink(linkAddr);
            sr.setPageLink(ar.getDefaultURL(ngp));
            sr.setLastModifiedTime(DOMFace.safeConvertLong(hitDoc.get("LASTMODIFIEDTIME")));
            sr.setLastModifiedBy(hitDoc.get("LASTMODIFIEDUSER"));
            vec.add(sr);
        }

        ireader.close();
        System.out.println("SearchManager - finished serching: "+(System.currentTimeMillis()-startTime)+" ms");
        return vec;
    }

}
