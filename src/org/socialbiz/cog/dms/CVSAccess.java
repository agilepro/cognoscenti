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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.UtilityMethods;


public class CVSAccess extends ConnectionTypeBase {

    private String loggedInUserName = null;

    public CVSAccess(ConnectionSettings folder, String loggedInUserName){
        super(folder);
        this.loggedInUserName = loggedInUserName;
    }

    public boolean createFolder(String path) throws Exception {
        // TODO Auto-generated method stub
        updateSandBox(path);
        File tmpFile = new File(path);

        if(tmpFile.exists()){
            return true;
        }
        tmpFile.mkdir();

        String cmdString = getCVSRoot() + " add " +  addQuote(tmpFile.getName());
        runCommand(cmdString, null, tmpFile.getParentFile());
        return true;

    }

    public void createNewFile(String parentPath, String fileName, File srcFile)
            throws Exception {
        createNewFileInt(parentPath, fileName, srcFile,false);

    }

    public void createNewFileInt(String parentPath, String fileName, File srcFile, boolean isOverwrite)
        throws Exception {

        updateSandBox(parentPath);
        InputStream is = null;
        OutputStream out = null;
        File destFile = new File(parentPath, fileName);
        try {
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


        String cmdString1 = getCVSRoot() + " add " + addQuote(fileName);
        String cmdString2 = getCVSRoot() + " "
                + "commit -m \"Initial Revision by Cognoscenti User " + loggedInUserName
                + " \" " + addQuote(fileName);
        runCommand(cmdString1, null, destFile.getParentFile());
        runCommand(cmdString2, null, destFile.getParentFile());

    }

    public boolean deleteEntity(String path) throws Exception {
        File f = new File(path);

        String fn = f.getName();
        File parent  = f.getParentFile();
        f.delete();


        //CVS delete;

        String cmdString1 = getCVSRoot() + " delete " + addQuote(fn);
        String cmdString2 = getCVSRoot() + " "
        + "commit -m \"File deleted by Cognoscenti User " + loggedInUserName
        + " \" " + addQuote(fn);

         runCommand(cmdString1, null, parent);
         runCommand(cmdString2, null, parent);

        return true;
    }

    public void lookUpDetails(ResourceEntity entity, boolean expand) throws Exception
    {
        String fullPath = entity.getFullPath();

        updateSandBox(fullPath);
        File f = new File(fullPath);
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
                for (File cf : subDirs) {
                    String childName = cf.getName();
                    if(childName.equalsIgnoreCase("CVS")) {
                        continue;
                    }

                    ResourceEntity cent = entity.getChild(childName);
                    if (cf.isDirectory()) {
                        cent.setType(ConnectionType.TYPE_FOLDER);
                        cent.setFileCount(getFileCount(cf.listFiles()));
                    } else {
                        cent.setType(ConnectionType.TYPE_FILE);
                        cent.setSize(cf.length());
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
        updateSandBox(path);
        File f = new File(path);
        return new FileInputStream(f);
    }

    public void uploadFile(String path, File srcFile) throws Exception {
        updateSandBox(path);
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

        File desFile = new File(path);
        String cmdString = getCVSRoot() + " "
        + "commit -m \"Revised by Cognoscenti User " + loggedInUserName
            + "\" " + addQuote(desFile.getName());

        runCommand(cmdString, null, desFile.getParentFile());
    }

    private String getCVSRoot() throws Exception{
        return getCVSRoot(folder.getExtendedAttribute(CVSConfig.ATT_CVS_ROOT) , folder.getFolderUserId(), folder.getFolderPassword());

    }

    private String getCVSRoot(String path, String uid, String pwd) throws Exception{
        if (path == null || path.length() == 0) {
            throw new NGException("nugen.exception.path.invalid", new Object[]{path});
        }

        String otext = ":uid:pwd@";
        String ntext = ":" + uid + ":" + pwd + "@";
        String root = "cvs -d " + path.replaceFirst(otext, ntext);
        return root;
    }


    /*
    private String formatPath(String path){
        path = path.replace("\\", "/");
        if (!path.endsWith("/")) {
            path = path + "/";
        }
        return path;
    }
    */

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

    private  String runCommand(String cmdString,String[] envp,
        File dir)throws Exception{

        Runtime runTime = Runtime.getRuntime();
        Process process = runTime.exec(cmdString,envp,dir);
        int exitCode = process.waitFor();
        String outMsg = getMessage(process.getInputStream());
        String errMsg = getMessage(process.getErrorStream());

        if(exitCode != 0){
            throw new NGException("nugen.exception.cvs.error", new Object[]{cmdString,exitCode,outMsg,errMsg});
        }

        return outMsg;
    }

    private String getMessage(InputStream is) throws Exception{
        if (is == null) {
            return "";
        }

        BufferedReader br = null;
        try{
            br = new BufferedReader(new InputStreamReader(is));
            StringBuffer sb = new StringBuffer();
            String str = "";
            while( (str = br.readLine())!= null){
                sb.append(str);
            }
            return sb.toString();
        }finally{
             br.close();
        }

    }

    private void updateSandBox(String path)throws Exception{
        File f = new File(path);
        if(f.isDirectory()){
            String  cmdString = getCVSRoot() + " update -l";
            this.runCommand(cmdString, null, f);
        }else{
            String  cmdString = getCVSRoot() + " update " + f.getName();
            this.runCommand(cmdString, null, f.getParentFile());

        }
    }

    private String addQuote(String val){
        return UtilityMethods.quote4JS(val);
    }

    public boolean checkAvailability(String parentPath, String fileName)
            throws Exception {
        File destFile = new File(parentPath, fileName);
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
