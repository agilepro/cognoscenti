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

package org.socialbiz.cog.rest;

import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.License;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.TopicRecord;
import org.socialbiz.cog.UtilityMethods;
import org.w3c.dom.Document;

public class CaseExchange {
    AuthRequest ar;
    NGWorkspace ngp;
    License license;
    boolean isAdmin = false;
    boolean isMember = false;

    public static void sendCaseFormat(AuthRequest _ar, NGWorkspace _ngp) throws Exception {

        CaseExchange pe = new CaseExchange(_ar, _ngp);
        pe.generateResponse();

    }

    private CaseExchange(AuthRequest _ar, NGWorkspace _ngp) {
        ar = _ar;
        ngp = _ngp;
    }

    private void generateResponse() throws Exception {

        String lic = ar.reqParam("lic");
        license = ngp.getLicense(lic);
        if (license == null) {
            throw new Exception("Can not access this page, license id is no longer valid: " + lic);
        }
        String lRole = license.getRole();
        if (lRole.equals(ngp.getPrimaryRole().getName())) {
            isMember = true;
        }
        if (lRole.equals(ngp.getSecondaryRole().getName())) {
            isMember = true;
            isAdmin = true;
        }

        Document mainDoc = DOMUtils.createDocument("case");
        DOMFace rootEle = new DOMFace(mainDoc, mainDoc.getDocumentElement(), null);

        generateDocs(rootEle);
        generateNotes(rootEle);
        generateGoals(rootEle);

        DOMUtils.writeDom(mainDoc, ar.w);
    }

    private void generateDocs(DOMFace rootEle) throws Exception {
        DOMFace allDocs = rootEle.createChild("documents", DOMFace.class);
        for (AttachmentRecord att : ngp.getAllAttachments()) {

            // first check if this license has access
            if (att.isPublic()) {
                // public document, so everyone can get it
            }
            else if (isMember) {
                // members can access everything
            }
            else if (att.roleCanAccess(license.getRole())) {
                // license role has access
            }
            else {
                // no access, so skip to next attachment
                continue;
            }

            DOMFace oneDoc = allDocs.createChild("doc", DOMFace.class);
            oneDoc.setAttribute("id", att.getId());
            oneDoc.setScalar("universalid", att.getUniversalId());
            oneDoc.setScalar("name", att.getNiceName());
            oneDoc.setScalar("size", Long.toString(att.getFileSize(ngp)));
            setScalarTime(oneDoc, "modifiedtime", att.getModifiedDate());
            oneDoc.setScalar("modifieduser", att.getModifiedBy());
        }
    }

    private void generateNotes(DOMFace rootEle) throws Exception {
        DOMFace allNotes = rootEle.createChild("notes", DOMFace.class);
        for (TopicRecord lr : ngp.getAllNotes()) {

            if (lr.getVisibility() == 1) {
                // public note, so everyone can get it
            }
            else if (isMember) {
                // members can access everything
            }
            else {
                // no access, so skip to next attachment
                continue;
            }

            DOMFace oneNote = allNotes.createChild("note", DOMFace.class);
            oneNote.setAttribute("id", lr.getId());
            oneNote.setScalar("universalid", lr.getUniversalId());
            oneNote.setScalar("subject", lr.getSubject());
            setScalarTime(oneNote, "modifiedtime", lr.getLastEdited());
            oneNote.setScalar("modifieduser", lr.getModUser().getUniversalId());
        }

    }

    private void generateGoals(DOMFace rootEle) throws Exception {
        @SuppressWarnings("unused")
        DOMFace allGoals = rootEle.createChild("goals", DOMFace.class);

    }

    private void setScalarTime(DOMFace oneDoc, String attName, long dateTime) {
        oneDoc.setScalar(attName, UtilityMethods.getXMLDateFormat(dateTime));
    }
}
