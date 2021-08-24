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
import java.io.Writer;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;

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
    public static void assureSchemaMigration(NGSection sec, NGWorkspace ngp) throws Exception
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
                thisId = ngp.getUniqueOnPage();
                att.setId(thisId);
            }

            //to move this attachment, remove it from the source
            oldAttachmentsContainer.getElement().removeChild(att.getElement());

            //added Nov 2010
            //clean up mistake where versions of attachments were being created at new
            //top level attachment records with the same ID.  Only add the first occurrence
            //of any record with a given ID.   Throw away the other duplicates

            if (!idset.containsKey(thisId)) {
                AttachmentRecord newRec = ngp.createAttachment();
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


    public static void moveAttachmentsFromDeprecatedSection(NGSection oldSec) throws Exception
    {
        if (oldSec==null)
        {
            throw new Exception("Null parameter passed to moveAttachmentsFromDeprecatedSection");
        }
        List<AttachmentRecord> wrongPlaceAtts = oldSec.getChildren("attachment", AttachmentRecord.class);
        for (AttachmentRecord oldRec: wrongPlaceAtts)
        {
            AttachmentRecord newRec = oldSec.parent.createAttachment();
            newRec.copyFrom(oldRec);
            newRec.setId(oldRec.getId());

            //now remove from the source.
            DOMFace allSourceAttachments = oldSec.getChild("attachments", DOMFace.class);
            allSourceAttachments.removeChild(oldRec);
        }
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


    @Override
    public void writePlainText(NGSection section, Writer out) throws Exception
    {
        assertRightAttachmentsSection(section);
        for (AttachmentRecord attachment : section.parent.getAllAttachments())
        {
            SectionUtil.writeTextWithLB(attachment.getId() , out);
            SectionUtil.writeTextWithLB(attachment.getNiceName() , out);
            SectionUtil.writeTextWithLB(attachment.getURLValue() , out);
            SectionUtil.writeTextWithLB(attachment.getType() , out);
            SectionUtil.writeTextWithLB(attachment.getModifiedBy() , out);
            SectionUtil.writeTextWithLB(Long.toString(attachment.getModifiedDate()) , out);
            SectionUtil.writeTextWithLB(attachment.getDescription() , out);
        }
    }


    private void assertRightAttachmentsSection(NGSection sec) throws Exception
    {
        //there should only be on section of type attachments, and it should
        //be named "Attachments" so check this quickly to make sure that the
        //right section, and only the right section is being passed here.
        if (!"Attachments".equals(sec.getName())) {
            throw new Exception("Internal error, SectionAttachments was passed a section that is not named 'Attachments' but is named '"+sec.getName()+"' instead");
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
    public static void serveUpFileNewUI(AuthRequest ar, NGWorkspace ngp, String fileName, int version)
        throws Exception
    {
        if (ngp==null) {
            throw new ProgramLogicError("SectionAttachments can serve upthe attachment only when the workspace is known.");
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

            AttachmentVersion attachmentVersion = getVersionOrLatest(ngp,fileName,version);
            File attachmentFile =  attachmentVersion.getLocalFile();

            if (!attachmentFile.exists()) {
                throw new NGException("nugen.exception.attachment.not.exist", new Object[]{attachmentFile.getAbsolutePath()});
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
            throw new Exception("Unable to serve up a file named '"+fileName+"' from workspace '"+ngp.getFullName()+"'", e);
        }
    }


    /**
     * Returns a stream from which the contents of the file can be read.   Be sure to close the
     * stream when you are done with it.
     *
     * Specified version is returns, except if specified version does not exist, and then the latest
     * version is returned.   Throws exceptions if no version or no contents can be found.
     */
    public static AttachmentVersion getVersionOrLatest(NGWorkspace ngp, String fileName, int version)
            throws Exception {
        try {
            AttachmentRecord att = null;
            att = ngp.findAttachmentByNameOrFail(fileName);

            if (!att.hasContents()) {
                throw new NGException("nugen.exception.unable.to.serve.attachment", new Object[]{att.getType()});
            }

            AttachmentVersion attachmentVersion = att.getSpecificVersion(ngp, version);
            if (attachmentVersion!=null) {
                return attachmentVersion;
            }

            //not sure if this is the best course of action, to serve up the latest
            //maybe we should throw an exception, because after all they are not
            //getting the version requested.  Why are they asking for a version that
            //does not exist?
            attachmentVersion = att.getLatestVersion(ngp);
            if (attachmentVersion!=null) {
                return attachmentVersion;
            }

            throw new NGException("Attachment does not have ANY versions", new Object[0]);
        }
        catch (Exception e) {
            throw new Exception("Unable to get contents of version "+version+" file named '"+fileName+"' from workspace '"+ngp.getFullName()+"'", e);
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
