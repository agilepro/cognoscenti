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

import java.util.List;
import java.util.Vector;

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
import org.apache.lucene.store.RAMDirectory;
import org.apache.lucene.util.Version;


public class SearchManager {

    private static Directory directory = null;
    private static Analyzer analyzer = null;

    private SearchManager() {
        //no instances allowed
    }

    public static synchronized void initializeIndex(Cognoscenti cog) throws Exception {
        analyzer = new StandardAnalyzer(Version.LUCENE_42);
        directory = new RAMDirectory();

        AuthRequest ar = AuthDummy.serverBackgroundRequest();

        IndexWriterConfig config = new IndexWriterConfig(Version.LUCENE_42, analyzer);
        IndexWriter iWriter = new IndexWriter(directory, config);

        for (NGPageIndex ngpi : cog.getAllContainers()) {

            if (ngpi.isProject()) {

                NGPage ngp = ngpi.getPage();
                String projectKey = ngp.getKey();
                String projectName = ngp.getFullName();
                String accountName = ngp.getSite().getFullName();

                //add a record for the project as a whole
                {
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Project", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", projectKey, TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("NOTEID", "$", TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(ngp.getLastModifyTime()), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDUSER", ngp.getLastModifyUser(), TextField.TYPE_STORED));
                    StringBuffer bodyStuff = new StringBuffer();
                    bodyStuff.append(ngp.getFullName());
                    bodyStuff.append("\n");
                    for (GoalRecord goal : ngp.getAllGoals()) {
                        //put each goal in
                        bodyStuff.append(goal.getSynopsis());
                        bodyStuff.append("\n");
                    }
                    // put the name in a few times to increase those scores
                    bodyStuff.append(ngp.getFullName());
                    bodyStuff.append("\n");
                    bodyStuff.append(ngp.getFullName());
                    doc.add(new Field("BODY", bodyStuff.toString(), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                }



                for (NoteRecord note : ngp.getAllNotes()) {
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Project", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", projectKey, TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("NOTEID", note.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("NOTESUBJ", note.getSubject(), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(note.getLastEdited()), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDUSER", note.getModUser().getName(), TextField.TYPE_STORED));
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
                    doc.add(new Field("PAGENAME", projectName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", accountName, TextField.TYPE_STORED));
                    doc.add(new Field("MEETID", meet.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("MEETNAME", meet.getName(), TextField.TYPE_STORED));
                    doc.add(new Field("LASTMODIFIEDTIME", Long.toString(meet.getStartTime()), TextField.TYPE_STORED));
                    //doc.add(new Field("LASTMODIFIEDUSER", meet.getModUser().getName(), TextField.TYPE_STORED));
                    doc.add(new Field("BODY", meet.generateWikiRep(ar, ngp), TextField.TYPE_STORED));
                    for (AgendaItem ai : meet.getAgendaItems()) {
                        for (CommentRecord cr : ai.getComments()) {
                            doc.add(new Field("BODY", cr.getContent(), TextField.TYPE_STORED));
                        }
                    }
                    iWriter.addDocument(doc);
                }
            }
        }
        iWriter.commit();
        iWriter.close();
    }


    public static synchronized List<SearchResultRecord> performSearch(AuthRequest ar,
                String queryStr, String relationship, String siteId) throws Exception {

        Vector<SearchResultRecord> vec = new Vector<SearchResultRecord>();

        boolean onlyOwner = ("owner".equals(relationship));
        boolean onlyMember = ("member".equals(relationship));

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
            String noteId = hitDoc.get("NOTEID");
            String meetId = hitDoc.get("MEETID");
            String linkAddr = null;
            String noteSubject = null;

            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(key);

            //if restricted to one site, check that site first and skip if not matching
            if (siteId!=null) {
                if (!siteId.equals(ngp.getSiteKey())) {
                    continue;
                }
            }
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
                noteSubject = "Project: "+ngp.getFullName();
            }
            if (noteId!=null && noteId.length()==4) {
                NoteRecord note = ngp.getNoteOrFail(noteId);

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
            if (meetId!=null && meetId.length()==4) {
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
        return vec;
    }

}
