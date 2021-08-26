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

package com.purplehillsbooks.weaver.spring;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.springframework.web.multipart.MultipartFile;

/**
* AttachmentHelper is a static class that contains helpful
* methods for handling attachments
*/
public class AttachmentHelper {

    public static void uploadNewDocument(AuthRequest ar,
                                            NGWorkspace ngc,
                                            MultipartFile file,
                                            String desiredName,
                                            String visibility,
                                            String comment,
                                            String modUser) throws Exception {

        //first, default the desired name if one was not set
        String fileName = file.getOriginalFilename();
        if (desiredName==null || desiredName.length()==0) {
            desiredName = fileName;
        }

        //first look for an attachment with this name, if found use that
        //and stream a new version of that attachment, otherwise, create a new.
        AttachmentRecord attachment =  ngc.findAttachmentByName(desiredName);
        if (attachment==null) {
            attachment =  ngc.createAttachment();
            attachment.setDisplayName(desiredName);
        }
        attachment.setDescription(comment);
        attachment.setModifiedBy(modUser);
        attachment.setModifiedDate(ar.nowTime);
        attachment.setType("FILE");
        attachment.setVersion(1);

        //if the existing document is marked deleted, you want to clear
        //that now that a new version has appeared.  Otherwise the new
        //uploaded document remains deleted.
        attachment.clearDeleted();

        setDisplayName(ngc, attachment, assureExtension(desiredName, fileName));
        saveUploadedFile(ar, attachment, file);
        HistoryRecord.createHistoryRecord(ngc, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                ar.nowTime, HistoryRecord.EVENT_DOC_ADDED, ar, "");

        ngc.saveFile(ar, comment);
    }



    public static String saveUploadedFile(AuthRequest ar, AttachmentRecord att,
            MultipartFile file) throws Exception {

        if(file.getSize() <= 0){
            //not sure why this would ever happen, but I saw other checks in the code for zero length
            //an just copying that here in the right place to check for it.
            throw new NGException("nugen.exception.file.size.zero",null);
        }
        String originalName = file.getOriginalFilename();


        // Figure out the file extension (including dot)
        if (originalName.indexOf("\\") >= 0) {
            throw new ProgramLogicError(
                    "Strange, got a path with a backslash.  This code assumes that will never happen. "
                            + originalName);
        }
        if (originalName.indexOf("/") >= 0) {
            throw new ProgramLogicError(
                    "Just checking: the source file name should not have any slashes "
                            + originalName);
        }
        int dotPos = originalName.lastIndexOf(".");
        if (dotPos < 0) {
            throw new NGException("nugen.exception.file.ext.missing",null);
        }
        String fileExtension = originalName.substring(dotPos);

        File tempFile = File.createTempFile("~editaction",  fileExtension);
        tempFile.delete();
        saveToFileAH(file, tempFile);
        FileInputStream fis = new FileInputStream(tempFile);
        att.streamNewVersion(ar, ar.ngp, fis);
        tempFile.delete();

        return fileExtension;
    }

    public static void saveToFileAH(MultipartFile file, File destinationFile)
            throws Exception {
        if (destinationFile == null) {
            throw new IllegalArgumentException(
                    "Can not save file.  Destination file must not be null.");
        }

        if (destinationFile.exists()) {
            throw new NGException("nugen.exception.file.already.exist",new Object[]{destinationFile});
        }
        File folder = destinationFile.getParentFile();
        if (!folder.exists()) {
            throw new NGException("nugen.exception.folder.not.exist" ,new Object[]{destinationFile});
        }

        try {
            FileOutputStream fileOut = new FileOutputStream(destinationFile);
            fileOut.write(file.getBytes());
            fileOut.close();
        } catch (Exception e) {
            throw new NGException("nugen.exception.failed.to.save.file", new Object[]{destinationFile}, e);
        }
    }

    private static String assureExtension(String dName, String fName) {
        if (dName == null || dName.length() == 0) {
            return fName;
        }
        int dotPos = fName.lastIndexOf(".");
        if (dotPos<0)
        {
            return dName;
        }
        String fileExtension = fName.substring(dotPos);
        if (!dName.endsWith(fileExtension))
        {
            dName = dName + fileExtension;
        }
        return dName;
    }

    public static void setDisplayName(NGWorkspace ngw, AttachmentRecord attachment,
            String proposedName) throws Exception {
        String currentName = attachment.getDisplayName();
        if (currentName.equals(proposedName)) {
            return; // nothing to do
        }
        if (attachment.equivalentName(proposedName)) {
            attachment.setDisplayName(proposedName);
            return;
        }
        String trialName = proposedName;

        String proposedRoot = proposedName;
        String proposedExt = "";
        int dotPos = proposedRoot.lastIndexOf(".");
        if (dotPos>0) {
            proposedExt = proposedRoot.substring(dotPos);
            proposedRoot = proposedRoot.substring(0, dotPos);
        }
        //now strip off any concluding hyphen number if present
        //but only if it is a hyphen followed by a single digit
        //if we get into double digit redundant names ... I don't care
        //about letting more hyphens appear
        if (proposedRoot.charAt(proposedRoot.length()-2) == '-') {
            char lastChar = proposedRoot.charAt(proposedRoot.length()-1);
            if (lastChar>='0' && lastChar <= '9') {
                proposedRoot = proposedRoot.substring(0, proposedRoot.length()-2);
            }
        }

        //NOTE: currently deleted documents are still present in the
        //project folder.  They probably should not be there.
        //TODO: remove deleted documents from project folder
        //so they do not cause a name clash that can not be seen.

        AttachmentRecord att = ngw.findAttachmentByName(trialName);
        int iteration = 0;
        while (att != null) {

            if (att.getType().equals("EXTRA")) {
                //This may be an attempt by the user to "reclaim" an attachment that had
                //been renamed, and discovered as a EXTRA file.   If this is the
                //case, then remove the EXTRA record.
                ngw.eraseAttachmentRecord(att.getId());
                att = null;
            }
            else {
                trialName = proposedRoot + "-"
                        + Integer.toString(++iteration)
                        + proposedExt;

                if (currentName.equals(trialName)) {
                    return; // nothing to do
                }
                if (attachment.equivalentName(trialName)) {
                    attachment.setDisplayName(trialName);
                    return;
                }
                att = ngw.findAttachmentByName(trialName);
            }
        }
        // if we get here, then there exists no other attachment with the trial
        // name
        attachment.setDisplayName(trialName);
    }


}
