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
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.WeaverException;

import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.streams.StreamHelper;

public class ErrorLog extends DOMFile {

    public ErrorLog(File path, Document newDoc) throws Exception {
        super(path, newDoc);
    }

    private static  ErrorLog cachedLogFile=null;

    public static ErrorLog getLogForDate(long dateValue, Cognoscenti cog) throws Exception {

        // create a log file name based on the date passed in.
        String encodedDate = new SimpleDateFormat("yyyy.MM.dd").format(dateValue);
        String fileName = "errorLog_"+ encodedDate.substring(0,10)+".xml";
        File logFolder = new File(cog.getConfig().getUserFolderOrFail(), "logs");
        File newPlace = new File(logFolder, fileName);
        
        //maybe this one is already cached and in use ... if so use that.
        if (cachedLogFile!=null && newPlace.equals(cachedLogFile.getFilePath())) {
            return cachedLogFile;
        }
        
        
        //error log files were placed directly in the main users folder for a while
        //now moved to the users logs folder, but look if it is there and move it if found there
        File oldPlace = new File(cog.getConfig().getUserFolderOrFail(), fileName);
        if (!newPlace.exists() && oldPlace.exists()) {
            StreamHelper.copyFileToFile(oldPlace, newPlace);
            oldPlace.delete();
        }


        //not cached, so load or create a new one
        Document errorLogDoc = readOrCreateFile(newPlace, "errorlog");
        cachedLogFile=new ErrorLog(newPlace, errorLogDoc);
        return cachedLogFile;
    }

    /**
     * Returns the error details for the specified error id.
     * @param errorId that you are looking for details on
     * @return the error details, or null if no error with that id
     */
    public ErrorLogDetails getDetails(int errorId) throws Exception {
        for (ErrorLogDetails errorLogDetails : getChildren("error", ErrorLogDetails.class)) {
            if(errorLogDetails.getErrorNo() == errorId){
                return errorLogDetails;
            }
        }
        return null;
    }

    public List<ErrorLogDetails> getAllDetails() throws Exception {
        List<ErrorLogDetails> list = new ArrayList<ErrorLogDetails>();
        for (ErrorLogDetails errorLogDetails : getChildren("error", ErrorLogDetails.class)) {
            list.add(errorLogDetails);
        }
        return list;
    }


    public ErrorLogDetails createNewError(Cognoscenti cog) throws Exception {
        ErrorLogDetails errorLogDetails = createChild("error", ErrorLogDetails.class);
        //fine the next error number and initialize it to that
        SuperAdminLogFile salf = SuperAdminLogFile.getInstance(cog);
        int exceptionNO = salf.incrementExceptionNo();
        errorLogDetails.setErrorNo(exceptionNO);
        //just in case it is not set elsewhere, give it a valid timestamp
        errorLogDetails.setModTime(System.currentTimeMillis());
        return errorLogDetails;
    }

    private int logsError(UserProfile up,String msg,Throwable ex, String errorURL,
            long nowTime, Cognoscenti cog) throws Exception {
        if (ex==null) {
            System.out.println("ERROR LOG: attempt to record null exception object");
            return -1;
        }
        String userName="GUEST";

        if (up!=null) {
            userName = up.getName()+"("+up.getKey()+")";
        }
        StackTraceElement[] element =ex.getStackTrace()  ;

        ErrorLogDetails errorLogDetails = createNewError(cog);

        errorLogDetails.setModified(userName, nowTime);

        errorLogDetails.setFileName(element[0].getFileName());
        errorLogDetails.setURI(errorURL);

        if (msg!=null && msg.length()>0) {
            errorLogDetails.setErrorMessage(msg+"\n"+WeaverException.getFullMessage(ex));
        } else {
            errorLogDetails.setErrorMessage(WeaverException.getFullMessage(ex));
        }
        errorLogDetails.setErrorDetails(convertStackTraceToString(ex));

        save();
        return errorLogDetails.getErrorNo();
    }


    public static File getErrorFileFullPath(Date date, Cognoscenti cog) throws Exception {
        String searchByDate=new SimpleDateFormat("yyyy.MM.dd").format(date);
        File userFolder = cog.getConfig().getUserFolderOrFail();
        return new File(userFolder, "errorLog_"+searchByDate+".xml");
    }




    public void logUserComments(int errorId, long logFileDate, String comments) throws Exception {

        ErrorLogDetails eDetails = getDetails(errorId);
        eDetails.setUserComment(comments);
        save();
    }

    private static String convertStackTraceToString(Throwable exception) throws Exception {
        return JSONException.convertToJSON(new Exception(exception), "ErrorLog").toString(2);
    }


    public synchronized long logException(String msg, Throwable ex, long nowTime,
            UserProfile userProfile, String errorURL, Cognoscenti cog) {
        try {

            //redundantly included in the system out as well
            //maybe someday this will not be necessary???
            System.out.println("\nLOGGED EXCEPTION: t="+Thread.currentThread().threadId()
                     +", start="+ SectionUtil.getNiceTimestamp(nowTime) + ", now=" + SectionUtil.getNiceTimestamp(System.currentTimeMillis()));
            if (msg==null || msg.length()==0) {
                msg = "LOGGED EXCEPTION: t="+Thread.currentThread().threadId()
                        +", start="+ SectionUtil.getNiceTimestamp(nowTime) + ", now=" + SectionUtil.getNiceTimestamp(System.currentTimeMillis());
            }
            if (WeaverException.containsMessage(ex, "Must be logged in")) {
                //suppress the logging of the entire stack trace just for not logged in.
                System.out.println(msg);
                System.out.println(WeaverException.getFullMessage(ex));
            }
            else {
                WeaverException.traceException(System.out, ex, msg);
            }

            return logsError(userProfile, msg, ex, errorURL, nowTime, cog);
        }
        catch (Exception e) {
            System.out.println("FATAL FAILURE TO LOG ERROR: "+e);
            // what else to do? ... crash the server. If your log file
            // is not working there is very little else to be done.
            // Might as well try throwing the exception...
            throw new RuntimeException("Can not write other exception to log file", e);
        }
    }


}

