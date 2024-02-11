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

package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;
import java.nio.file.Path;

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

import com.purplehillsbooks.streams.MemFile;
import com.purplehillsbooks.streams.StreamHelper;


public class SearchManager {

    private Directory directoryStore = null;
    private Analyzer analyzer = null;
    private Cognoscenti cog = null;

    public SearchManager(Cognoscenti _cog) {
        cog = _cog;
    }

    public static void writeStringToFile(String str, File file) throws Exception {
        StringReader sr = new StringReader(str);
        StreamHelper.copyReaderToFile(sr, file, "UTF-8");
    }
    public static void addString(MemFile mf, String str) throws Exception {
        StringReader sr = new StringReader(str);
        mf.fillWithReader(sr);
    }
    
    private Directory getStore() throws Exception {
        File directoryFolder = new File(cog.getConfig().getUserFolderOrFail(), ".search");
        Path dirPath = directoryFolder.toPath();
        System.out.println("SearchManager - starting to build index in ("+directoryFolder.getCanonicalPath()+")");

        //directory = new RAMDirectory();
        if (directoryStore==null) {
            directoryStore = FSDirectory.open(dirPath);
        }
        
        return directoryStore;
    }
    
    public void cleanOutIndex() throws Exception {
        Directory dirStore = getStore();
        IndexWriterConfig config = new IndexWriterConfig(analyzer);
        IndexWriter iWriter = new IndexWriter(dirStore, config);
        try {
            iWriter.deleteAll();
            for (NGPageIndex ngpi : cog.getAllContainers()) {
                File containingFolder = ngpi.containerPath.getParentFile();
                File searchFile = new File(containingFolder, "search.txt");
                if (searchFile.exists()) {
                    searchFile.delete();
                }
            }
        }
        finally {
            iWriter.close();
        }
        System.out.println("SearchManager - index completely cleared");
    }
    
    public String max50(String str) {
        if (str==null) {
            return null;
        }
        if (str.length()<=50) {
            return str;
        }
        return str.substring(0,50);
    }
    
    /**
    * Given a block of wiki formatted text, this will strip out all the
    * formatting characters, but write out everything else as plain text.
    */
    private static String stripWikiFormatting(String wikiData) throws Exception
    {
        StringBuilder sb = new StringBuilder();
        LineIterator li = new LineIterator(wikiData);
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            sb.append(stripWikiFromLine(thisLine));
            sb.append("\n");
        }
        return sb.toString();
    }

    protected static String stripWikiFromLine(String line)
            throws Exception
    {
        if (line == null || ((line = line.trim()).length()) == 0) {
            return "";
        }

        if (line.startsWith("----"))
        {
            line = line.substring(4);
        }
        else if (line.startsWith("!!!") || (line.startsWith("***")))
        {
            line = line.substring(3);
        }
        else if (line.startsWith("!!") || (line.startsWith("**")))
        {
            line = line.substring(2);
        }
        else if (line.startsWith("!") || (line.startsWith("*")))
        {
            line = line.substring(1);
        }
        line = line.replaceAll("__", "");
        line = line.replaceAll("''", "");
        line = line.replaceAll("\\[", "");
        line = line.replaceAll("\\]", "");
        line = line.replaceAll("\\|", "");
        return line;
    }    
    
    private synchronized void initializeIndex() throws Exception {
        analyzer = new StandardAnalyzer();

        long startTime = System.currentTimeMillis();

        AuthRequest ar = AuthDummy.serverBackgroundRequest();

        Directory dirStore = getStore();
        IndexWriterConfig config = new IndexWriterConfig(analyzer);

        for (NGPageIndex ngpi : cog.getAllContainers()) {

            if (!ngpi.isWorkspace()) {
                //we only index workspaces
                continue;
            }
            if (ngpi.isDeleted) {
                //skip all deleted workspaces
                continue;
            }
            NGBook site = ngpi.getSiteForWorkspace();
            if (site.isDeleted()) {
                //skip all deleted sites
                continue;
            }
            if (site.isMoved()) {
                //skip all moved sites
                continue;
            }
            
            File containingFolder = ngpi.containerPath.getParentFile();
            File searchFile = new File(containingFolder, "search.txt");
            if (searchFile.exists() && searchFile.lastModified() > ngpi.containerPath.lastModified()) {
                //seems this version of the workspace has already been indexed
                //System.out.println("[-][-][-] skipping [-][-][-] "+ngpi.wsSiteKey+"/"+ngpi.containerKey);
                continue;
            }
            
            
            NGWorkspace ngw = ngpi.getWorkspace();
            if (ngw.isDeleted()) {
                //skip all deleted workspaces in case different from above
                continue;
            }

            String workspaceKey = ngw.getKey();
            //we can't tolerate any hyphens in the page key
            if (workspaceKey.startsWith("-")) {
                //forget it, we simply can't index pages that start with hyphen
                System.out.println("SearchManager - can not handle workspace ("+workspaceKey+")");
                continue;
            }
            String siteKey = ngw.getSiteKey();
            String workspaceName = ngw.getFullName();
            String siteName = ngw.getSite().getFullName();
            
            System.out.println("SearchManager - Updating workspace "+ngpi.wsSiteKey+"/"+ngpi.containerKey);
            
            IndexWriter iWriter = new IndexWriter(dirStore, config);
            

            try {
                //delete all documents with workspace equal to the workspace key
                QueryParser parser = new QueryParser("BODY", analyzer);
                Query query = parser.parse("PAGEKEY:"+workspaceKey);
                iWriter.deleteDocuments(query);
                
                MemFile mf = new MemFile();
                
                {
                    //add a record for the workspace as a whole
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Workspace", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(ngw.getLastModifyTime()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", "$", TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(workspaceName), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "FrontPage.htm", TextField.TYPE_STORED));
                    
                    StringBuilder bodyStuff = new StringBuilder();
                    bodyStuff.append(siteName);
                    bodyStuff.append("\n");
                    bodyStuff.append(workspaceName);
                    bodyStuff.append("\n");
                    ProcessRecord process = ngw.getProcess();
                    bodyStuff.append(stripWikiFormatting(process.getScalar("description")));   //a.k.a. "aim"
                    bodyStuff.append("\n");
                    bodyStuff.append(stripWikiFormatting(process.getScalar("mission")));
                    bodyStuff.append("\n");
                    bodyStuff.append(stripWikiFormatting(process.getScalar("vision")));
                    bodyStuff.append("\n");
                    bodyStuff.append(stripWikiFormatting(process.getScalar("domain")));
                    bodyStuff.append("\n");
                    // put the name in a few times to increase those scores
                    bodyStuff.append(ngw.getFullName());
                    bodyStuff.append("\n");
                    bodyStuff.append(ngw.getFullName());
                    doc.add(new Field("BODY", bodyStuff.toString(), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                    addString(mf, doc.toString());
                }



                for (TopicRecord note : ngw.getAllDiscussionTopics()) {
                    String itemName = note.getSubject();
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Topic", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(note.getLastEdited()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", note.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(itemName), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "noteZoom"+note.getId()+".htm", TextField.TYPE_STORED));
                    

                    //first add the subject, then add the text of the note, then all the comments
                    doc.add(new Field("BODY", itemName, TextField.TYPE_STORED));
                    doc.add(new Field("BODY", stripWikiFormatting(note.getWiki()), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                    addString(mf, "\n=============== TOPIC\n");
                    addString(mf, doc.toString());
                }
                for (MeetingRecord meet : ngw.getMeetings()) {
                    String itemName = meet.getName();
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Meeting", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(meet.getStartTime()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", meet.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(itemName), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "MeetingHtml.htm?id="+meet.getId(), TextField.TYPE_STORED));
                    

                    doc.add(new Field("MEETNAME", meet.getName(), TextField.TYPE_STORED));

                    doc.add(new Field("BODY", itemName, TextField.TYPE_STORED));
                    doc.add(new Field("BODY", stripWikiFormatting(meet.generateWikiRep(ar, ngw)), TextField.TYPE_STORED));
                    for (AgendaItem ai : meet.getSortedAgendaItems()) {
                        doc.add(new Field("BODY", stripWikiFormatting(ai.getMeetingNotes()), TextField.TYPE_STORED));
                        doc.add(new Field("BODY", stripWikiFormatting(ai.getDesc()), TextField.TYPE_STORED));
                    }
                    iWriter.addDocument(doc);
                    addString(mf, "\n=============== MEETING\n");
                    addString(mf, doc.toString());
                }

                for (DecisionRecord dec : ngw.getDecisions()) {
                    String itemName = stripWikiFormatting(dec.getDecision());
                    if (itemName.length()<5) {
                        //short decisions are not searchable
                        continue;
                    }
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Decision", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(dec.getTimestamp()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", Integer.toString(dec.getNumber()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(itemName), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "DecisionList.htm#DEC"+dec.getNumber(), TextField.TYPE_STORED));

                    doc.add(new Field("BODY", itemName, TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                    addString(mf, "\n=============== DECISION\n");
                    addString(mf, doc.toString());
                }

                for (AttachmentRecord att : ngw.getAllAttachments()) {
                    if (att.isDeleted()) {
                        continue; //skip deleted attachments
                    }
                    String itemName = att.getNiceName();
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Document", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(att.getModifiedDate()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", att.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(itemName), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "DocDetail.htm?aid="+att.getId(), TextField.TYPE_STORED));

                    doc.add(new Field("BODY", itemName + "\n" + stripWikiFormatting(att.getDescription()), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                    addString(mf, "\n=============== DOCUMENT\n");
                    addString(mf, doc.toString());
                }
                
                for (CommentRecord comment : ngw.getAllComments()) {
                    String itemName = stripWikiFormatting(comment.getAllSearchableText());
                    if (itemName.length()<5) {
                        //short comments are not searchable, like phase change messages
                        continue;
                    }
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Comment", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(comment.getTime()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", Long.toString(comment.getTime()), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(itemName), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "CommentZoom.htm?cid="+comment.getTime(), TextField.TYPE_STORED));

                    doc.add(new Field("BODY", itemName, TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                    addString(mf, "\n=============== COMMENT\n");
                    addString(mf, doc.toString());
                }
                for (GoalRecord goal : ngw.getAllGoals()) {
                    String itemName = goal.getSynopsis();
                    if (itemName.length()<5) {
                        //short action items are not searchable
                        continue;
                    }
                    long itemTime = goal.getDueDate();
                    if (itemTime<10) {
                        itemTime = goal.getStartDate();
                    }
                    if (itemTime<10) {
                        itemTime = goal.getEmailSendTime();
                    }
                    Document doc = new Document();
                    doc.add(new Field("containerType", "Action Item", TextField.TYPE_STORED));
                    doc.add(new Field("PAGEKEY", workspaceKey, TextField.TYPE_STORED));
                    doc.add(new Field("SITEKEY", siteKey,    TextField.TYPE_STORED));
                    doc.add(new Field("PAGENAME", workspaceName, TextField.TYPE_STORED));
                    doc.add(new Field("ACCTNAME", siteName, TextField.TYPE_STORED));
                    doc.add(new Field("MODTIME", Long.toString(itemTime), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMNAME", max50(itemName), TextField.TYPE_STORED));
                    doc.add(new Field("ITEMID", goal.getId(), TextField.TYPE_STORED));
                    doc.add(new Field("LINK", "task"+goal.getId()+".htm", TextField.TYPE_STORED));

                    doc.add(new Field("BODY", stripWikiFormatting(goal.getAllSearchableText()), TextField.TYPE_STORED));
                    iWriter.addDocument(doc);
                    addString(mf, "\n=============== ACTION ITEM\n");
                    addString(mf, doc.toString());
                }
                
                //now make a copy of the searchable text into a temp file
                if (searchFile.exists()) {
                    searchFile.delete();
                }
                StreamHelper.copyStreamToFile(mf.getInputStream(), searchFile);
                iWriter.commit();
            }
            finally {
                iWriter.close();
            }
        }
        System.out.println("SearchManager - finished building index: "+(System.currentTimeMillis()-startTime)+" ms");
    }


    public synchronized List<SearchResultRecord> performSearch(AuthRequest ar,
                String queryStr, String relationship, String siteId, String workspaceId) throws Exception {

        long startTime = System.currentTimeMillis();
        
        
        //rebuild the parts of the index that have changed
        initializeIndex();
        
        System.out.println("SearchManager - actually performing a search for ("+queryStr+") "+relationship);
        List<SearchResultRecord> vec = new ArrayList<SearchResultRecord>();
        if (!ar.isLoggedIn()) {
            return vec;   //bomb out without searching for anything
        }

        boolean onlyOwner  = ("owner".equals(relationship));
        //boolean onlyMember = ("member".equals(relationship));
        boolean onlyOne    = ("one".equals(relationship));

        DirectoryReader ireader = DirectoryReader.open(directoryStore);
        IndexSearcher isearcher = new IndexSearcher(ireader);
        
        // Parse a simple query that searches for "text":
        QueryParser parser = new QueryParser("BODY", analyzer);
        Query query = parser.parse(queryStr);
        
        TopDocs td = isearcher.search(query, 1000);
        ScoreDoc[] hits = td.scoreDocs;

        UserProfile up = ar.getUserProfile();

        for (int i = 0; i < hits.length; i++)
        {
            Document hitDoc = isearcher.doc(hits[i].doc);
            String containerType = hitDoc.get("containerType");
            String key = hitDoc.get("PAGEKEY");
            String siteKey = hitDoc.get("SITEKEY");
            String link = hitDoc.get("LINK");
            String itemName = containerType+": "+hitDoc.get("ITEMNAME");
            
            long updateTime = DOMFace.safeConvertLong(hitDoc.get("MODTIME"));

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

            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteKey, key).getWorkspace();
            if (!ngw.primaryOrSecondaryPermission(up)) {
                continue;   //don't include anything else if not a member
            }
            
            String linkAddr = ar.getResourceURL(ngw, link);
            if (onlyOwner) {
                if (!ngw.secondaryPermission(up)) {
                    continue;
                }
            }
          

            SearchResultRecord sr = new SearchResultRecord();
            sr.setPageName(hitDoc.get("PAGENAME"));
            sr.setPageKey(key);
            sr.setBookName(hitDoc.get("ACCTNAME"));
            sr.setNoteSubject(itemName);
            sr.setNoteLink(linkAddr);
            sr.setPageLink(ar.getDefaultURL(ngw));
            sr.setLastModifiedTime(updateTime);
            vec.add(sr);
        }

        ireader.close();
        System.out.println("SearchManager - finished serching: "+(System.currentTimeMillis()-startTime)+" ms");
        return vec;
    }

}
