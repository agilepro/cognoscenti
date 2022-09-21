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

import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.util.ThreeWayMerge;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

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

    public String getAttribute(String attrName)
    {
        if (attrName == null)
        {
            throw new RuntimeException("Program logic error: a null attribute name"
                +" was passed to getAttribute.");
        }
        return fEle.getAttribute(attrName);
    }

    public void setAttributeLong(String attrName, long value) {
        setAttribute(attrName, Long.toString(value));
    }
    public void setAttributeInt(String attrName, int value) {
        setAttribute(attrName, Integer.toString(value));
    }
    public long getAttributeLong(String attrName) {
        return safeConvertLong(getAttribute(attrName));
    }
    public int getAttributeInt(String attrName) {
        return safeConvertInt(getAttribute(attrName));
    }
    public boolean getAttributeBool(String attrName) {
        return "true".equals(getAttribute(attrName));
    }
    public void setAttributeBool(String attrName, boolean newVal) {
        if (newVal) {
            setAttribute(attrName, "true");
        }
        else {
            clearAttribute(attrName);
        }
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

    public void clearScalar(String memberName) {
        setScalar(memberName, null);
    }
    public void setScalar(String memberName, String value) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to setScalar.");
        }
        DOMUtils.setChildValue(fDoc, fEle, memberName, value);
    }
    public String getScalar(String memberName) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to getScalar.");
        }
        return DOMUtils.getChildText(fEle, memberName);
    }
    public long getScalarLong(String memberName) {
        return safeConvertLong(getScalar(memberName));
    }
    public void setScalarLong(String memberName, long value) {
        setScalar(memberName, Long.toString(value));
    }
    public void mergeScalar(String key, String oldValue, String newValue) {
        String curDoc = getScalar(key);
        String result = ThreeWayMerge.mergeThem(curDoc, oldValue, newValue);
        setScalar(key, result);
    }
    public void mergeScalarDelta(String key, JSONObject vals) throws Exception {
        String curDoc = getScalar(key);
        String result = ThreeWayMerge.mergeThem(curDoc, vals.optString("old",""),  vals.optString("new",""));
        setScalar(key, result);
    }
    public boolean mergeIfPresent(JSONObject updateJSON, String key) throws Exception {
    	if (updateJSON.has(key+"Merge")) {
    		mergeScalarDelta(key, updateJSON.getJSONObject(key+"Merge"));
    		return true;
    	}
    	return false;
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
        List<Element> children = getNamedChildrenVector(tagname);
        for  (Element child : children) {
            if (tagname.equals(child.getLocalName()) || tagname.equals(child.getNodeName())) {
                String childAttValue = child.getAttribute(attrName);
                if (childAttValue!=null && attrValue.equals(childAttValue)) {
                    fEle.removeChild(child);
                }
            }
        }
    }




    public List<Element> getNamedChildrenVector(String elementName)
    {
        return DOMUtils.getNamedChildrenVector(fEle, elementName);
    }
    public void fillVectorValues(List<String> result, String elementName) {
        List<Element> children = getNamedChildrenVector(elementName);
        for (Element child : children) {
            result.add(DOMUtils.textValueOf(child, false));
        }
    }
    public List<String> getVector(String memberName)
    {
        List<String> children = new ArrayList<String>();
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
    * values: a List of string values
    */
    public void setVector(String memberName, List<String> values) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to setVector.");
        }
        removeAllNamedChild(memberName);
        for (String val : values) {
            createChildElement(memberName, val);
        }
    }
    public void setVectorLong(String memberName, List<Long> values) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to setVector.");
        }
        removeAllNamedChild(memberName);
        for (Long val : values) {
            createChildElement(memberName, Long.toString(val));
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
    public void removeVectorValue(String memberName, String value) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to addVectorValue.");
        }
        List<Element> children = getNamedChildrenVector(memberName);
        for (Element child : children) {
            String childVal = DOMUtils.textValueOf(child, false);
            if (childVal.equals(value)) {
                fEle.removeChild(child);
            }
        }
    }
    /**
     * Add a value to a vector, but only if it is not already there.
     */
    public void addUniqueValue(String memberName, String value) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to addVectorValue.");
        }
        AddressListEntry newUser = new AddressListEntry(value);
        List<Element> children = getNamedChildrenVector(memberName);
        for (Element child : children) {
            String childVal = DOMUtils.textValueOf(child, false);
            if (newUser.hasAnyId(childVal)) {
                //value is already there, so ignore this add
                return;
            }
        }
        createChildElement(memberName, value);
    }

    public Element getElement() {
        return fEle;
    }
    public Document getDocument() {
        return fDoc;
    }
    public DOMFace getParent() {
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
    public static long safeConvertLong(String val) {
        if (val==null) {
            return 0;
        }
        long res = 0;
        boolean isNegative = false;
        int last = val.length();
        for (int i=0; i<last; i++) {
            char ch = val.charAt(i);
            if (ch>='0' && ch<='9') {
                res = res*10 + ch - '0';
            }
            else if (ch=='-') {
                isNegative = true;
            }
        }
        if (isNegative) {
            res = -res;
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
            throw new JSONException("Unable to construct XML object for {0}", e, childClass.getName());
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
    * Get a List full of DOMFace elements.  Pass in the tagname and the
    * specific class or objects you want constructed.  Class must have
    * a constructor with two parameters (like DOMFace).
    *
    * USAGE:  parent.getChildren("childtag", ChildClass.class);
    */
    public <T extends DOMFace> List<T> getChildren(String elementName, Class<T> childClass)
            throws Exception {
        ArrayList<T> list = new ArrayList<T>() ;
        Constructor<T> con = childClass.getConstructor(constructParams);
        Object[] inits = new Object[3];
        inits[0] = fDoc;
        inits[2] = this;

        NodeList childNdList = fEle.getChildNodes();
        for (int i = 0; i < childNdList.getLength(); i++) {
            org.w3c.dom.Node n = childNdList.item(i);
            if (n == null) {
                continue; // there are strange cases where it can be null
            }
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
            if (n == null) {
                continue; // there are strange cases where it can be null
            }
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
    *
    * @param elementName   the tag name in the XML
    * @param childClass    the Java class of the child
    * @param idAttribute   the name of the attribute of the XML that holds the id
    * @param idValue       the value of the id that you are looking for
    */
    public <T extends DOMFace> T createChildWithID(String elementName, Class<T> childClass,
                String idAttribute, String idValue) throws Exception {
        Element ne = createChildElement(elementName);
        ne.setAttribute(idAttribute, idValue);
        return construct(fDoc, ne, this, childClass);
    }


    /**
     * This will look for and find a child of a particular tag and class, with
     * and id of a specified value if it exists.  If it does not exist, it will
     * return null.
     *
     * @param elementName   the tag name in the XML
     * @param childClass    the Java class of the child
     * @param idAttribute   the name of the attribute of the XML that holds the id
     * @param idValue       the value of the id that you are looking for
     */
    public <T extends DOMFace> T findChildWithID(String elementName, Class<T> childClass,
            String idAttribute, String idValue) throws Exception {
        List<T> list = getChildren(elementName, childClass);
        for (T inst : list) {
            if (idValue.equals(inst.getAttribute(idAttribute))) {
                return inst;
            }
        }
        return null;
    }

    /**
     * This will look for and find a child of a particular tag and class, with
     * and id of a specified value if it exists.  If it does not exist, it will
     * create one.
     *
     * @param elementName   the tag name in the XML
     * @param childClass    the Java class of the child
     * @param idAttribute   the name of the attribute of the XML that holds the id
     * @param idValue       the value of the id that you are looking for
     */
    public <T extends DOMFace> T findOrCreateChildWithID(String elementName, Class<T> childClass,
            String idAttribute, String idValue) throws Exception {
        T child = findChildWithID(elementName, childClass, idAttribute, idValue);
        if (child==null) {
            child = createChildWithID(elementName, childClass, idAttribute, idValue);
        }
        return child;
    }

    /**
     * This will look for and remove a child of a particular tag and class, with
     * and id of a specified value if it exists.  If not found the call does nothing.
     *
     * @param elementName   the tag name in the XML
     * @param childClass    the Java class of the child
     * @param idAttribute   the name of the attribute of the XML that holds the id
     * @param idValue       the value of the id that you are looking for
     */
    public <T extends DOMFace> void removeChildWithID(String elementName, Class<T> childClass,
            String idAttribute, String idValue) throws Exception {
        List<T> list = getChildren(elementName, childClass);
        for (T inst : list) {
            if (idValue.equals(inst.getAttribute(idAttribute))) {
                this.removeChild(inst);
            }
        }
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
            if (n == null) {
                continue; // there are strange cases where it can be null
            }
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
        JSONArray array = new JSONArray();
        for (String item : input) {
            array.put(item);
        }
        return array;
    }
    public static JSONArray constructJSONArrayEmail(List<String> input) {
        JSONArray array = new JSONArray();
        for (String item : input) {
            array.put(UserManager.getCorrectedEmail(item));
        }
        return array;
    }
    public static JSONArray constructJSONArrayLong(List<Long> input) {
        JSONArray array = new JSONArray();
        for (Long item : input) {
            array.put(item.longValue());
        }
        return array;
    }

    public static List<String> constructVector(JSONArray inputArray) throws Exception {
        ArrayList<String> list = new ArrayList<String>();
        int top = inputArray.length();
        for (int i = 0; i<top; i++) {
            String val = inputArray.getString(i);
            //assure uniqueness of the values in the list, don't allow duplicates
            if (!list.contains(val)) {
                list.add(val);
            }
        }
        return list;
    }
    public static List<Long> constructVectorLong(JSONArray inputArray) throws Exception {
        ArrayList<Long> list = new ArrayList<Long>();
        int top = inputArray.length();
        for (int i = 0; i<top; i++) {
            long longVal = inputArray.getLong(i);
            //assure uniqueness of the values in the list, don't allow duplicates
            Long objVal = new Long(longVal);
            if (!list.contains(objVal)) {
                list.add(objVal);
            }
        }
        return list;
    }

    /**
     * Every DOMFace object can implement an update from JSON in order to receive JSON update
     * from external.  There is no default behavior and instead it must be implemented on
     * each of the subclasses if need.  This is used by some of the base routines.
     * If one of those routines are used, but this is not implemented on that class,
     * then an exception will be thrown.
     */
    public void updateFromJSON(JSONObject foo) throws Exception {
        throw new JSONException("UpdateFromJSON method needs to be implemented on the class {0}", this.getClass().getName());
    }
    public JSONObject getJSON() throws Exception {
        throw new JSONException("getJSON method needs to be implemented on the class {0}", this.getClass().getName());
    }

    // --------------------------------------------------------------------------
    // All of these convert between JSON representation and XML representation
    // but they keep the name of the item the same.
    // EXTRACT copies a value from the CML to the JSON.
    // UPDATE copies from the JSON to the XML if it exists.
    // --------------------------------------------------------------------------

    public void extractScalarString(JSONObject dest, String fieldName) throws Exception {
        String val = getScalar(fieldName);
        if (val!=null) {
            dest.put(fieldName, val);
        }
    }
    public void extractScalarEmail(JSONObject dest, String fieldName) throws Exception {
        String val = getScalar(fieldName);
        if (val!=null) {
            val = UserManager.getCorrectedEmail(val);
            dest.put(fieldName, val);
        }
    }
    public boolean updateScalarString(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            setScalar(fieldName, srce.getString(fieldName));
            return true;
        }
        return false;
    }
    public void extractVectorString(JSONObject dest, String fieldName) throws Exception {
        JSONArray ja = new JSONArray();
        for (String val : getVector(fieldName)) {
            ja.put(val);
        }
        dest.put(fieldName, ja);
    }
    public boolean updateVectorString(String fieldName, JSONObject srce) throws Exception {
        if (!srce.has(fieldName)) {
            return false;
        }
        JSONArray ja = srce.getJSONArray(fieldName);
        if (ja.length()==0) {
            return false;
        }
        List<String> vals = new ArrayList<String>();
        for (int i=0; i<ja.length(); i++) {
            vals.add(ja.getString(i));
        }
        setVector(fieldName, vals);
        return true;
    }
    public boolean updateUniqueVectorString(String fieldName, JSONObject srce) throws Exception {
        Set<String> uniqueCheck = new HashSet<String>();
        if (!srce.has(fieldName)) {
            return false;
        }
        JSONArray ja = srce.getJSONArray(fieldName);
        if (ja.length()==0) {
            return false;
        }
        List<String> vals = new ArrayList<String>();
        for (int i=0; i<ja.length(); i++) {
            String value = ja.getString(i).trim();
            String lcvalue = value.toLowerCase();
            if (!uniqueCheck.contains(lcvalue)) {
                vals.add(value);
                uniqueCheck.add(lcvalue);
            }
        }
        setVector(fieldName, vals);
        return true;
    }
    public void extractAttributeString(JSONObject dest, String fieldName) throws Exception {
        String val = getAttribute(fieldName);
        if (val!=null) {
            dest.put(fieldName, val);
        }
    }
    public boolean updateAttributeString(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            setAttribute(fieldName, srce.getString(fieldName));
            return true;
        }
        return false;
    }
    public void extractScalarLong(JSONObject dest, String fieldName) throws Exception {
        dest.put(fieldName, getScalarLong(fieldName));
    }
    public boolean updateScalarLong(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            setScalarLong(fieldName, srce.getLong(fieldName));
            return true;
        }
        return false;
    }
    public void extractScalarInt(JSONObject dest, String fieldName) throws Exception {
        dest.put(fieldName, (int) getScalarLong(fieldName));
    }
    public boolean updateScalarInt(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            setScalarLong(fieldName, srce.getInt(fieldName));
            return true;
        }
        return false;
    }
    public void extractAttributeLong(JSONObject dest, String fieldName) throws Exception {
        dest.put(fieldName, getAttributeLong(fieldName));
    }
    public boolean updateAttributeLong(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            long def = getAttributeLong(fieldName);
            setAttributeLong(fieldName, srce.optLong(fieldName, def));
            return true;
        }
        return false;
    }
    public void extractAttributeInt(JSONObject dest, String fieldName) throws Exception {
        dest.put(fieldName, (int) getAttributeLong(fieldName));
    }
    public boolean updateAttributeInt(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            int def = getAttributeInt(fieldName);
            setAttributeLong(fieldName, srce.optInt(fieldName, def));
            return true;
        }
        return false;
    }

    public void extractAttributeBool(JSONObject dest, String fieldName) throws Exception {
        dest.put(fieldName, getAttributeBool(fieldName));
    }
    public boolean updateAttributeBool(String fieldName, JSONObject srce) throws Exception {
        if (srce.has(fieldName)) {
            boolean def = getAttributeBool(fieldName);
            setAttributeBool(fieldName, srce.optBoolean(fieldName, def));
            return true;
        }
        return false;
    }


    /**
     * Given a set of children with a specific tag name that all have associated
     * Java classes that have getJSON implemented to generate the right representation
     * in JSON, this method will create a JSONArray of those children.
     * @param dest       the object that will get the array of the specified name
     * @param fieldName  the name of the array
     * @param childClass the Java class for the children
     */
    public <T extends DOMFace> void extractCollection(JSONObject dest, String fieldName,
            Class<T> childClass) throws Exception {
        JSONArray array = new JSONArray();
        for (T inst : getChildren(fieldName, childClass)) {
            array.put(inst.getJSON());
        }
        dest.put(fieldName, array);
    }


    /**
     * This will take an object which has a member that is a JSONArray of objects
     * and it will update all of the corresponding children.  The assumption is that
     * the member name on the JSONObject is the same as the tag name of the children.
     * Each child has an id attribute, and the attribute name is the same in the JSON
     * and in the XML.
     *
     * This gives PATCH style semantics to collections.  You can update with a single
     * instance object in it, and it will either delete that child, create that child
     * or update the child according to a key field value specified.  It is done in
     * a type-safe class-safe way such that the Java can still ensure the consistency
     * of the child XML DOM objects.
     *
     * This will look at each JSONObject in the JSONArray specified by name, and look
     * for a corresponding child DOM element with the same tag name, and with an id
     * that matches.  It will then create, update or delete that child.
     *
     * If the object in the array has a member "_DELETE_ME_" then the child will be
     * deleted instead of being updated.  If no matching child is found the delete
     * command is ignored.
     *
     * If not a delete case, then it looks for the child.  If no child is found,
     * one will be created.  Whether found or created the child will be updated
     * using JSONUpdate.
     *
     * @param parent the JSONObject that has a member which is a JSONArray
     * @param memberName the name of the member which is the JSONArray
     * @param childClass the Java class of the child objects
     * @param idAttribute the name of the attribute that holds the id both
     *                    in the JSON and in the child XML attribute.
     */
    public <T extends DOMFace> void updateCollection(JSONObject parent, String memberName,
            Class<T> childClass, String idAttribute) throws Exception {
        try {
            if (parent.has(memberName)) {
                JSONArray respArray = parent.getJSONArray(memberName);
                int last = respArray.length();
                for (int i=0; i<last; i++) {
                    JSONObject instanceObj = respArray.getJSONObject(i);
                    String key = null;
                    if (instanceObj.has(idAttribute)) {
                        //use the key of the object passed in.
                        key = instanceObj.getString(idAttribute);
                    }
                    else {
                        //if no key is specified, then generate a key here and use that.
                        //Can only be a CREATE case.
                        key = IdGenerator.generateKey();
                    }
                    boolean isDelete = instanceObj.has("_DELETE_ME_");
                    if (isDelete) {
                        removeChildWithID(memberName, childClass,  idAttribute, key);
                    }
                    else {
                        T oneResp = findOrCreateChildWithID(memberName, childClass, idAttribute, key);
                        oneResp.updateFromJSON(instanceObj);
                    }
                }
            }
        }
        catch (Exception e) {
            throw new JSONException("Unable to update collection named {0}", e, memberName);
        }
    }

}
