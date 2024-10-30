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
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.util.MimeTypes;

public class SectionAttachments extends SectionUtil implements SectionFormat
{

    public SectionAttachments()
    {
    }



    /**
    * READ CERFULLY:  This method is placed here to perform any schema migration
    * or any clean up tasks that need to be done on a document as it is read.
    * This method is called when the page is read into memory.
    * The migration will always update the document in memory, so that IF the
    * document is written out, it will always be written in the latest form.
    *
    * Each piece of schema migration code must be dated as of the date it was
    * introduced, so that when all documents have finally been updated,
    * that code can be removed as it is no longer needed.  Generally we will
    * leave such code in place for a period of two years.
    *
    * Care must be take so that new additions of the schema are not confused
    * with older versions of the schema.
    *
    */
    public static void assureSchemaMigration(NGSection sec, NGWorkspace ngw) throws Exception
    {
        //attachments are directly in the section element.  Earlier there was an 'attachments'
        //element, and attachments were in that.  Clean that up.

        DOMFace oldAttachmentsContainer = sec.getChild("attachments", DOMFace.class);
        if (oldAttachmentsContainer==null) {
            //if it does not exist then all is OK
            return;
        }

        List<AttachmentRecord> oldAtts = oldAttachmentsContainer.getChildren("attachment", AttachmentRecord.class);
        Hashtable<String,String> idset = new Hashtable<String,String>();
        sortByVersion(oldAtts);
        for(AttachmentRecord att : oldAtts) {
            //assure that all attachments have an ID added Dec 2009
            //Now, clean up the ids in case there are any missing ids, this will
            //migrate any existing documents without id values in the record
            String thisId = att.getId();
            if (thisId.length()==0) {
                thisId = ngw.getUniqueOnPage();
                att.setId(thisId);
            }

            //to move this attachment, remove it from the source
            oldAttachmentsContainer.getElement().removeChild(att.getElement());

            //added Nov 2010
            //clean up mistake where versions of attachments were being created at new
            //top level attachment records with the same ID.  Only add the first occurrence
            //of any record with a given ID.   Throw away the other duplicates

            if (!idset.containsKey(thisId)) {
                AttachmentRecord newRec = ngw.createAttachment();
                newRec.copyFrom(att);
                newRec.setId(att.getId());
            }
            idset.put(thisId, thisId);
        }

        //remove the old attachments element
        sec.removeChild(oldAttachmentsContainer);
    }



    /**
    * get the name of the format
    */
    @Override
    public String getName()
    {
        return "Attachments Format";
    }

    /**
    * pass ar=null if you do not want any history records created
    * recording that the document was removed.
    */
    public static void removeAttachments( AuthRequest ar, NGSection ngs, List<String> fileIdsToBeRemoved)
        throws Exception
    {
        if (fileIdsToBeRemoved == null || fileIdsToBeRemoved.size() == 0) {
            //nothing to do
            return;
        }

        // remove the files that were marked for delete.
        for (String fileid : fileIdsToBeRemoved) {
            AttachmentRecord att = ngs.parent.findAttachmentByID(fileid);
            if (att!=null) {
                ngs.parent.deleteAttachment(fileid,ar);
                att.createHistory(ar, ngs.parent, HistoryRecord.EVENT_DOC_REMOVED, "");
            }
        }
    }


    /**
    * Walk through whatever elements this owns and put all the four digit
    * IDs into the vector so that we can generate another ID and assure it
    * does not duplication any id found here.
    */
    @Override
    public void findIDs(List<String> v, NGSection sec)
        throws Exception
    {
        //legacy upgrade...there are some old attachments sections that are to be automatically
        //deleted or migrated during schema migration.  Unfortunately, there are some calls to
        //get unique ids during schema migration, and possibly before this section has had a
        //chance to be migrated.  So rather than bomb out, the search of IDs should search even
        //outdated or legacy sections. The idea begin findIds is that finding more IDs is better
        //than skipping IDs and possibly causing a clash.

        List<DOMFace> attChildren = sec.getChildren("attachment", DOMFace.class);
        for (DOMFace att : attChildren) {
            v.add(att.getAttribute("id"));
        }
    }

    /**
    * This is a method to find a file, and output the file as a
    * stream of bytes to the request output stream.
    */
    public static void serveUpFileNewUI(AuthRequest ar, NGWorkspace ngw, String fileName, int version)
        throws Exception
    {
        if (ngw==null) {
            throw WeaverException.newBasic("SectionAttachments can serve upthe attachment only when the workspace is known.");
        }
        try {
            //get the mime type from the file extension
            String mimeType=MimeTypes.getMimeType(fileName);
            ar.resp.setContentType(mimeType);
            //set expiration to about 1 year from now
            ar.resp.setDateHeader("Expires", ar.nowTime+3000000);

            // Temporary fix: To force the browser to show 'SaveAs' dialogbox with right format.
            // Note this originally had some code that assumed that old versions of a file
            // might have a different extension.  I don't see how this can happen.
            // The attachment has a name, and that name holds for all versions.  If you
            // change the name, it changes all the versions.  I don't see how old
            // versions might have a different extension....  Removed complicated logic.
            ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );

            AttachmentVersion attachmentVersion = getVersionOrLatest(ngw,fileName,version);
            File attachmentFile =  attachmentVersion.getLocalFile();

            if (!attachmentFile.exists()) {
                throw WeaverException.newBasic("Attachment '%s' does not exist.", attachmentFile.getAbsolutePath());
            }

            ar.resp.setHeader( "Content-Length", Long.toString(attachmentVersion.getFileSize()) );

            InputStream fis = new FileInputStream(attachmentFile);
            ar.streamBytesOut(fis);
            fis.close();
        }
        catch (Exception e) {
            //why sleep?  Here, this is VERY IMPORTANT
            //Someone might be trying all the possible file names just to
            //see what is here.  A three second sleep makes that more difficult.
            Thread.sleep(3000);
            throw WeaverException.newWrap("Unable to serve up a file named '%s' from workspace '%s'", e, fileName, ngw.getFullName());
        }
    }


    /**
     * Returns a stream from which the contents of the file can be read.   Be sure to close the
     * stream when you are done with it.
     *
     * Specified version is returns, except if specified version does not exist, and then the latest
     * version is returned.   Throws exceptions if no version or no contents can be found.
     */
    public static AttachmentVersion getVersionOrLatest(NGWorkspace ngw, String fileName, int version)
            throws Exception {
        try {
            AttachmentRecord att = null;
            att = ngw.findAttachmentByNameOrFail(fileName);

            if (!att.hasContents()) {
                throw WeaverException.newBasic("Can only serve up attachments of type FILE, this attachment appears to be of type '%s'", att.getType());
            }

            AttachmentVersion attachmentVersion = att.getSpecificVersion(ngw, version);
            if (attachmentVersion!=null) {
                return attachmentVersion;
            }

            //not sure if this is the best course of action, to serve up the latest
            //maybe we should throw an exception, because after all they are not
            //getting the version requested.  Why are they asking for a version that
            //does not exist?
            attachmentVersion = att.getLatestVersion(ngw);
            if (attachmentVersion!=null) {
                return attachmentVersion;
            }

            throw WeaverException.newBasic("Attachment does not have ANY versions");
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to get contents of version %s file named '%s' from workspace '%s'", 
                    e, version, fileName, ngw.getFullName());
        }
    }

    public static void sortByVersion(List<AttachmentRecord> listToSort)
    {
        Collections.sort(listToSort, new AttachmentRecordComparator());
    }
    public static void sortByName(List<AttachmentRecord> listToSort)
    {
        Collections.sort(listToSort, new AttachmentNameComparator());
    }
    public static void sortByDate(List<AttachmentRecord> listToSort)
    {
        Collections.sort(listToSort, new AttachmentDateComparator());
    }


    static class AttachmentRecordComparator implements Comparator<AttachmentRecord>{

        @Override
        public int compare(AttachmentRecord paramT1, AttachmentRecord paramT2) {

            int version1 = paramT1.getVersion();
            int version2 = paramT2.getVersion();

            if( version1 < version2 ) {
                return 1;
            }
            else if( version1 > version2 ) {
                return -1;
            }
            else {
                return 0;
            }
        }
    }
    static class AttachmentNameComparator implements Comparator<AttachmentRecord>{

        @Override
        public int compare(AttachmentRecord paramT1, AttachmentRecord paramT2) {

            String name1 = paramT1.getNiceName();
            String name2 = paramT2.getNiceName();

            int comp = name1.compareTo(name2);
            if (comp!=0)
            {
                return comp;
            }

            int version1 = paramT1.getVersion();
            int version2 = paramT2.getVersion();

            if( version1 < version2 ) {
                return 1;
            }
            else if( version1 > version2 ) {
                return -1;
            }
            else {
                return 0;
            }
        }
    }
    static class AttachmentDateComparator implements Comparator<AttachmentRecord>{

        @Override
        public int compare(AttachmentRecord paramT1, AttachmentRecord paramT2) {

            long date1 = paramT1.getModifiedDate();
            long date2 = paramT2.getModifiedDate();

            //note, this is REVERSE chrono order
            if( date2 < date1 )
            {
                return 1;
            }
            else if( date2 > date1 )
            {
                return -1;
            }


            String name1 = paramT1.getNiceName();
            String name2 = paramT2.getNiceName();

            int comp = name1.compareTo(name2);
            if (comp!=0)
            {
                return comp;
            }

            int version1 = paramT1.getVersion();
            int version2 = paramT2.getVersion();

            if( version1 < version2 ) {
                return 1;
            }
            else if( version1 > version2 ) {
                return -1;
            }
            else {
                return 0;
            }
        }
    }

}
