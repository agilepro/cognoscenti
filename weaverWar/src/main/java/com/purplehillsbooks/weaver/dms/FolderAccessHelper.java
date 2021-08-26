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
 * limitations under the License.package com.purplehillsbooks.weaver.dms;
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package com.purplehillsbooks.weaver.dms;

import java.io.InputStream;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;

public class FolderAccessHelper {

    AuthRequest ar;

    @Deprecated
    public FolderAccessHelper(AuthRequest ar)throws Exception
    {
        if(ar == null)
        {
            throw new ProgramLogicError("FolderAccessHelper requires that AuthRequest parameter not be null");
        }
        this.ar = ar;
    }




    public void attachDocument(ResourceEntity remoteFile,
            NGWorkspace ngp,        String description,   String dName,
            String visibility, String readonly) throws Exception{

        if (!remoteFile.isFilled()) {
            //make sure we have the modified date
            remoteFile.fillInDetails(false);
        }

        AttachmentRecord attachment = ngp.createAttachment();
        attachment.setDisplayName(dName);
        attachment.setDescription(description);
        attachment.setModifiedBy(ar.getBestUserId());
        attachment.setModifiedDate(ar.nowTime);
        attachment.setAttachTime(ar.nowTime);
        attachment.setType("FILE");

        RemoteLinkCombo rlc = new RemoteLinkCombo(ar.getUserProfile().getKey(), remoteFile);
        attachment.setRemoteCombo(rlc);
        attachment.setRemoteFullPath(remoteFile.getFullPath());
        attachment.setReadOnlyType(readonly);

        attachment.setFormerRemoteTime(remoteFile.getLastModifed());

        //the following should be inside the ResourceEntity ... soon
        ConnectionType cType = remoteFile.getConnection();
        InputStream is = cType.openInputStream(remoteFile);
        attachment.streamNewVersion(ar, ar.ngp, is);
        is.close();
    }



    /**
    * @deprecated, not needed any more, use RemoteLinkCombo instead
    *
    public String getOwner(String rLink) throws Exception{
        RemoteLinkCombo rlc = RemoteLinkCombo.parseLink(rLink);
        return rlc.userKey;
    }
    /**
    * @deprecated, not needed any more, use RemoteLinkCombo instead
    *
    public String getRPath(String rLink) throws Exception{
        RemoteLinkCombo rlc = RemoteLinkCombo.parseLink(rLink);
        return rlc.rpath;
    }
    */

}
