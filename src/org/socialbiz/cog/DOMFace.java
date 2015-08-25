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

import java.lang.reflect.Constructor;
import java.util.Enumeration;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.workcast.json.JSONArray;

/**
* The purpose of this class is to be a base class to classes which
* are designed to be interfaced to DOM trees.  If you have a DOM
* tree, and you want to directly reflect that out to the program
* as structured data, you create a file that has getters and setters
* for the various members.  This base class containes convenient
* methods for manipulating the DOM tree, and keeping it in sync
* with the external representation you are presenting.
*
* GETTERS: pull values directly from child dom elements.  Useful when
*     a particular member is gotten only a few times any reading
*     of the file.  If this is a heavily used member, prefectch that
*     to a cache member, and use that.
* SETTERS: put value directly into child dom elements.  If you have
*     decided to use a cache member for fast access, don't forget to
*     update both the cache and the dom tree.
*/
public class DOMFace
{
    protected Document fDoc;
    protected Element fEle;
    protected DOMFace parent;


    private static Class<?>[] constructParams = new Class<?>[] {Document.class,
                              Element.class, DOMFace.class};


    public DOMFace(Document doc, Element ele, DOMFace p)
    {
        if (ele == null)
        {
            throw new RuntimeException("Program logic error: DOMFace object can not"
                +" be constructed on a null element parameter.");
        }
        if (doc == null)
        {
            throw new RuntimeException("Program logic error: DOMFace object can not"
                +" be constructed on a null document parameter.");
        }
        fDoc = doc;
        fEle = ele;
        parent = p;
    }


    public void setAttribute(String attrName, String value)
    {
        if (attrName == null)
        {
            throw new RuntimeException("Program logic error: a null attribute name"
                +" was passed to setAttribute.");
        }
        if (value == null)
        {
            fEle.removeAttribute(attrName);
        }
        else
        {
            fEle.setAttribute(attrName, value);
        }
    }
    public void clearAttribute(String attrName)
    {
        if (attrName == null)
        {
            throw new RuntimeException("Program logic error: a null attribute name"
                +" was passed to setAttribute.");
        }
        fEle.removeAttribute(attrName);
    }

    public void setAttributeLong(String attrName, long value)
    {
        setAttribute(attrName, Long.toString(value));
    }
    public String getAttribute(String attrName)
    {
        if (attrName == null)
        {
            throw new RuntimeException("Program logic error: a null attribute name"
                +" was passed to getAttribute.");
        }
        return fEle.getAttribute(attrName);
    }
    public long getAttributeLong(String attrName)
    {
        return safeConvertLong(getAttribute(attrName));
    }

    public boolean attributeEquals(String attrName, String testValue)
        throws Exception
    {
        if (testValue == null)
        {
            throw new RuntimeException("Program logic error: a null test value"
                +" was passed to attributeEquals.");
        }
        String val = getAttribute(attrName);
        if (val==null)
        {
            return false;
        }
        return testValue.equals(val);
    }

    public void setScalar(String memberName, String value)
    {
        if (memberName == null)
        {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to setScalar.");
        }
        DOMUtils.setChildValue(fDoc, fEle, memberName, value);
    }
    public String getScalar(String memberName)
    {
        if (memberName == null)
        {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to getScalar.");
        }
        return DOMUtils.getChildText(fEle, memberName);
    }

    /**
    * Returns the entire contents of the element as a block of
    * text.  Used when the element does not have any children elements
    * but still has attributes, and it has content in the form of text.
    */
    public String getTextContents()
    {
        return DOMUtils.textValueOf(fEle, true);
    }
    public void setTextContents(String newValue)
    {
        DOMUtils.removeAllChildren(fEle);
        DOMUtils.addChildText(fDoc, fEle, newValue);
    }


    public Element createChildElement(String elementName)
    {
        return DOMUtils.createChildElement(fDoc, fEle, elementName);
    }
    public Element createChildElement(String elementName, String value)
    {
        return DOMUtils.createChildElement(fDoc, fEle, elementName, value);
    }
    public void removeChildElement(Element ele)
    {
        fEle.removeChild(ele);
    }
    public void removeFromParent(Element parent)
    {
        parent.removeChild(fEle);
    }
    public void removeAllNamedChild(String elementName)
    {
        DOMUtils.removeAllNamedChild(fEle, elementName);
    }
    public void removeChildrenByNameAttrVal(String tagname, String attrName, String attrValue)
    {
        Vector<Element> children = getNamedChildrenVector(tagname);
        Enumeration<Element> e = children.elements();
        while (e.hasMoreElements())
        {
            Element child = e.nextElement();
            if (tagname.equals(child.getLocalName()) || tagname.equals(child.getNodeName()))
            {
                String childAttValue = child.getAttribute(attrName);
                if (childAttValue!=null && attrValue.equals(childAttValue))
                {
                    fEle.removeChild(child);
                }
            }
        }
    }




    public Vector<Element> getNamedChildrenVector(String elementName)
    {
        return DOMUtils.getNamedChildrenVector(fEle, elementName);
    }
    public void fillVectorValues(Vector<String> result, String elementName)
    {
        Vector<Element> children = getNamedChildrenVector(elementName);
        Enumeration<Element> e = children.elements();
        while (e.hasMoreElements())
        {
            Element child = e.nextElement();
            result.add(DOMUtils.textValueOf(child, false));
        }
    }
    public Vector<String> getVector(String memberName)
    {
        Vector<String> children = new Vector<String>();
        fillVectorValues(children, memberName);
        return children;
    }



    /**
    * If a containing tag has multiple child value tags
    * you can access and set all the values at once using a
    * vector of string values.
    *
    * Construct a vector will all of the string value in the correct
    * order.  Call setVector, and a child tag and value will be created
    * in the DOM tree for each value in the vector.  Any previous values
    * will be removed.
    *
    * memberName: the name of the tag holding a data value
    * values: a Vector of string values
    */
    public void setVector(String memberName, Vector<String> values)
    {
        if (memberName == null)
        {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to setVector.");
        }
        removeAllNamedChild(memberName);
        for (String val : values)
        {
            createChildElement(memberName, val);
        }
    }

    /**
    * Gets rid of all the values in a vector value
    *
    * memberName: the name of the tag holding a data value
    */
    public void clearVector(String memberName)
    {
        if (memberName == null)
        {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to setVector.");
        }
        removeAllNamedChild(memberName);
    }

    /**
    * If a containing tag has multiple child value tags
    * you append a value to that set of values.
    *
    * memberName: the name of the tag holding a data value
    * value: a string value to be added
    */
    public void addVectorValue(String memberName, String value)
    {
        if (memberName == null)
        {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to addVectorValue.");
        }
        createChildElement(memberName, value);
    }
    public void removeVectorValue(String memberName, String value)
    {
        if (memberName == null)
        {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to addVectorValue.");
        }
        Vector<Element> children = getNamedChildrenVector(memberName);
        Enumeration<Element> e = children.elements();
        while (e.hasMoreElements())
        {
            Element child = e.nextElement();
            String childVal = DOMUtils.textValueOf(child, false);
            if (childVal.equals(value))
            {
                fEle.removeChild(child);
            }
        }
    }

    public Element getElement()
    {
        return fEle;
    }
    public Document getDocument()
    {
        return fDoc;
    }
    public DOMFace getParent()
    {
        return parent;
    }

    /**
    * designed primarily for returning date long values
    * works only for positive integer (long) values
    * considers all numeral, ignores all letter and punctuation
    * never throws an exception
    * if you give this something that is not a number, you
    * get surprising result.  Zero if no numerals at all.
    */
    public static long safeConvertLong(String val)
    {
        if (val==null)
        {
            return 0;
        }
        long res = 0;
        int last = val.length();
        for (int i=0; i<last; i++)
        {
            char ch = val.charAt(i);
            if (ch>='0' && ch<='9')
            {
                res = res*10 + ch - '0';
            }
        }
        return res;
    }

    /**
    * designed primarily for returning date long values
    * works only for positive integer (long) values
    * considers all numeral, ignores all letter and punctuation
    * never throws an exception
    * if you give this something that is not a number, you
    * get surprising result.  Zero if no numerals at all.
    */
    public static int safeConvertInt(String val)
    {
        if (val==null)
        {
            return 0;
        }
        int res = 0;
        int last = val.length();
        for (int i=0; i<last; i++)
        {
            char ch = val.charAt(i);
            if (ch>='0' && ch<='9')
            {
                res = res*10 + ch - '0';
            }
        }
        return res;
    }




    ////////// CONSTRUCTORS - CHILDREN //////////////


    /**
    * Constructs an instance of an extended class.  This is used by all
    * the methods that take a class name and return elements of specific
    * subclasses.
    */
    public static <T extends DOMFace> T construct(Document doc, Element ele, DOMFace parent,
            Class<T> childClass) throws Exception {
        try {
            Constructor<T> con = childClass.getConstructor(constructParams);
            Object[] inits = new Object[3];
            inits[0] = doc;
            inits[1] = ele;
            inits[2] = parent;
            T retval = con.newInstance(inits);
            if (retval == null) {
                // this should absolutely never happen, but putting this check
                // here to make absolutely sure.
                throw new NGException("nugen.exception.fail.in.java.instantiator", null);
            }
            return retval;
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.create.object",
                    new Object[] { childClass.getName() }, e);
        }
    }


    private static String getElementName(Element e)
    {
        String name = e.getNodeName();
        if (name==null || name.length()==0)
        {
            name = e.getLocalName();
        }
        int colonPos = name.lastIndexOf(":");
        if (colonPos>=0)
        {
            name = name.substring(colonPos+1);
        }
        return name;
    }


    /**
    * Get a Vector full of DOMFace elements.  Pass in the tagname and the
    * specific class or objects you want constructed.  Class must have
    * a constructor with two parameters (like DOMFace).
    *
    * USAGE:  parent.getChildren("childtag", ChildClass.class);
    */
    public <T extends DOMFace> Vector<T> getChildren(String elementName, Class<T> childClass)
        throws Exception
    {
        Vector<T> list = new Vector<T>() ;
        Constructor<T> con = childClass.getConstructor(constructParams);
        Object[] inits = new Object[3];
        inits[0] = fDoc;
        inits[2] = this;

        NodeList childNdList = fEle.getChildNodes();
        for (int i = 0; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i);
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue;
            }
            Element ne = (Element) n;
            if (elementName.equals(getElementName(ne))) {
                inits[1] = n;
                list.add(con.newInstance(inits));
            }
        }
        return list;
    }


    /**
    * Get a single DOMFace elements.  Pass in the tagname and the
    * specific class or objects you want constructed.  Class must have
    * a constructor with three parameters (like DOMFace).  If there are
    * multiple dom elements, it only returns the child for the
    * first such element.
    *
    * USAGE:  parent.getChild("childtag", ChildClass.class);
    */
    public <T extends DOMFace> T getChild(String elementName, Class<T> childClass)
        throws Exception
    {
        NodeList childNdList = fEle.getChildNodes();
        for (int i = 0 ; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i) ;
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue ;
            }
            Element ne = (Element)n;
            if (elementName.equals(getElementName(ne)))
            {
                return construct(fDoc, ne, this, childClass);
            }
        }
        return null;
    }


    /**
    * Create a child DOMFace elements.  Pass in the tagname and the
    * specific class or objects you want constructed.  Class must have
    * a constructor with three parameters (like DOMFace).
    *
    * USAGE:  parent.createChild("childtag", ChildClass.class);
    */
    public <T extends DOMFace> T createChild(String elementName, Class<T> childClass)
        throws Exception
    {
        Element ne = createChildElement(elementName);
        return construct(fDoc, ne, this, childClass);
    }

    /**
    * Create a child DOMFace element as one of a number of such
    * elements, setting a given id attribute to a given value.
    * Pass in the tagname and the
    * specific class or objects you want constructed, along with the
    * name of an attribute, and a value to set it to.  Class must have
    * a constructor with three parameters (like DOMFace).
    */
    public <T extends DOMFace> T createChildWithID(String elementName, Class<T> childClass,
                String idAttribute, String idValue)
        throws Exception
    {
        Element ne = createChildElement(elementName);
        ne.setAttribute(idAttribute, idValue);
        return construct(fDoc, ne, this, childClass);
    }

    /**
    * Require child is used in places where you expect a single tag
    * and if it is no there, go ahead and create it.
    *
    * USAGE:  parent.requireChild("childtag", ChildClass.class);
    */
    public <T extends DOMFace> T requireChild(String elementName, Class<T> childClass)
        throws Exception
    {
        T df = getChild(elementName, childClass);
        if (df==null)
        {
            df = createChild(elementName, childClass);
        }
        return df;
    }


    /**
    * Remove a child
    */
    public void removeChild(DOMFace unwantedChild)
        throws Exception
    {
        fEle.removeChild(unwantedChild.getElement());
    }

    public <T extends DOMFace> T getChildAttribute(String attributeValue, Class<T> childClass,
            String AttributeName) throws Exception {
        NodeList childNdList = fEle.getChildNodes();
        for (int i = 0; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i);
            if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
                continue;
            }
            Element ne = (Element) n;
            if (attributeValue.equals(ne.getAttribute(AttributeName))) {
                return construct(fDoc, ne, this, childClass);
            }
        }
        return null;
    }


    public static JSONArray constructJSONArray(List<String> input) {
        JSONArray val = new JSONArray();
        for (String item : input) {
            val.put(item);
        }
        return val;
    }

    public static Vector<String> constructVector(JSONArray input) throws Exception {
        Vector<String> list = new Vector<String>();
        int top = input.length();
        for (int i = 0; i<top; i++) {
            String val = input.getString(i);
            //assure uniqueness of the values in the list, don't allow duplicates
            if (!list.contains(val)) {
                list.add(val);
            }
        }
        return list;
    }

}
