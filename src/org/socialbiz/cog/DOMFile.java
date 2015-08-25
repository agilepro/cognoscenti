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

package org.socialbiz.cog;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * At the root of a DOM tree is a node that has no parent, and that is the root
 * node for an XML file on disk.
 *
 * DOMFile is a subclass of DOMFace, with the additional capabilities to read
 * and write files.
 */
public class DOMFile extends DOMFace {
    File associatedFile;

    public DOMFile(File path, Document doc) {
        super(doc, doc.getDocumentElement(), null);
        associatedFile = path;
    }

    public File getFilePath() {
        return associatedFile;
    }

    public static Document readOrCreateFile(File path, String rootNode) throws Exception {
        try {
            Document userDoc;
            if (!path.exists()) {
                userDoc = DOMUtils.createDocument(rootNode);
            }
            else {
                FileInputStream is = new FileInputStream(path);
                userDoc = DOMUtils.convertInputStreamToDocument(is, false, false);
            }
            return userDoc;
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.read.create.xml.file",
                    new Object[] { path.toString() }, e);
        }
    }

    public void save() throws Exception {
        try {
            reformatXML();
            DOMUtils.writeDomToFile(fDoc, associatedFile);
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.write.file",
                    new Object[] { associatedFile.toString() }, e);
        }
    }

    public void saveAs(File newFile) throws Exception {
        try {
            associatedFile = newFile;
            DOMUtils.writeDomToFile(fDoc, associatedFile);
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.write.file",
                    new Object[] { associatedFile.toString() }, e);
        }
    }

    public void reformatXML() throws Exception {
        Element root = fDoc.getDocumentElement();
        indentChildren(root, "\n");
    }

    private void indentChildren(Element parent, String indent) throws Exception {
        NodeList childNdList = parent.getChildNodes();
        String newIndent = indent + "  ";

        // first scan to see if there are child Elements, or just text
        boolean hasChildElements = false;
        for (int i = 0; i < childNdList.getLength(); i++) {
            Node n = childNdList.item(i);
            if (n == null) {
                continue; // there are strange cases where it can be null
            }
            if (n.getNodeType() == org.w3c.dom.Node.ELEMENT_NODE) {
                hasChildElements = true;
                break;
            }
        }

        // if there are no elements, then don't modify anything ... it is a data
        // value
        if (!hasChildElements) {
            return;
        }

        // Since there are some elements, then we know this should be in this
        // pattern:
        //
        // indentation text node
        // element
        // indentation text node
        // element
        // smaller indentation text node
        //
        // All other text nodes can be deleted. Each indentation node is a
        // CR then n*2 spaces. The smaller indent is (n-1)*2 spaces.
        // To accomplish this, all Elements are removed from the parent and
        // placed
        // in a vector for temporary holding, and all the existing text nodes
        // are destroyed.
        // Once the parent is empty, the correct indenting nodes are added
        // between
        // the Element nodes.

        Vector<Element> elementSet = new Vector<Element>();
        for (int i = 0; i < childNdList.getLength(); i++) {
            Node n = childNdList.item(i);
            if (n.getNodeType() == org.w3c.dom.Node.ELEMENT_NODE) {
                elementSet.add((Element) n);
            }
        }
        {

            Node nx = parent.getFirstChild();
            while (nx != null) {
                parent.removeChild(nx);
                nx = parent.getFirstChild();
            }
        }

        if (parent.hasChildNodes()) {
            throw new ProgramLogicError(
                    "just cleaned out child nodes, but there seems to still be one.");
        }
        childNdList = parent.getChildNodes();
        if (childNdList.getLength() > 0) {
            throw new ProgramLogicError(
                    "just cleaned out child nodes, but there seems to still be one in childlist.");
        }

        Collections.sort(elementSet, new DOMElementComparator());

        Enumeration<Element> e1 = elementSet.elements();
        while (e1.hasMoreElements()) {
            parent.appendChild(fDoc.createTextNode(newIndent));
            Element ele = e1.nextElement();
            parent.appendChild(ele);
        }

        parent.appendChild(fDoc.createTextNode(indent));

        // recursively indent the children elements now
        e1 = elementSet.elements();
        while (e1.hasMoreElements()) {
            indentChildren(e1.nextElement(), newIndent);
        }

    }

    /**
     * use DOMElementComparator to sort a vector of elements into alphabetical
     * order according to their name.
     */
    static class DOMElementComparator implements Comparator<Element> {
        public DOMElementComparator() {
        }

        public int compare(Element o1, Element o2) {
            String name1 = o1.getNodeName();
            String name2 = o2.getNodeName();
            if (name1 == null || name2 == null) {
                return 0;
            }
            return name1.compareToIgnoreCase(name2);
        }
    }

    public static void moveFile(File oldLocation, File newLocation) throws Exception {
        FileInputStream is = new FileInputStream(oldLocation);
        FileOutputStream out = new FileOutputStream(newLocation);
        byte[] buf = new byte[2048];
        int amtRead = is.read(buf);
        while (amtRead > 0) {
            // these are bytes to write directly to the byte stream
            out.write(buf, 0, amtRead);
            amtRead = is.read(buf);
        }
        is.close();
        out.close();
        oldLocation.delete();
    }

}
