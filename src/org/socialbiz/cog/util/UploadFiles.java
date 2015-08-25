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

import java.io.IOException;
import java.util.Vector;

/**
 * @publish extension
 */
public class UploadFiles {

    UploadFiles()
    {
        m_files = new Vector<UploadFile>();
    }

    protected void addFile(UploadFile newFile) throws Exception
    {
        if (newFile == null)
        {
            throw new IllegalArgumentException("Null file passed to addFile.  File must not be null.");
        }
        m_files.add(newFile);
    }

    public UploadFile getFile(int index)
    {
        if (index < 0)
        {
            throw new IllegalArgumentException("File's index " + index
                    + " cannot be a negative value.");
        }
        int last = getCount();
        if (index >= last)
        {
            throw new IllegalArgumentException("File's index " + index
                    + " is greater than the number of files being held.");
        }
        UploadFile retval = m_files.elementAt(index);
        if (retval == null)
        {
            throw new IllegalArgumentException(
                    "Something is wrong with the collection of files.  Index '"+index+"' returned a null value.");
        }
        return retval;
    }

    public int getCount()
    {
        return m_files.size();
    }

    public long getSize() throws IOException
    {
        long tmp = 0L;
        int last = m_files.size();
        for (int i = 0; i < last; i++)
        {
            tmp += getFile(i).getSize();
        }
        return tmp;
    }

    private Vector<UploadFile> m_files;
}