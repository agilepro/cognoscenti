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

package com.purplehillsbooks.weaver.util;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import com.purplehillsbooks.weaver.exception.WeaverException;

public class UploadFile {

    public UploadFile(FileUploadSpec parent, String dataHeader, byte[] buffer,
            int startData, int endData) {
        m_parent = parent;
        m_startData = startData;
        m_endData = endData;

        m_size = 0;
        new String();
        m_filename = new String();
        m_fileExt = new String();
        new String();
        m_contentType = new String();
        m_contentDisp = new String();
        m_typeMime = new String();
        m_subTypeMime = new String();
        m_isMissing = true;
    }

    /**
     * This simply write the contents of the file to the path and file name that
     * you specify. Please be sure that the containing folder exists. Be sure
     * that the file does not already exist.
     */
    public void saveToFile(File destinationFile) throws Exception {
        if (destinationFile == null) {
            throw new IllegalArgumentException(
                    "Can not save file.  Destination file must not be null.");
        }

        if (destinationFile.exists()) {
            throw WeaverException.newBasic(
                "The specified file already exists: %s",
                destinationFile);
        }
        File folder = destinationFile.getParentFile();
        if (!folder.exists()) {
            throw WeaverException.newBasic(
                "The destination parent folder for the file does not exist: %s",
                folder.getAbsolutePath());
        }

        try {
            FileOutputStream fileOut = new FileOutputStream(destinationFile);
            fileOut.write(m_parent.m_binArray, m_startData, m_size);
            fileOut.close();
        } catch (Exception e) {
            throw WeaverException.newWrap(
                "Failure while saving the file to: %s",
                e, destinationFile);
        }
    }

    public boolean isMissing() {
        return m_isMissing;
    }

    public String getOriginalName() {
        return m_filename;
    }

    public String getDestinationName() {
        return m_filename;
    }

    public String getFileExt() {
        return m_fileExt;
    }

    public String getContentType() {
        return m_contentType;
    }

    public String getContentDisp() {
        return m_contentDisp;
    }

    public String getTypeMIME() throws IOException {
        return m_typeMime;
    }

    public String getSubTypeMIME() {
        return m_subTypeMime;
    }

    public int getSize() {
        return m_size;
    }

    protected int getStartData() {
        return m_startData;
    }

    protected int getEndData() {
        return m_endData;
    }

    protected void setParent(FileUploadSpec parent) {
        m_parent = parent;
    }

    protected void setStartData(int startData) {
        m_startData = startData;
    }

    protected void setEndData(int endData) {
        m_endData = endData;
    }

    protected void setSize(int size) {
        m_size = size;
    }

    protected void setIsMissing(boolean isMissing) {
        m_isMissing = isMissing;
    }

    protected void setFieldName(String fieldName) {
    }

    protected void setOriginalName(String fileName) {
        m_filename = fileName;
    }

    public void setDestinationName(String fileName) {
        m_filename = fileName;
    }

    protected void setFilePathName(String filePathName) {
    }

    protected void setFileExt(String fileExt) {
        m_fileExt = fileExt;
    }

    protected void setContentType(String contentType) {
        m_contentType = contentType;
    }

    protected void setContentDisp(String contentDisp) {
        m_contentDisp = contentDisp;
    }

    protected void setTypeMIME(String TypeMime) {
        m_typeMime = TypeMime;
    }

    protected void setSubTypeMIME(String subTypeMime) {
        m_subTypeMime = subTypeMime;
    }

    public byte getBinaryData(int index) {
        if (m_startData + index > m_endData) {
            throw new ArrayIndexOutOfBoundsException("Index " + index
                    + " is out of range.");
        }
        if (m_startData + index <= m_endData) {
            return m_parent.m_binArray[m_startData + index];
        } else {
            return 0;
        }
    }

    /**
     *
     *             This method attempts to enforce a number of undocumented
     *             rules about where files can be placed, and what is allowed.
     *             It converts the file name/path in some cases. The save as
     *             option is not documented. The class that represents the
     *             binary file is not the appropriate place to enforce where it
     *             can and can not be saved. That is better done in the
     *             application that has logic for that. The saveToFile method
     *             simply believes that the file path given to it is the right
     *             one, and writes out the data there.
     * 
     * This needs to be rewritten to use the Java File class as parameter
     * and for all manipulations.
     */
    public void saveAsXXXXX(String destFilePathName, int optionSaveAs)
            throws Exception, IOException {
        String path = new String();
        path = m_parent.getPhysicalPath(destFilePathName, optionSaveAs);
        if (path == null) {
            throw WeaverException.newBasic(
                "The corresponding physical path does not exist: %s",
                destFilePathName);
        }

        File file = new File(path);
        try {
            FileOutputStream fileOut = new FileOutputStream(file);
            fileOut.write(m_parent.m_binArray, m_startData, m_size);
            fileOut.close();
        } catch (IOException e) {
            throw WeaverException.newWrap(
                "Failure while saving the file to: %s",
                e, file.getAbsolutePath());
        }
    }

    private FileUploadSpec m_parent; // the FileUploadSpec class that parsed this out
    private int m_startData; // beginning of the block of data for the file
    private int m_endData; // end of the block of data for the file

    private int m_size;
    private String m_filename;
    private String m_fileExt;
    private String m_contentType;
    private String m_contentDisp;
    private String m_typeMime;
    private String m_subTypeMime;
    private boolean m_isMissing;
    public static final int SAVEAS_AUTO = 0;
    public static final int SAVEAS_VIRTUAL = 1;
    public static final int SAVEAS_PHYSICAL = 2;

}