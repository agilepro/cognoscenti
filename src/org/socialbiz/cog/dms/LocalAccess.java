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
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;

public class LocalAccess extends ConnectionTypeBase{

    public LocalAccess(ConnectionSettings folder){
        super(folder);
    }

    public boolean createFolder(String path) throws Exception {
        path = formatPath(path);
        checkAccess(path);
        File tmpFile = new File(path);
        return tmpFile.mkdir();
    }

    public void createNewFile(String parentPath, String fileName, File srcFile)
    throws Exception {

        createNewFileInt(parentPath, fileName, srcFile,false);
    }
    public void createNewFileInt(String parentPath, String fileName, File srcFile, boolean isOverwrite)
            throws Exception {
        InputStream is = null;
        OutputStream out = null;
        try {
            String filePath = extendPath(parentPath, fileName);
            File destFile = new File(filePath);
            if (!isOverwrite) {
                if (destFile.exists()) {
                    throw new NGException("nugen.exception.file.already.exists", new Object[]{fileName});
                }
            }

            is = new FileInputStream(srcFile);
            out = new FileOutputStream(destFile);
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

    public boolean deleteEntity(String path) throws Exception {
        File f = new File(path);
        boolean deleteSuccess = f.delete();
        if(!deleteSuccess){
            throw new NGException("nugen.exception.unable.to.delete.resource", null);
        }
        return true;
    }

    public byte[] getFileContent(String path) throws Exception {
        throw new ProgramLogicError("Method getFileContent not implemented.");
    }

    public void lookUpDetails(ResourceEntity entity, boolean expand) throws Exception
    {
        String fullPath = entity.getFullPath();
        File f = new File(fullPath);

        //here we simply check that we extracted the file name the same way that Java File object does.
        if (!entity.getName().equals(f.getName())) {
            throw new ProgramLogicError("somethind is wrong with LocalAccess, calculated file name ("
                +entity.getName()+") but file itself says it is ("+f.getName()+")");
        }

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
            File[] subDirs = f.listFiles();
            if (subDirs != null) {
                for (int i = 0; i < subDirs.length; i++) {
                    File cf = subDirs[i];
                    ResourceEntity cent = entity.getChild(cf.getName());
                    if (cf.isDirectory()) {
                        cent.setType(ConnectionType.TYPE_FOLDER);
                        int cfcnt = getFileCount(cf.listFiles());
                        cent.setFileCount(cfcnt);
                    } else {
                        cent.setType(ConnectionType.TYPE_FILE);
                        cent.setSize(cf.length());
                    }

                    cent.setDisplayName(entity.getDisplayName() + "/"
                            + cf.getName());
                    cent.setLastModifed(cf.lastModified());
                    entity.addChildEntity(cent);
                }
            }
        }
    }

    public InputStream openInputStream(ResourceEntity ent) throws Exception {
        File f = new File(ent.getFullPath());
        return new FileInputStream(f);
    }

    public void uploadFile(String path, File srcFile) throws Exception {
        InputStream is = new FileInputStream(srcFile);
        OutputStream out = new FileOutputStream(path);
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

    private void checkAccess(String path)throws Exception {
        List<LocalFolderConfig> lclConnections = FolderAccessHelper.getLoclConnections();
        if(lclConnections.isEmpty()){
            throw new NGException("nugen.exception.co.cofig.for.local.con",null);
        }

        for(int i=0; i<lclConnections.size(); i++){
            String dpath = lclConnections.get(i).getPath();
            if (path.startsWith(dpath)) {
                 return;
             }

        }

        throw new NGException("nugen.exception.invalid.local.path", new Object[]{path});

    }

    private int getFileCount(File[] files) throws Exception {
        int count = 0;
        if (files == null) {
            return 0;
        }
        for (int i = 0; i < files.length; i++) {
            File tfile = files[i];
            if (!tfile.isDirectory()) {
                count++;
            }
        }
        return count;
    }
    private String formatPath(String path){
        path = path.replace("\\", "/");
        if (!path.endsWith("/")) {
            path = path + "/";
        }
        return path;
    }

    public boolean checkAvailability(String parentPath, String fileName)
            throws Exception {
        String filePath = extendPath(parentPath, fileName);
        File destFile = new File(filePath);
        return destFile.exists();
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
