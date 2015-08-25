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

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.jsp.PageContext;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;

/**
 *
 * File Upload
 * @publish internal
 */
public class Upload
{

    public Upload()
    {
        m_totalBytes = 0;
        m_currentIndex = 0;
        m_startData = 0;
        m_endData = 0;
        m_boundary = new String();
        m_totalMaxFileSize = 0L;
        m_maxFileSize = 0L;
        m_denyPhysicalPath = false;
        new String();
        m_files = new UploadFiles();
        m_formRequest = new UploadRequest();
    }


    public final void initialize(ServletConfig config, HttpServletRequest request, HttpServletResponse response)
        throws ServletException
    {
        m_application = config.getServletContext();
        m_request = request;
        m_response = response;
    }

    public final void initialize(PageContext pageContext)
        throws ServletException
    {
        m_application = pageContext.getServletContext();
        m_request = (HttpServletRequest)pageContext.getRequest();
        m_response = (HttpServletResponse)pageContext.getResponse();
    }


    //this routine can only be called once, so why not make it part of initialize?
    public UploadFiles parsePostedContent()
        throws Exception, IOException, ServletException
    {
        long totalFileSize = 0L;
        boolean found = false;
        boolean isFile = false;
        m_totalBytes = m_request.getContentLength();
        m_binArray = new byte[m_totalBytes];
        int totalRead = 0;
        int readBytes = 0;
        while(totalRead < m_totalBytes)
        {
            try
            {
                m_request.getInputStream();
                readBytes = m_request.getInputStream().read(m_binArray, totalRead, m_totalBytes - totalRead);
            }
            catch(Exception e)
            {
                throw new NGException("nugen.exception.unable.to.read.content" ,null, e);
            }
            totalRead += readBytes;
        }

        //now, the entire posted page content is in variable m_binArray

        //this code appears to be looking for the first CR, and that first
        //line will be the boundary pattern for the MIME encoding.
        while(!found && m_currentIndex < m_totalBytes)
        {
            if(m_binArray[m_currentIndex] == 13)
            {
                found = true;
                break;
            }
            //Note that this is not properly encoding characters for UTF-8
            //but Mime encoding might require ASCII at this point....
            m_boundary = m_boundary + (char)m_binArray[m_currentIndex];
            m_currentIndex++;
        }

        //I guess this is the case where the boundary was zero length, so give up.
        if(m_currentIndex == 1)
        {
            return m_files;   //empty at this point
        }

        //what if the current index is > m_totalBytes, shouldn't we quite now as well?

        //go one more... is this to skip the line feed?
        m_currentIndex++;
        while (m_currentIndex < m_totalBytes)
        {
            String dataHeader = getDataHeader();
            m_currentIndex = m_currentIndex + 2;

            //if the header mentions filename, then it is a file
            //but what if it is a different kind of section that mentiones 'filename'?
            //TODO: detection of a file should depend upon a better test
            isFile = dataHeader.indexOf("filename") > 0;
            String fieldName = getDataFieldValue(dataHeader, "name");

            //if the end of the section is not properly found, then this
            //will return zero.  Probably should exit if this happens.
            m_endData = getDataSection();

            if(isFile)
            {
                String filePathName = getDataFieldValue(dataHeader, "filename");
                String fileName     = getFileNameFromPath(filePathName);
                String fileExt      = getFileExt(fileName);
                String contentType  = getContentType(dataHeader);
                String contentDisp  = getContentDisp(dataHeader);
                String typeMIME     = getTypeMIME(contentType);
                String subTypeMIME  = getSubTypeMIME(contentType);
                if(fileName.length() > 0)
                {
                    long thisDataSize = (m_endData - m_startData) + 1;
                    if(m_maxFileSize > 0 && thisDataSize > m_maxFileSize)
                    {
                        throw new SecurityException("Size exceeded for this file : " + fileName + ". The max file size is " + m_maxFileSize);
                    }
                    totalFileSize += (m_endData - m_startData) + 1;
                    if(m_totalMaxFileSize > 0 && totalFileSize > m_totalMaxFileSize) {
                        throw new SecurityException("Total File Size exceeded. The max total size is " + m_totalMaxFileSize);
                    }
                }
                UploadFile newFile = new UploadFile(this, dataHeader, m_binArray, m_startData, m_endData);
                newFile.setFieldName(fieldName);
                newFile.setOriginalName(fileName);
                newFile.setFileExt(fileExt);
                newFile.setFilePathName(filePathName);
                newFile.setIsMissing(filePathName.length() == 0);
                newFile.setContentType(contentType);
                newFile.setContentDisp(contentDisp);
                newFile.setTypeMIME(typeMIME);
                newFile.setSubTypeMIME(subTypeMIME);
                if(contentType.indexOf("application/x-macbinary") > 0)
                {
                    m_startData = m_startData + 128;
                }
                newFile.setSize((m_endData - m_startData) + 1);
                newFile.setStartData(m_startData);
                newFile.setEndData(m_endData);
                m_files.addFile(newFile);
            }
            else
            {
                String value = new String(m_binArray, m_startData, (m_endData - m_startData) + 1, "UTF-8");
                m_formRequest.putParameter(fieldName, value);
            }
            if((char)m_binArray[m_currentIndex + 1] == '-')
            {
                break;
            }
            m_currentIndex = m_currentIndex + 2;
        }

        return m_files;
    }

    public int save(String destPathName)
        throws Exception, IOException, ServletException
    {
        return save(destPathName, 0);
    }

    @SuppressWarnings("deprecation")
    public int save(String destPathName, int option)
        throws Exception, IOException, ServletException
    {
        int count = 0;
        if(destPathName == null)
        {
            destPathName = m_application.getRealPath("/");
        }
        else
        {
            if (destPathName.indexOf("\\")>=0)
            {
                throw new NGException("nugen.exception.blackslash.in.path.not.allowed" , new Object[]{destPathName});
            }
        }
        if(destPathName.indexOf("/") != -1)
        {
            if(destPathName.charAt(destPathName.length() - 1) != '/')
            {
                destPathName = String.valueOf(destPathName).concat("/");
            }
        }
        for(int i = 0; i < m_files.getCount(); i++)
        {
            if(!m_files.getFile(i).isMissing())
            {
                m_files.getFile(i).saveAsXXXXX(destPathName + m_files.getFile(i).getOriginalName(), option);
                count++;
            }
        }

        return count;
    }

    public int getSize()
    {
        return m_totalBytes;
    }

    public byte getBinaryData(int index) throws Exception
    {
        byte retval;
        try
        {
            retval = m_binArray[index];
        }
        catch(Exception e)
        {
            throw new ProgramLogicError("Index " + index + " is out of range.");
        }
        return retval;
    }

    public UploadFiles getFiles()
    {
        return m_files;
    }

    public UploadRequest getRequest()
    {
        return m_formRequest;
    }



    private String getDataFieldValue(String dataHeader, String fieldName)
    {
        String token = new String();
        String value = new String();
        int pos = 0;
        int i = 0;
        int start = 0;
        int end = 0;
        token = String.valueOf((new StringBuffer(String.valueOf(fieldName))).append("=").append('"'));
        pos = dataHeader.indexOf(token);
        if(pos > 0)
        {
            i = pos + token.length();
            start = i;
            token = "\"";
            end = dataHeader.indexOf(token, i);
            if(start > 0 && end > 0) {
                value = dataHeader.substring(start, end);
            }
        }
        return value;
    }

    private String getFileExt(String fileName)
    {
        String value = new String();
        int start = 0;
        int end = 0;
        if(fileName == null) {
            return null;
        }
        start = fileName.lastIndexOf('.') + 1;
        end = fileName.length();
        value = fileName.substring(start, end);
        if(fileName.lastIndexOf('.') > 0) {
            return value;
        }
        else {
            return "";
        }
    }

    private String getContentType(String dataHeader)
    {
        String token = new String();
        String value = new String();
        int start = 0;
        int end = 0;
        token = "Content-Type:";
        start = dataHeader.indexOf(token) + token.length();
        if(start != -1)
        {
            end = dataHeader.length();
            value = dataHeader.substring(start, end);
        }
        return value;
    }

    private String getTypeMIME(String ContentType)
    {
        int pos = 0;
        pos = ContentType.indexOf("/");
        if(pos != -1) {
            return ContentType.substring(1, pos);
        }
        else {
            return ContentType;
        }
    }

    private String getSubTypeMIME(String ContentType)
    {
        int start = 0;
        int end = 0;
        start = ContentType.indexOf("/") + 1;
        if(start != -1)
        {
            end = ContentType.length();
            return ContentType.substring(start, end);
        } else
        {
            return ContentType;
        }
    }

    private String getContentDisp(String dataHeader)
    {
        String value = new String();
        int start = 0;
        int end = 0;
        start = dataHeader.indexOf(":") + 1;
        end = dataHeader.indexOf(";");
        value = dataHeader.substring(start, end);
        return value;
    }

    private int getDataSection()
    {
        int searchPos = m_currentIndex;
        int keyPos = 0;
        int boundaryLen = m_boundary.length();
        m_startData = m_currentIndex;
        m_endData = 0;

        //this searches through the byte array to find a match to the boundary
        //TODO: this search algorithm will miss cases where there are repeating
        //      patterns in the boundary....
        while (searchPos < m_totalBytes)
        {
            if(m_binArray[searchPos] == (byte)m_boundary.charAt(keyPos))
            {
                if(keyPos == boundaryLen - 1)
                {
                    //success, found it, so put the result in a global variable?
                    m_endData = ((searchPos - boundaryLen) + 1) - 3;
                    m_currentIndex = m_endData + boundaryLen + 3;
                    return m_endData;
                }
                searchPos++;
                keyPos++;
            }
            else
            {
                searchPos++;
                keyPos = 0;
            }
        }

        //you only get here if you fail to find the pattern.
        //should throw exception?
        return 0;
    }

    private String getDataHeader() throws UnsupportedEncodingException
    {
        int start = m_currentIndex;
        int end = 0;
        boolean found = false;
        //this appears to be scanning forward for a blank line (two CRs in a row)
        //TODO: this should check the total length of the buffer to avoid indexing off end
        while(!found)
        {
            if(m_binArray[m_currentIndex] == 13 && m_binArray[m_currentIndex + 2] == 13)
            {
                found = true;
                end = m_currentIndex - 1;
                m_currentIndex = m_currentIndex + 2;
            }
            else
            {
                m_currentIndex++;
            }
        }
        String dataHeader = new String(m_binArray, start, (end - start) + 1, "UTF-8");
        return dataHeader;
    }

    private String getFileNameFromPath(String filePathName)
    {
        int pos = 0;
        pos = filePathName.lastIndexOf('/');
        if(pos != -1) {
            return filePathName.substring(pos + 1, filePathName.length());
        }
        pos = filePathName.lastIndexOf('\\');
        if(pos != -1) {
            return filePathName.substring(pos + 1, filePathName.length());
        }
        else {
            return filePathName;
        }
    }

    public void setDenyPhysicalPath(boolean deny)
    {
        m_denyPhysicalPath = deny;
    }

    public void setForcePhysicalPath(boolean force)
    {
    }

    public void setContentDisposition(String contentDisposition)
    {
    }

    public void setTotalMaxFileSize(long totalMaxFileSize)
    {
        m_totalMaxFileSize = totalMaxFileSize;
    }

    public void setMaxFileSize(long maxFileSize)
    {
        m_maxFileSize = maxFileSize;
    }

    protected String getPhysicalPath(String filePathName, int option)
        throws IOException
    {
        String path = new String();
        String fileName = new String();
        String fileSeparator = new String();
        boolean isPhysical = false;
        fileSeparator = System.getProperty("file.separator");
        if(filePathName == null) {
            throw new IllegalArgumentException("There is no specified destination file.");
        }
        if(filePathName.equals("")) {
            throw new IllegalArgumentException("There is no specified destination file.");
        }
        if(filePathName.lastIndexOf("\\") >= 0)
        {
            path = filePathName.substring(0, filePathName.lastIndexOf("\\"));
            fileName = filePathName.substring(filePathName.lastIndexOf("\\") + 1);
        }
        if(filePathName.lastIndexOf("/") >= 0)
        {
            path = filePathName.substring(0, filePathName.lastIndexOf("/"));
            fileName = filePathName.substring(filePathName.lastIndexOf("/") + 1);
        }
        path = path.length() != 0 ? path : "/";
        File physicalPath = new File(path);
        if(physicalPath.exists()) {
            isPhysical = true;
        }
        if(option == 0)
        {
            if(isVirtual(path))
            {
                path = m_application.getRealPath(path);
                if(path.endsWith(fileSeparator)) {
                    path = path + fileName;
                }
                else {
                    path = String.valueOf((new StringBuffer(String.valueOf(path))).append(fileSeparator).append(fileName));
                }
                return path;
            }
            if(isPhysical)
            {
                if(m_denyPhysicalPath) {
                    throw new IllegalArgumentException("Physical path " + path + " is denied.");
                }
                else {
                    return filePathName;
                }
            } else
            {
                throw new IllegalArgumentException("This path " + path + " does not exist.");
            }
        }
        if(option == 1)
        {
            if(isVirtual(path))
            {
                path = m_application.getRealPath(path);
                if(path.endsWith(fileSeparator)) {
                    path = path + fileName;
                }
                else {
                    path = String.valueOf((new StringBuffer(String.valueOf(path))).append(fileSeparator).append(fileName));
                }
                return path;
            }
            if(isPhysical) {
                throw new IllegalArgumentException("The path " + path + " is not a virtual path.");
            }
            else {
                throw new IllegalArgumentException("This path " + path + " does not exist.");
            }
        }
        if(option == 2)
        {
            if(isPhysical) {
                if(m_denyPhysicalPath) {
                    throw new IllegalArgumentException("Physical path " + path + " is denied.");
                }
                else {
                    return filePathName;
                }
            }
            if(isVirtual(path)) {
                throw new IllegalArgumentException("The path " + path + " is not a physical path.");
            }
            else {
                throw new IllegalArgumentException("This path " + path + " does not exist.");
            }
        } else
        {
            return null;
        }
    }

    public void uploadInFile(String destFilePathName)
        throws Exception, IOException
    {
        int intsize = 0;
        int pos = 0;
        int readBytes = 0;
        if(destFilePathName == null) {
            throw new IllegalArgumentException("There is no specified destination file.");
        }
        if(destFilePathName.length() == 0) {
            throw new IllegalArgumentException("There is no specified destination file.");
        }
        if(!isVirtual(destFilePathName) && m_denyPhysicalPath) {
            throw new SecurityException("Physical path " + destFilePathName + " is denied.");
        }
        intsize = m_request.getContentLength();
        m_binArray = new byte[intsize];
        for(; pos < intsize; pos += readBytes) {
            try
            {
                readBytes = m_request.getInputStream().read(m_binArray, pos, intsize - pos);
            }
            catch(Exception e)
            {
                throw new NGException("nugen.exception.unable.to.upload.file",new Object[]{destFilePathName},e);
            }
        }

        if(isVirtual(destFilePathName)) {
            destFilePathName = m_application.getRealPath(destFilePathName);
        }
        try
        {
            File file = new File(destFilePathName);
            FileOutputStream fileOut = new FileOutputStream(file);
            fileOut.write(m_binArray);
            fileOut.close();
        }
        catch(Exception e)
        {
            throw new NGException("nugen.exception.data.cant.saved",new Object[]{destFilePathName},e);
        }
    }

    private boolean isVirtual(String pathName)
    {
        if(m_application.getRealPath(pathName) != null)
        {
            File virtualFile = new File(m_application.getRealPath(pathName));
            return virtualFile.exists();
        } else
        {
            return false;
        }
    }

    protected byte m_binArray[];
    protected HttpServletRequest m_request;
    protected HttpServletResponse m_response;
    protected ServletContext m_application;
    private int m_totalBytes;
    private int m_currentIndex;
    private int m_startData;
    private int m_endData;
    private String m_boundary;
    private long m_totalMaxFileSize;
    private long m_maxFileSize;
    private boolean m_denyPhysicalPath;
    public static final int SAVE_AUTO = 0;
    public static final int SAVE_VIRTUAL = 1;
    public static final int SAVE_PHYSICAL = 2;
    private UploadFiles m_files;
    private UploadRequest m_formRequest;
}