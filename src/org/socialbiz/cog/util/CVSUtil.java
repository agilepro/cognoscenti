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

package org.socialbiz.cog.util;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;

public class CVSUtil
{

    public static final String ADD          = "add";          //Add a new file/directory to the repository
    public static final String ADMIN        = "admin";        //Administration front end for rcs
    public static final String ANNOTATE     = "annotate";     //Show last revision where each line was modified
    public static final String CHACL        = "chacl";        //Change the Access Control List for a directory
    public static final String CHECKOUT     = "checkout";     //Checkout sources for editing
    public static final String CHOWN        = "chown";        //Change the owner of a directory
    public static final String COMMIT       = "commit";       //Check files into the repository
    public static final String DIFF         = "diff";         //Show differences between revisions
    public static final String EDIT         = "edit";         //Get ready to edit a watched file
    public static final String EDITORS      = "editors";      //See who is editing a watched file
    public static final String EXPORT       = "export";       //Export sources from CVS, similar to checkout
    public static final String HISTORY      = "history";      //Show repository access history
    public static final String IMPORT       = "import";       //Import sources into CVS, using vendor branches
    public static final String INIT         = "init";         //Create a CVS repository if it doesn't exist
    public static final String INFOR        = "info";         //Display information about supported protocols
    public static final String LOG          = "log";          //Print out history information for files
    public static final String LOGIN        = "login";        //Prompt for password for authenticating server
    public static final String LOGOUT       = "logout";       //Removes entry in .cvspass for remote repository
    public static final String LS           = "ls";           //List files in the repository
    public static final String LSACL        = "lsacl";        //List the directories Access Control List
    public static final String PASSWORD     = "passwd";       //Set the user's password (Admin: Administer users)
    public static final String AUTHSERVER   = "authserver";   //Authentication server mode
    public static final String RANNOTATE    = "rannotate";    //Show last revision where each line of module was modified
    public static final String RDIFF        = "rdiff";        //Create 'patch' format diffs between releases
    public static final String RELEASE      = "release";      //Indicate that a Module is no longer in use
    public static final String REMOVE       = "remove";       //Remove an entry from the repository
    public static final String RLOG         = "rlog";         //Print out history information for a module
    public static final String RTAG         = "rtag";         //Add a symbolic tag to a module
    public static final String SERVERS      = "server";       //Server mode
    public static final String STATUS       = "status";       //Display status information on checked out files
    public static final String TAG          = "tag";          //Add a symbolic tag to checked out version of files
    public static final String UNEDIT       = "unedit";       //Undo an edit command
    public static final String UPDATE       = "update";       //Bring work tree in sync with repository
    public static final String VERSION      = "version";      //Show current CVS version(s)
    public static final String WATCH        = "watch";        //Set watches
    public static final String WATCHERS     = "watchers";     //See who is watching a file

    private static String cvsConnectStr = "";
    private static String SPACE = " ";
    private static String CVS_D = "cvs -d ";
    private static boolean cvsEnabled = false;
    private static String DBL_QUOTE = "\"";


    public CVSUtil(String m_cvsConnectStr, String m_password, boolean m_isCVSEnabled)
    {
        cvsConnectStr = m_cvsConnectStr;
        cvsEnabled = m_isCVSEnabled;
    }

    private static String getErrorMessage(Process process) throws Exception
    {
        if (process == null) {
            return "";
        }

        BufferedReader br = new BufferedReader(new InputStreamReader(process.getErrorStream()));
        StringBuffer sb = new StringBuffer();

        String str = br.readLine();
        while( str != null){
            str = br.readLine();
            sb.append(str);
        }
        return sb.toString();
    }

    private static boolean isProcessSuccess(Process process) throws Exception
    {
        if (process == null) {
            return false;
        }
        String str = getErrorMessage(process);
        return ((str.length() == 0)? true : false);
    }

    private static Process executeCommand(String command) throws Exception
    {
        if ((command == null) || command .length() == 0)
        {
            throw new ProgramLogicError("Attempt to execute a comand line command with a null command value.");
        }
        Runtime runTime = Runtime.getRuntime();
        // for windows - use cmd.exe. for Solaris this needs to be changed.
        Process process = runTime.exec("cmd.exe /c "+ command);
        return process;
    }

    public static Process add(File filePath, String userName, String comment) throws Exception
    {
        if (!cvsEnabled) {
            return null;  //silently do nothing if not enabled
        }
        if (filePath == null || !filePath.exists()) {
            throw new NGException("nugen.exception.file.missing.to.add",null);
        }
        if (userName == null) {
            userName = "";
        }
        if (comment == null) {
            comment = "";
        }

        String file = convertBStoFWS(filePath);
        // get the parent directory name from the file path.
        File parent = filePath.getParentFile();
        String dirName = parent.getPath().replace('\\', '/');

        // for adding a file into CVS one has to be in any of the CVS directory to execute the command.
        Process p1 = CVSUtil.executeCVSCommand("CD " + dirName + " && " + CVSUtil.ADD + CVSUtil.SPACE + DBL_QUOTE + file + DBL_QUOTE);
        Process p2 = null;
        if (CVSUtil.isProcessSuccess(p1)) {
            p2 = CVSUtil.commit(filePath, userName, (comment + " :: " +  "(" + userName + ")") );
        }
        return ((p2 == null)? p1 : p2);
    }

    public static Process commit(File filePath, String userName, String comment) throws Exception
    {
        if (!cvsEnabled) {
            return null;  //silently do nothing if not enabled
        }
        if (filePath == null || !filePath.exists()) {
            throw new NGException("nugen.exception.file.missing.to.commit",null);
        }

        if (userName == null) {
            userName = "";
        }
        if (comment == null) {
            comment = "";
        }

        return CVSUtil.executeCVSCommand(CVSUtil.COMMIT + CVSUtil.SPACE
                    + "-m" + CVSUtil.SPACE
                    + CVSUtil.quote4CMDLine(comment + " :: (" + userName + ")" )
                    + CVSUtil.SPACE + DBL_QUOTE + convertBStoFWS(filePath) + DBL_QUOTE );
    }

    public static Process update(File filePath) throws Exception
    {
        if (!cvsEnabled) {
            return null;  //silently do nothing if not enabled
        }
        if (filePath == null || !filePath.exists()) {
            throw new NGException("nugen.exception.file.missing.to.update",null);
        }

        return CVSUtil.executeCVSCommand(CVSUtil.UPDATE + CVSUtil.SPACE + DBL_QUOTE
                    + convertBStoFWS(filePath) + DBL_QUOTE);
    }

    public static Process checkOut(File filePath) throws Exception
    {
        if (!cvsEnabled) {
            return null;  //silently do nothing if not enabled
        }
        if (filePath == null || !filePath.exists()) {
            throw new NGException("nugen.exception.file.missing.to.add",null);
        }

        return CVSUtil.executeCVSCommand(CVSUtil.CHECKOUT + CVSUtil.SPACE + DBL_QUOTE
                     + convertBStoFWS(filePath) + DBL_QUOTE);
    }

    public static Process edit(File filePath) throws Exception
    {
        if (!cvsEnabled) {
            return null;  //silently do nothing if not enabled
        }
        if (filePath == null || !filePath.exists()) {
            throw new NGException("nugen.exception.file.missing.to.add",null);
        }

        return CVSUtil.executeCVSCommand(CVSUtil.EDIT + CVSUtil.SPACE + DBL_QUOTE
                     + convertBStoFWS(filePath) + DBL_QUOTE);
    }

    private static Process executeCVSCommand(String command) throws Exception
    {
        if (!cvsEnabled)
        {
            return null;  //silently do nothing if not enabled
        }
        if (command == null || command.length() == 0)
        {
            throw new ProgramLogicError("Null command.  Method executeCVSCommand needs to be passed a valid, non-null command value.");
        }
        Process process = CVSUtil.executeCommand(CVS_D + cvsConnectStr + SPACE + command);
        return process;
    }

    private static String convertBStoFWS(File filePath)
    {
        if (filePath == null) {
            return "";
        }
        return filePath.getPath().replace('\\', '/');
    }

    private static String quote4CMDLine(String str) {
        //passing a null in results a no output, no quotes, nothing
        if (str == null) {
            return "\"\"";
        }
        int len = str.length();
        int startPos = 0;
        String trans = null;

        StringBuffer res = new StringBuffer("\"");
        for (int i=0; i<len; i++) {
            char ch = str.charAt(i);
            switch ( ch) {
                case '\"':
                    trans = "\\\"";
                    break;
                default:
                    continue;
            }
            if (trans != null) {
                if (i > startPos) {
                    res.append(str.substring(startPos, i));
                }
                res.append(trans);
                startPos = i+1;
                trans = null;
            }
        }
        // now write out whatever is left
        if (len > startPos) {
            res.append(str.substring(startPos));
        }
        res.append("\"");
        return res.toString();
    }

}