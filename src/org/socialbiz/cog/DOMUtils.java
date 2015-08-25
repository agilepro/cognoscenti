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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.StringReader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Random;
import java.util.Vector;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.ErrorHandler;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.socialbiz.cog.exception.NGException;

/**
 * This class offers a number of helper functions for dealing with XML DOMS
 * By centralizing all XML specific functions here, we can maximize reuse.
 *
 * @publish internal
 */
public class DOMUtils {

     /**
      * Enforce the fact that this object has only static methods
      * by having a private constructor. No reason to ever construct one of these
      */
  private DOMUtils() {
  }


    /**
    * Returns the text of all the chidren of a node as a single string
    *
    * @param node is the parent of the text
    * @param nodeName
    */
    public static String textValueOf(
        Node node,
        boolean trim)
    {
        // unfold the loop.  99.9% of the time, the XML will have a
        // single text node.  Memory is much more efficiently handled
        // if the string from that text node is used directly, instead
        // of being copied into the string buffer.   Unfold the loop,
        // and if there is a single child node, simply return that
        // value.
        Node child = skipToNextTextNode(node.getFirstChild());
        if (child == null) {
            return "";
        }
        Node nextChild = skipToNextTextNode(child.getNextSibling());
        if (nextChild == null) {
            if (trim) {
                return child.getNodeValue().trim();
            }
            else {
                return child.getNodeValue();
            }
        }

        // we have more than one, so make a string buffer to
        // concatenate them together.
        StringBuffer text = new StringBuffer();
        if (trim) {
            text.append(child.getNodeValue().trim());
        }
        else {
            text.append(child.getNodeValue());
        }
        child = nextChild;
        while (child != null) {
            if (trim) {
                text.append(child.getNodeValue().trim());
            }
            else {
                text.append(child.getNodeValue());
            }
            child = skipToNextTextNode(child.getNextSibling());
        }
        return text.toString();
    }


  /**
   * @returns the text value of a single node
   * @param contextNode
   * @param nodeName is the name of the subelement to find, if there
   *        are multiple then it finds and returns only the first one.
   * @param trim
   */
    public static String textValueOfChild(Node contextNode, String nodeName, boolean trim)
    {
        Node node = getFirstNodeByTagName(contextNode, nodeName);
        if (node == null) {
            return null;
        }
        return textValueOf(node, trim);
    }

    public static String getChildText(Element parent, String name)
    {
        Element child = getChildElement(parent, name);
        if (child==null) {
            return "";
        }
        return textValueOf(child, true);
    }


  /**
   * @returns the text value of nodes with the specified name
   * @param contextNode
   * @param nodeName
   * @param trim
   */
    public static String[] textValuesOfAll(Node contextNode, String nodeName, boolean trim)
        throws Exception
    {
        NodeList nodes = findNodesOneLevel(contextNode, nodeName);
        int last = nodes.getLength();
        String[] retval = new String[last];
        for (int i=0; i<last; i++) {
            retval[i] = textValueOf(nodes.item(i), trim);
        }
        return retval;
    }


    // PRIVATE:
    // if text node passed in, then that is returned.
    // if not, skips nodes that are not text nodes.
    // returns null when gets to the last sibling.
    private static Node skipToNextTextNode(Node child)
    {
        if (child==null) {
            return null;
        }
        while (child.getNodeType() != Node.CDATA_SECTION_NODE &&
               child.getNodeType() != Node.TEXT_NODE) {
            child = child.getNextSibling();
            if (child == null) {
                return null;
            }
        }
        return child;
    }


    /////////////////// ONE CHILD ///////////////////////


    /**
    * Returns the first child (direct descendant) with the specified name
    * Returns null if no child is found with that name.
    * Should be called 'findChildByName'
    *
    * @param contextNode
    * @param nodeName
    */
    public static Node getFirstNodeByTagName(Node contextNode, String nodeName)
    {
        // Use DOM traversal
        Node child = contextNode.getFirstChild();
        while (child != null) {
            if (child.getNodeName().equals(nodeName)) {
                return child;
            }
            child = child.getNextSibling();
        }
        return null;
    }

    public static Element getChildElement(Element parent, String name)
    {
        NodeList childNdList = parent.getChildNodes();
        if (childNdList==null) {
            return null;
        }
        for (int i = 0 ; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i);

            if (n==null) {
                //apparently, there is some situations where the Nodellist will return
                //a null.  Have gotten a null opinter exception on the line below.
                //don't understand how it happens, but this seems to happen, just skip it.
                continue;
            }

            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue ;
            }
            if (name.equals(n.getLocalName())) {
                return (Element) n;
            }
            if (name.equals(n.getNodeName())) {
                return (Element) n;
            }
        }
        return null;
    }

    public static Element getOrCreateChild(Document doc, Element parent, String name)
    {
        Element ret = getChildElement(parent, name);
        if (ret==null)
        {
            ret = createChildElement(doc, parent, name);
        }
        return ret;
    }





    /////////////////// ALL CHILDREN  ///////////////////////

    /**
    * Silly method.
    * As part of porting this from the old XML parser to DOM,
    * use this simple method to get child Elements.
    *  The old parser has a method for getting an Enumeration. That was used in
    *  hundreds of places. This simple method is an easy replacement for that.
    *
    * @deprecated use getChildElementsList instead
    *
    * @param from - a Node/Element from which we want to get all the child elements
    * @return an Enumeration of org.w3c.dom.Element objects
    * or an empty Enumeration if there are no child elements
    */

    public static Enumeration<Element> getChildElements(Element from)
    {
        if (from==null)
        {
            throw new RuntimeException("getChildElements must have a non null parameter 'from'");
        }
        Vector<Element> list = new Vector<Element>() ;
        NodeList childNdList = from.getChildNodes();
        for (int i = 0 ; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i) ;
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue ;
            }
            list.add((Element)n) ;
        }
        return list.elements() ;
    }

   /**
   * Get an ordered list of all ELEMENTs that are children of a context Node
   * NOTE: This is DIFFERENT THAN   getElementsByTagName("*")
   *   because this method does NOT traverse the full tree!!! It just gets direct children.
   *
   * @param contextNode - a Node/Element from which we want to get all the child elements
   * @return a List of org.w3c.dom.Element objects
   * or an empty List if there are no child elements
   */

    public static List<Element> getChildElementsList(Node contextNode)
    {
        ArrayList<Element> list = new ArrayList<Element>() ;
        NodeList childNdList = contextNode.getChildNodes();
        for (int i = 0 ; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i);
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue;
            }
            list.add((Element) n);
        }
        return list ;
    }




    /////////////////// SET OF CHILDREN  ///////////////////////

    public static Vector<Element> getNamedChildrenVector(Element from, String name)
    {
        Vector<Element> list = new Vector<Element>() ;
        NodeList childNdList = from.getChildNodes();
        for (int i = 0 ; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i) ;
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue ;
            }
            if (name.equals(n.getLocalName())) {
                list.add((Element)n) ;
            }
            if (name.equals(n.getNodeName())) {
                list.add((Element)n) ;
            }
        }
        return list;
    }

    /**
    * Searches a Node for children matching a particular Local Name
    * @param contextNode - the Node to start searching from
    * @param Local Name - the LOCAL NAME of the child node to search for (assuming of course that the DOM Document
    *            supports namespaces. If not, this will search for a full name matching this string.
    * @param recursively - If true - this will recurse downward in the Node tree.
    *   If false, then this will only search DIRECT CHILD NODES of the contextNode.
    */
    private static NodeList findNodes(Node contextNode, String expr, boolean recursively)
        throws Exception
    {
        if (contextNode == null)
        {
            // recover gracefully
            return new NodeListImpl();
        }
        try
        {
            // Use DOM traversal on children
            NodeListImpl nodeList = new NodeListImpl();
            Node child = contextNode.getFirstChild();
            while (child != null)
            {
                String lclNm = child.getLocalName() ;
                String fullNm = child.getNodeName() ;
                if ((lclNm != null && lclNm.equals(expr)) ||
                    (fullNm != null && fullNm.equals(expr))) {
                    nodeList.add(child);
                }
                if (recursively) {
                    nodeList.add(findNodes(child, expr, true));
                }
                child = child.getNextSibling();
            }
            return nodeList;
       }
       catch (Exception e) {
           throw new NGException("nugen.exception.error.while.searching.dom", new Object[]{e.getMessage()});
       }
    }


  /**
   * Recursively searches a Node for children matching a particular Local Name
   * @param contextNode
   * @param Local Name
   */
    public static NodeList findNodesOneLevel(Node contextNode, String expr)
        throws Exception
    {
        return findNodes(contextNode, expr, true) ;
    }




    public static Node findNodeWithAttrValue(Document doc, String elementName,
                       String attrName, String attrValue)
        throws Exception
    {
        NodeList elmts = doc.getElementsByTagNameNS("*", elementName) ; ;
        for (int i = 0 ; i < elmts.getLength(); i++)
        {
            NamedNodeMap attrs = elmts.item(i).getAttributes() ;
            if (attrs != null && attrs.getLength() > 0)
            {
                Node attrNode = attrs.getNamedItem(attrName) ;
                if (attrNode != null && attrValue.equals(attrNode.getNodeValue()))
                {
                    return elmts.item(i) ;
                }
            }
        }
        return null ;
    }


    ////////////////////////// REMOVE / REPLACE /////////////////////////////


    public static void removeAllChildren(Element parent)
    {
        NodeList childNdList = parent.getChildNodes();
        int last = childNdList.getLength();
        for (int i=last-1; i>=0 ; i--)
        {
            org.w3c.dom.Node n = childNdList.item(i);
            if (n==null) {
                continue;  //there are strange cases where it can be null
            }
            parent.removeChild(n);
        }

        //DEBUG: make sure it worked
        childNdList = parent.getChildNodes();
        if (childNdList!=null)
        {
            last = childNdList.getLength();
            if (last>0)
            {
                throw new RuntimeException("Attempted to remove all children, but it did not work!");
            }
        }
    }


    public static void removeAllNamedChild(Element parent, String name)
    {
        NodeList childNdList = parent.getChildNodes();
        for (int i = 0 ; i < childNdList.getLength(); i++)
        {
            org.w3c.dom.Node n = childNdList.item(i) ;
            if (n==null) {
                continue;  //there are strange cases where it can be null
            }
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE)
            {
                continue ;
            }
            if (name.equals(n.getLocalName()))
            {
                parent.removeChild(n);
            }
            if (name.equals(n.getNodeName()))
            {
                parent.removeChild(n);
            }
        }
    }

    // This method walks the document and removes all nodes
    // of the specified type and specified name.
    // If name is null, then the node is removed if the type matches.
    public static void removeAll(Node node, short nodeType, String name)
    {
        if (node.getNodeType() == nodeType &&
                (name == null || node.getNodeName().equals(name))) {
            node.getParentNode().removeChild(node);
        } else {
            // Visit the children
            NodeList list = node.getChildNodes();
            for (int i=0; i<list.getLength(); i++) {
                removeAll(list.item(i), nodeType, name);
            }
        }
    }

    /**
    * passing a null removed all evidence of a tag by that name
    * removed all duplicate values, and leaves with one child
    * of the name and value specified.
    */
    public static void setChildValue(Document doc, Element parent, String childName, String newValue)
    {
        Element child = getChildElement(parent, childName);

        if (newValue==null)
        {
            removeAllNamedChild(parent, childName);
        }

        if (child==null)
        {
            child = createChildElement(doc, parent, childName, newValue);
        }
        else
        {
            removeAllChildren(child);
            DOMUtils.addChildText(doc, child, newValue);
        }
    }



    ///////////////////////// CREATE / CONSTRUCT /////////////////////////////

    /**
     * This method is used to create a Child element.
     * @param doc document on which the Child Element has to be created.
     * @param parent Parent Element.
     * @param name Tag name of the Child Element.
     * @return Element.
     */
    public static Element createChildElement(Document doc, Element parent, String name)
    {
        Element newElem = doc.createElement(name);
        parent.appendChild(newElem);
        return newElem;
    }

    /**
     * This method is used to create a Child Text element.
     * @param doc document on which the Text Element has to be created.
     * @param parent Parent Element.
     * @param name Tag name of the Text Element.
     * @param textValue tag value of the Text Element.
     * @return Element.
     */
    public static Element createChildElement(Document doc, Element parent, String name, String textValue)
    {
        //if a null is passed in, then do not create the child element
        //at all.  Then when reading, if the element does not exist,
        //the value will be null.  This is standard behaviod for
        //optional element.
        if (textValue == null) {
            return null;
        }
        Element newElem = doc.createElement(name);
        newElem.appendChild(doc.createTextNode(textValue));
        parent.appendChild(newElem);
        return newElem;
    }

    /**
     * This method is used to create a Child Text node directly after the
     * last child of an existing element.  Needed when you have tags and
     * text interspursed.
     * @param doc document on which the Text has to be created.
     * @param parent Parent Element.
     * @param textValue tag value of the Text.
     * @return Element.
     */
    public
    static
    void
    addChildText( Document doc, Element parent, String textValue)
    {
        parent.appendChild(doc.createTextNode(textValue));
    }


    /**
     * This method is used to create an element with Attributes.
     * @param doc document on which the Child Element has to be created.
     * @param parent Parent Element.
     * @param name Tag Name of the Element
     * @param attributeNames List of Attribute names.
     * @param attributeValues List of Attribute values.
     * @return Element
     */
    public static Element createChildElement(Document doc, Element parent, String name,
                          String textValue, String[] attributeNames, String[] attributeValues)
    {
        Element newElem = doc.createElement(name);

        if (textValue != null) {
            newElem.appendChild(doc.createTextNode(textValue));
        }

        for (int i=0; i< attributeNames.length; i++) {
            newElem.setAttribute(attributeNames[i], attributeValues[i]);
        }

        parent.appendChild(newElem);
        return newElem;
    }



    ///////////////////////// DOCUMENTS /////////////////////////////

    /**
     * This method creates a new Document Object.
     * Pass in the name of the root node, since you ALWAYS need
     * a root node, and attaching this to the document is not like other children.
     * Retrieve the root element with the standard getDocumentElement.
     * @return
     * @throws Exception
     */
    public static Document createDocument(String rootNodeName)
        throws Exception
    {
        DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
        dfactory.setNamespaceAware(true);
        dfactory.setValidating(false);
        DocumentBuilder bldr = dfactory.newDocumentBuilder() ;
        Document doc = bldr.newDocument();
        Element rootEle = doc.createElement(rootNodeName);
        doc.appendChild(rootEle);
        return doc;
    }

    public static Document createDocument(String rootNodeName, String schema)
        throws Exception
    {
        DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
        dfactory.setNamespaceAware(true);
        dfactory.setValidating(false);
        DocumentBuilder bldr = dfactory.newDocumentBuilder() ;
        Document doc = bldr.newDocument();
        Element rootEle = doc.createElement(rootNodeName);
        rootEle.setAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
        rootEle.setAttribute("xsi:noNamespaceSchemaLocation", schema);
        doc.appendChild(rootEle);
        return doc;
    }



    ////////////////////////// READ WRITE /////////////////////////

    /**
     * This method is used to De-Serialize the DOM Document Object from a String.
     * @param xmlString The XML String.
     * @param validate
     * @param isNamespaceAware
     * @return Document of the DOM.
     * @throws Exception
     */
    public static Document convertInputStreamToDocument(
        InputStream is, boolean validate, boolean isNamespaceAware)
        throws Exception
    {
        DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
        dfactory.setNamespaceAware(isNamespaceAware);
        dfactory.setValidating(validate) ;
        dfactory.setIgnoringElementContentWhitespace(true) ;
        DocumentBuilder bldr = dfactory.newDocumentBuilder();
        bldr.setErrorHandler(new ErrorHandler()
        {
            public void warning (SAXParseException exception) throws SAXException {
                //ignore warnings
            }
            public void error (SAXParseException exception) throws SAXException {
                // ignore parse validation errors
            }
            public void fatalError (SAXParseException exception) throws SAXException {
                throw exception ;
            }
        });
        Document doc = bldr.parse(new InputSource(is));
        return doc;
    }


    /**
     * @Deprecated - you should never convert a string to a DOM because a string
     * is composed of 16-bit characters, and XML is typically a sequence of 8-bit
     * byte values.  The conversion of 8-bit to 16-bit might or might not be done
     * correctly.  DOM serialization does it correctly according to the encoding
     * placed at the beginning of the file.
     *
     * There are some places where we need get AML as a (16-bit char) string and
     * convert, so this method remains here, but it should be AVOIDED if at all
     * possible.
     *
     * Instead use the Stream interfaces for streaming bytes in and out of DOM.
     */
    public static Document convertStringToDocument(String xmlString, boolean validate,
                  boolean isNamespaceAware)
        throws Exception
    {
        DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
        dfactory.setNamespaceAware(isNamespaceAware);
        dfactory.setValidating(validate) ;
        dfactory.setIgnoringElementContentWhitespace(true) ;
        DocumentBuilder bldr = dfactory.newDocumentBuilder();
        bldr.setErrorHandler(new ErrorHandler()
        {
            public void warning (SAXParseException exception) throws SAXException {
                //ignore warnings
            }
            public void error (SAXParseException exception) throws SAXException {
                // ignore parse validation errors
            }
            public void fatalError (SAXParseException exception) throws SAXException {
                throw exception ;
            }
        });
        Document doc = bldr.parse(new InputSource(new StringReader(xmlString)));
        return doc;
    }

    public static void writeDom(Document doc, OutputStream out)
        throws Exception
    {
        DOMSource docSource = new DOMSource(doc);
        Transformer transformer = getXmlTransformer();
        transformer.transform(docSource, new StreamResult(out));
    }

    public static void writeDom(Document doc, Writer w)
        throws Exception
    {
        DOMSource docSource = new DOMSource(doc);
        Transformer transformer = getXmlTransformer();
        transformer.transform(docSource, new StreamResult(w));
    }

    public static void writeDomToFile(Document doc, File outFile)
        throws Exception
    {
        //if there is already a file, write to a temp file
        File tempFile = null;
        Random r = new Random();
        do
        {
            tempFile = new File(outFile.toString()+"tmp-"+r.nextInt(1000));
        }
        while (tempFile.exists());
        OutputStream fw = new FileOutputStream(tempFile);
        DOMUtils.writeDom(doc, fw);
        fw.flush();
        fw.close();

        //got here without problem, ok, delete the backup file, and rename output file
        if (outFile.exists())
        {
            outFile.delete();
        }
        tempFile.renameTo(outFile);
    }


  /**************************************************************************
   * Title:        A trivial Vector based NodeList implementation
   * Description:
   * @version 1.0
   */
    private static class NodeListImpl implements NodeList
    {
        private ArrayList<Node> nodeVector = null;

        public NodeListImpl()
        {
            nodeVector = new ArrayList<Node>();
        }

        public Node item(int index)
        {
            return nodeVector.get(index);
        }

        public void add(NodeList appendList)
        {
            for (int i = 0 ; i < appendList.getLength(); i++) {
                nodeVector.add(appendList.item(i)) ;
            }
        }

        public int getLength()
        {
            return nodeVector.size();
        }

        public void add(Node node)
        {
            nodeVector.add(node);
        }
    }

    /**
     * Utility method to do XML escaping for the given xml string.
     *
     * @param xmlStr
     *                Source XML String
     * @return escaped String.
     */
    public static String xmlEscape(String str) {
        StringBuffer validStr = new StringBuffer(str.length());
        for (int i = 0; i < str.length(); i++) {
            char currentChar = str.charAt(i);
            switch (currentChar) {
            case '\"': {
                validStr.append("&quot;");
                break;
            }
            case '\'': {
                validStr.append("&apos;");
                break;
            }
            case '<': {
                validStr.append("&lt;");
                break;
            }
            case '>': {
                validStr.append("&gt;");
                break;
            }
            case '&': {
                validStr.append("&amp;");
                break;
            }
            default:
                validStr.append(currentChar);
            }
        }
        return validStr.toString();
    }

    /**
     * This method is used to Serialize the DOM Document Object into a String.
     * This is the preferred way to convert an XML dom tree to a String, but
     * PLEASE try not to use this. Creating XML copies as strings in memory is a
     * bad practice. Streaming them directly to a file, or to a socket, is
     * better. But, if you need to have a String, use this one.
     *
     * @param doc
     *                Document Object.
     * @return XML String.
     * @throws Exception
     */
    public static String convertDomToStringAvoidUsingThis(Document doc) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        DOMSource docSource = new DOMSource(doc);
        Transformer transformer = getXmlTransformer();
        transformer.transform(docSource, new StreamResult(baos));
        return baos.toString("UTF-8");
    }

    private static Transformer getXmlTransformer() throws Exception {
        /*
         * CDATA_SECTION_ELEMENTS | cdata-section-elements = expanded names.
         * DOCTYPE_PUBLIC | doctype-public = string. DOCTYPE_SYSTEM |
         * doctype-system = string. ENCODING | encoding = string. INDENT |
         * indent = "yes" | "no". MEDIA_TYPE | media-type = string. METHOD |
         * method = "xml" | "html" | "text" | expanded name.
         * OMIT_XML_DECLARATION | omit-xml-declaration = "yes" | "no".
         * STANDALONE | standalone = "yes" | "no". VERSION | version = nmtoken.
         */

        initTransformer();
        Transformer transformer = transformerFactory.newTransformer();
        transformer.setOutputProperty(OutputKeys.METHOD, "xml");
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        try {
            transformer.setOutputProperty(
                    "{http://xml.apache.org/xslt}indent-amount", "4");
        } catch (IllegalArgumentException e) {
            // If the property is not supported, and is not qualified with a
            // namespace then
            // it throws IllegalArgumentException. we do not have to re-throw
            // this exception.
        }
        return transformer;
    }

    private static TransformerFactory transformerFactory = null;
    private static final Long mutex2 = new Long(2);
    private static final void initTransformer()
            throws TransformerFactoryConfigurationError,
            TransformerConfigurationException {
        if (transformerFactory == null) {
            synchronized (mutex2) {
                transformerFactory = TransformerFactory.newInstance();
            }
        }
    }

    public static void setSchemAttribute(Element root, String schema)
    {
        root.setAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");

        String targetns = "http://nugen.fujitsu.com";
        if(schema.endsWith("BookContent.xsd")) {
            targetns = "http://nugenextn.fujitsu.com/bookcontent/schema";
        }
        else if(schema.endsWith("PageList.xsd")) {
            targetns = "http://nugenextn.fujitsu.com/pagelist/schema";
        }
        else if(schema.endsWith("Status.xsd")) {
            targetns = "http://nugenextn.fujitsu.com/status/schema";
        }
        else if(schema.endsWith("UsersList.xsd")) {
            targetns = "http://nugenextn.fujitsu.com/userlist/schema";
        }
        else if(schema.endsWith("SearchResults.xsd")) {
            targetns = "http://nugenextn.fujitsu.com/search/schema";
        }
        else {
            targetns = "http://nugen.fujitsu.com";
        }

        root.setAttribute("xmlns", targetns);
        String schemloc = targetns + " " + schema;
        root.setAttribute("xsi:schemaLocation", schemloc);
    }

}
