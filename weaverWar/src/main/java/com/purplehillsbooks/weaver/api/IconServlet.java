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
 */

package com.purplehillsbooks.weaver.api;

import java.io.File;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.ConfigFile;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;

import com.purplehillsbooks.streams.StreamHelper;

/**
 * This servlet services up an image for use as an icon
 * Any address of the type /icon/xxxxxxxx.jsp  will return an image
 * The xxxxxxxx is either a user key or an email address
 */
@SuppressWarnings("serial")
public class IconServlet extends javax.servlet.http.HttpServlet {
    private static ConfigFile theConfig;
    private static File userFolder;
    private static File applicationUsersFolder;

    public static void init(ConfigFile config) throws Exception {
        theConfig = config;
        userFolder = theConfig.getUserFolderOrFail();
        applicationUsersFolder = theConfig.getFileFromRoot("users");
    }


    public static void copyFileIfNeeded(File sourceFolder, File dest) throws Exception {
        if (!dest.exists()) {
            File source = new File(sourceFolder, dest.getName());
            if (source.exists()) {
                StreamHelper.copyFileToFile(source, dest);
            }
        }
    }
    public static void copyFileIfExists(File source, File dest) throws Exception {
        if (source.exists()) {
            StreamHelper.copyFileToFile(source, dest);
        }
    }
    public static void moveFileIfExists(File source, File dest) throws Exception {
        if (source.exists()) {
            StreamHelper.copyFileToFile(source, dest);
            source.delete();
        }
    }
    
    private File findMatchingImage(String fileName) throws Exception {
        if (!fileName.endsWith(".jpg")) {
            //only allow requests that end in jpg to make this safer
            throw new Exception("Icon file must be a '.jpg' file, not "+fileName);
        }
        String firstChar = fileName.substring(0,1).toLowerCase();
        
        //if it looks like an email address, then try to look up the user
        UserProfile user = null;
        int atPos = fileName.indexOf("@");
        if (atPos>0 && fileName.length()>6) {
            //strip the .jpg off
            String userEmail = fileName.substring(0,fileName.length()-4);
            user = UserManager.getStaticUserManager().lookupUserByAnyId(userEmail);
            if (user!=null) {
                fileName = user.getImage();
                //use first character of the name instead of email address
                firstChar = user.getName().substring(0,1).toLowerCase();
            }
        }
        
        File imgFile = new File(userFolder, fileName);
        if (imgFile.exists()) {
            return imgFile;
        }
        
        //new scheme is to put all the icon files in lower case but a link
        //might have it upper case.  Only try for upper case once, and 
        //only in the user folder.
        imgFile = new File(userFolder, fileName.toLowerCase());
        if (imgFile.exists()) {
            return imgFile;
        }
        
        //no file exists for the user, to send down a generic based on first letter
        imgFile = new File(applicationUsersFolder, "fake-"+firstChar+".jpg");
        if (imgFile.exists()) {
            return imgFile;
        }
        
        //if there is a strange initial letter for any reason, use the generic generic
        //this should ALWAYS exist
        imgFile = new File(applicationUsersFolder, "fake-~.jpg");
        return imgFile;
    }


    @Override
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        String path = req.getRequestURI();
        try {
            
            int pos = path.indexOf("/icon/");
            if (pos<0) {
                //if this happens the servlet is mapped to the wrong path
                throw new Exception("path does not have 'icon'");
            }
            
            File imgFile = findMatchingImage(path.substring(pos+6));

            StreamHelper.copyFileToOutput(imgFile, resp.getOutputStream());
        }
        catch (Exception e) {
            System.out.println("ERROR serving up the icon file: "+path);
            e.printStackTrace();
        }
    }

}
