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

package org.socialbiz.cog.test;

import java.io.InputStream;
import java.nio.BufferOverflowException;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;




public class Page {

    private String html;

    // Data for textual content
    private String text;
    private String title;

    // binary data (e.g, image content)
    // It's null for html pages
    private byte[] binaryData;

    private ByteBuffer bBuf;

    private static Log log = LogFactory.getLog(Page.class.getName());

    private final static String defaultEncoding = Configurations
            .getStringProperty("crawler.default_encoding", "UTF-8");

    public static final int MAX_DOWNLOAD_SIZE = Configurations
            .getIntProperty("fetcher.max_download_size", 1048576);

    public boolean load(final InputStream in, final int totalsize,
            final boolean isBinary) {
        if (totalsize > 0) {
            this.bBuf = ByteBuffer.allocate(totalsize + 1024);
        } else {
            this.bBuf = ByteBuffer.allocate(MAX_DOWNLOAD_SIZE);
        }
        final byte[] b = new byte[1024];
        int len;
        double finished = 0;
        try {
            while ((len = in.read(b)) != -1) {
                if (finished + b.length > this.bBuf.capacity()) {
                    break;
                }
                this.bBuf.put(b, 0, len);
                finished += len;
            }
        } catch (final BufferOverflowException boe) {
            log.error("Page size exceeds maximum allowed.");
            return false;
        } catch (final Exception e) {
            log.error(e.getMessage());
            return false;
        }

        this.bBuf.flip();
        if (isBinary) {
            binaryData = new byte[bBuf.limit()];
            bBuf.get(binaryData);
        } else {
            this.html = "";
            this.html += Charset.forName(defaultEncoding).decode(this.bBuf);
            this.bBuf.clear();
            if (this.html.length() == 0) {
                return false;
            }
        }
        return true;
    }

    public String getHTML() {
        return this.html;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }
    // Image or other non-textual pages
    public boolean isBinary() {
        return binaryData != null;
    }

    public byte[] getBinaryData() {
        return binaryData;
    }

}
