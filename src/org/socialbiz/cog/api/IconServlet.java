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

package org.socialbiz.cog.api;

import java.io.File;
import java.io.FileInputStream;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.ConfigFile;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;

import com.purplehillsbooks.streams.StreamHelper;

/**
 * This servlet services up an image for use as an icon
 */
@SuppressWarnings("serial")
public class IconServlet extends javax.servlet.http.HttpServlet {
    private static ConfigFile theConfig;
    private static File userFolder;
    private static File defaultFolder;

    public static void init(ConfigFile config) throws Exception {
        theConfig = config;
        userFolder = theConfig.getUserFolderOrFail();
        defaultFolder = theConfig.getFileFromRoot("users");
    }

    @Override
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        String path = req.getRequestURI();
        try {
            //resp.setContentType(arg0);
            int pos = path.indexOf("/icon/");
            if (pos<0) {
                throw new Exception("path does not have 'icon'");
            }
            String fileName = path.substring(pos+6);
            File imgFile = new File(userFolder, fileName);
            if (!imgFile.exists()) {
                //new scheme is to put all the icon files in lower case but a link
                //might have it differently
                imgFile = new File(userFolder, fileName.toLowerCase());
            }
            if (!imgFile.exists()) {
                imgFile = new File(defaultFolder, fileName);
            }
            if (!imgFile.exists()) {
                int atPos = fileName.indexOf("@");
                if (atPos<0 && fileName.length()>12) {
                    String userKey = fileName.substring(0,9).toUpperCase();
                    UserProfile user = UserManager.getUserProfileByKey(userKey);
                    if (user!=null) {
                        String userName = user.getName();
                        String firstChar = userName.substring(0,1).toLowerCase();
                        imgFile = new File(defaultFolder, "fake-"+firstChar+".jpg");
                    }
                }
            }
            if (!imgFile.exists()) {
                String firstChar = fileName.substring(0,1).toLowerCase();
                imgFile = new File(defaultFolder, "fake-"+firstChar+".jpg");
            }
            if (!imgFile.exists()) {
                imgFile = new File(defaultFolder, "fake-~.jpg");
            }
            StreamHelper.copyFileToOutput(imgFile, resp.getOutputStream());
        }
        catch (Exception e) {
            System.out.println("ERROR serving up the icon file: "+path);
            e.printStackTrace();
        }
    }

}
