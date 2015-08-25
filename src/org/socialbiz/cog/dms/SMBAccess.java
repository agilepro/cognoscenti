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
 * limitations under the License.package org.socialbiz.cog.dms;
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.dms;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import jcifs.UniAddress;
import jcifs.smb.NtlmPasswordAuthentication;
import jcifs.smb.SmbFile;
import jcifs.smb.SmbSession;

public class SMBAccess extends ConnectionTypeBase{

    public SMBAccess(ConnectionSettings folder){
        super(folder);
    }

    public boolean createFolder(String path)
            throws Exception {
        if (!path.endsWith("/")) {
            path = path + "/";
        }
        SmbFile f = getSmbFile(path, folder.getFolderUserId(), folder.getFolderPassword());
        f.mkdir();
        return true;
    }

    public boolean deleteEntity(String path)throws Exception{
        SmbFile f = getSmbFile(path, folder.getFolderUserId(), folder.getFolderPassword());
        f.delete();
        return true;
    }

    public void lookUpDetails(ResourceEntity entity, boolean expand) throws Exception
    {
        String fullPath = entity.getFullPath();

        SmbFile f = getSmbFile(fullPath, folder.getFolderUserId(), folder.getFolderPassword());
        if (f.isDirectory()){
            entity.setType(ConnectionType.TYPE_FOLDER);
            int fcnt = getFileCount(f.listFiles());
            entity.setFileCount(fcnt);
        }
        else {
            entity.setType(ConnectionType.TYPE_FILE);
            entity.setSize(f.length());
        }
        entity.setDisplayName(folder.getDisplayName() + entity.getPath());
        entity.setLastModifed(f.lastModified());
        if(expand && f.isDirectory()){
                SmbFile[] subDirs = f.listFiles();
                if (subDirs != null) {
                    for (int i = 0; i < subDirs.length; i++) {
                        SmbFile cf = subDirs[i];
                        ResourceEntity cent = entity.getChild(cf.getName());
                        if (cf.isDirectory()) {
                            cent.setType(ConnectionType.TYPE_FOLDER);
                            int cfcnt = getFileCount(cf.listFiles());
                            cent.setFileCount(cfcnt);
                        }else {
                            cent.setType(ConnectionType.TYPE_FILE);
                            cent.setSize(cf.getContentLength());
                        }

                        cent.setDisplayName(entity.getDisplayName() + "/" + cf.getName());
                        cent.setLastModifed(cf.lastModified());
                        entity.addChildEntity(cent);
                    }
                }


        }
    }

    public InputStream openInputStream(ResourceEntity ent) throws Exception {
        String path = ent.getFullPath();
        SmbFile f = getSmbFile(path, folder.getFolderUserId(), folder.getFolderPassword());
        return f.getInputStream();
    }

    public void uploadFile(String path, File srcFile)
            throws Exception {
        SmbFile tmpFile = getSmbFile(path, folder.getFolderUserId(), folder.getFolderPassword());
        InputStream is = new FileInputStream(srcFile);
        OutputStream out = tmpFile.getOutputStream();
        byte[] buf = new byte[2048];
        int amtRead = is.read(buf);
        while (amtRead > 0) {
            // these are bytes to write directly to the byte stream
            out.write(buf, 0, amtRead);
            amtRead = is.read(buf);
        }
        is.close();
        out.close();
    }


    private SmbFile getSmbFile(String path, String uid, String pwd)throws Exception {

        String ps = "smb://";
        if (!path.startsWith(ps)) {
            throw new NGException("nugen.exception.invalid.smb.path",null);
        }

        int indx = path.indexOf('/', ps.length());
        String address = path.substring(ps.length(), indx);

        UniAddress domain = UniAddress.getByName(address);
        NtlmPasswordAuthentication auth = new NtlmPasswordAuthentication(
                address, uid, pwd);
        SmbSession.logon(domain, auth);
        return new SmbFile(path, auth);
    }

    private int getFileCount(SmbFile[] files) throws Exception {
        int count = 0;
        if (files == null) {
            return 0;
        }
        for (int i = 0; i < files.length; i++) {
            SmbFile tfile = files[i];
            if (!tfile.isDirectory()) {
                count++;
            }
        }
        return count;
    }

    public void createNewFile(String parentPath,
            String fileName, File srcFile) throws Exception {

        createNewFileInt(parentPath, fileName, srcFile, false);
    }

    public void createNewFileInt(String parentPath,
            String fileName, File srcFile, boolean isOverwrite) throws Exception {

        InputStream is = null;
        OutputStream out = null;
        try {
            String filePath = parentPath;
            if (filePath.endsWith("/")) {
                filePath = parentPath + fileName;
            } else {
                filePath = parentPath + "/" + fileName;
            }

            SmbFile tmpFile = getSmbFile(filePath, folder.getFolderUserId(), folder.getFolderPassword());
            if (!isOverwrite) {
                if (tmpFile.exists()) {
                    throw new NGException("nugen.exception.file.already.exists", new Object[]{fileName});
                }
            }

            is = new FileInputStream(srcFile);
            out = tmpFile.getOutputStream();
            byte[] buf = new byte[2048];
            int amtRead = is.read(buf);
            while (amtRead > 0) {
                // these are bytes to write directly to the byte stream
                out.write(buf, 0, amtRead);
                amtRead = is.read(buf);
            }
        }finally{
            if(is != null) {
                is.close();
            }
            if(out != null) {
                out.close();
            }
        }

    }

    public boolean checkAvailability(String parentPath, String fileName)
            throws Exception {
        String filePath = parentPath;
        if (filePath.endsWith("/")) {
            filePath = parentPath + fileName;
        } else {
            filePath = parentPath + "/" + fileName;
        }

        SmbFile tmpFile = getSmbFile(filePath, folder.getFolderUserId(), folder.getFolderPassword());
            if (tmpFile.exists()) {
                return true;
            }else{
                return false;
            }

    }

    public void overwriteExistingDocument(String parentPath, String fileName,
            File srcFile) throws Exception {
        createNewFileInt(parentPath, fileName, srcFile, true);

    }

    public Exception getValidationError(String path) throws Exception
    {
        throw new ProgramLogicError("isValid is not implemented yet");
    }
    public String cleanPath(String path) throws Exception
    {
        throw new ProgramLogicError("cleanPath is not implemented yet");
    }

}
