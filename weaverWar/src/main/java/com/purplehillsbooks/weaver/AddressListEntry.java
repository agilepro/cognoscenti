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

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
* An entry in the address list.  Holds the email address
* and optionally a UserProfile so that duplicate or alternate
* email addresses can be identified easily.
*
* Address lists can also hold a reference to a role.
* The method isRoleRef() returns true if this is the case.
* Create a role ref version with newRoleRef.
*
* ALE provides a number of functions around parsing and handling
* email addresses and openids.  Whenever you get an email address
* the code should immediately create an ALE and manipulate that.
*
* Upon construction, the ALE will parse the email address, and say
* whether it is a valid email address or not.
*
* The constructor will also detect if the ID is an openid.
*
* Then, it will look into the list of profiles, and see if there is
* a user profile that matches this address.  If it finds one, it will
* make use of of that user's PREFERRED address, instead of the one
* given.
*
* getUniversalId() - returns the "best" id for the user matched with
*     this address.  If no user was found, then the original address returned.
*
* getOriginalId() - returns the (cleaned up) address that was passed in.
*
* getEmail() - returns either the best email address for the user, or
*     the original address if that looks like email, otherwise null string.
*
* There is no way to "set" the id since you only use the constructor
* and pass an email address in.
*
* Generally, the ALE is passed to other objects to either add them to
* a list of addresses (like a NGRole) or to other methods that need a
* target address.
*
* When you have a list of ALE you can find which ones match a particular
* address using hasAnyId() which will test all of a user's addresses
* as well as their name for a match.  If no matching profile was found,
* the obviously it only matches against the address passed in.
*
* Then, when outputting UI you have:
*
* writeLink() to write a well formatted link into a web page
*
* writeURLEncodedID() for composing web URLS
*
*
*/
public class AddressListEntry implements UserRef
{
    String       rawAddress;
    boolean      isRole       = false;
    UserProfile  user;
    String       namePart;

    public static final char RAQUO = '\u00BB';
    public static final char LAQUO = '\u00AB';


    /**
     * This is the main constructor used on a unique id of a person,
     * could be an email address or an OpenID style uid.
     * It will search and try to find the user.
     */
    public AddressListEntry(String addr) {
        if (addr==null) {
            throw new ProgramLogicError("AddressListEntry: attempt to construct an instance with a null value");
        }
        if (addr.indexOf(LAQUO)>=0 || addr.indexOf('<')>=0) {
            throw new ProgramLogicError("AddressListEntry: looks like a combined address value and should be using parseCombinedAddress method: "+addr);
        }
        rawAddress = UserManager.getCorrectedEmail(addr);
        user = UserManager.getStaticUserManager().findUserByAnyIdOrFail(addr);
    }

    /**
     * This constructor is used when you have two values, one
     * universal id, and a name.  First the uid will be used to
     * try and find the user object.  If found, then the name
     * is ignored.  If not found, then the name is remembered.
     * @throws Exception
     */
    public AddressListEntry(String uid, String name) throws Exception {
        this(uid);
        if (user==null && name!=null && name.length()>0) {

            //check to see if we have seen this email address before
            //and if so we will be using the previously recorded name
            MicroProfileRecord record = MicroProfileMgr.findMicroProfileById(uid);

            //if not, then put the name we have at this point into the
            //microprofile because it is better than nothing
            if (record==null) {
                MicroProfileMgr.setDisplayName(uid, name);
            }
        }
    }


    public AddressListEntry(UserProfile knownUser) {
        if (knownUser==null) {
            throw new RuntimeException("Unable to construct AddressListEntry on a null user profile object");
        }
        user = knownUser;
        rawAddress = user.getUniversalId();
    }

    /**
    * Pass the name of a role in, and get an AddressListEntry
    * that represents a reference to a role in return.
    */
    public static AddressListEntry newRoleRef(String roleName)
    {
        AddressListEntry retval = new AddressListEntry(roleName);
        retval.setRoleRef(true);
        return retval;
    }

    /**
    * Return the email address for this entry if one is known.
    * If not, return a null string.
    */
    public String getEmail() {
        if (user!=null) {
            return user.getPreferredEmail();
        }
        return rawAddress;
    }

    /**
     * An ALE is constructed on a string value.  That value might or might not
     * be appropriate to designate a user.  Use this function to see if the
     * ALE looks like it is a valid representation of a user.
     *
     * Every user HAS to have an email address at this point, so this method
     * will check to make sure that they have an email.  In the future if there
     * are any other consistency constraints we can set that here.
     */
    public boolean isWellFormed() {
        String email = getEmail();
        return (email!=null && email.length()>0);
    }


    /**
    * Return the best global unique ID for this address list entry.
    * Usually an email address, but not always.  Could be an openid if there is no user
    * profile associated with the initial address.  Or it could be the name of a role.
    */
    public String getUniversalId() {
        if (user!=null) {
            return user.getUniversalId();
        }
        else {
            return rawAddress;
        }
    }

    public String getKey() {
        if (user!=null) {
            return user.getKey();
        }
        else {
            //if this is a bare email address, use the email as the key
            return getUniversalId();
        }
    }

    /**
    * return the ID that was used in this role or address list
    * the one that was used to find the associated user.
    */
    public String getInitialId()
    {
        return rawAddress;
    }

    /**
    * return the best email address for this entry
    */
    public boolean hasAnyId(String testAddr)
    {
        if (user!=null)
        {
            return user.hasAnyId(testAddr);
        }
        else
        {
            return testAddr.equalsIgnoreCase(rawAddress);
        }
    }

    public boolean equals(UserRef other)
    {
        //first test one way
        if (hasAnyId(other.getUniversalId()))
        {
            return true;
        }

        //then test the other way
        return other.hasAnyId(getUniversalId());
    }

    /**
    * Say whether this address list entry is for the specified profile
    */
    public boolean isSameAs(UserProfile another)
    {
        if (user!=null)
        {
            return user.getKey().equals(another.getKey());
        }
        return false;
    }

    /**
    * return the best name, either the user name, or the address
    * in the case that no user was found.
    */
    public String getName()
    {
        if (user!=null)
        {
            String uName = user.getName();
            if (uName==null || uName.length()==0) {
                return rawAddress;
            }
            return uName;
        }
        MicroProfileRecord record = MicroProfileMgr.findMicroProfileById(rawAddress);
        if (record != null)
        {
            return record.getDisplayName();
        }
        if (namePart!=null)
        {
            return namePart;
        }

        return rawAddress;
    }



    public void writeURLEncodedID(AuthRequest ar) throws Exception {
        if (user!=null) {
            ar.write(user.getKey());
        }
        else {
            ar.writeURLData(rawAddress);
        }
    }


    /**
    * Write out a HTML link to fetch the informatin about this user
    * if possible.
    */
    public void writeLink(AuthRequest ar) throws Exception
    {
        if (user != null) {
            user.writeLink(ar);
            if (!ar.isStaticSite()) {
                String email = getEmail();
                if (email==null || email.length()==0) {
                    ar.write(" <img src=\"");
                    ar.write(ar.retPath);
                    ar.write("warning.gif\">");
                }
            }
            return;
        }

        boolean makeItALink = ar.isLoggedIn() && !ar.isStaticSite();
        MicroProfileRecord record = MicroProfileMgr.findMicroProfileById(rawAddress);
        if (record != null) {
            record.writeLink(ar);
            return;
        }

        MicroProfileRecord.writeSpecificLink(ar, SectionUtil.cleanName(getName()),
                rawAddress,  makeItALink);
    }

    /**
     * Make a link to this to provide information about the person
     */
    public String getLinkUrl() throws Exception {
        if (user!=null) {
            return "v/FindPerson.htm?uid="+URLEncoder.encode(user.getKey(), "UTF-8");
        }
        else {
            return "v/FindPerson.htm?uid="+URLEncoder.encode(rawAddress, "UTF-8");
        }

    }



    public boolean isRoleRef() {
        return isRole;
    }

    public void setRoleRef(boolean newVal) {
        isRole = newVal;
    }


    public String getStorageRepresentation() {
        String memberID = getUniversalId();
        if (isRoleRef()) {
            memberID = "%"+memberID;
        }
        return memberID;
    }
    public static AddressListEntry newEntryFromStorage(String roleName)
    {
        String actualName = roleName;
        boolean isRole = false;
        if (roleName.startsWith("%"))
        {
            actualName = roleName.substring(1);
            isRole = true;
        }
        AddressListEntry retval = new AddressListEntry(actualName);
        retval.setRoleRef(isRole);
        return retval;
    }

    public UserProfile getUserProfile() {
        return user;
    }
    
    public boolean hasLoggedIn() {
        return (user!=null && user.getLastLogin() > 100000);
    }


    public static void sortByName(List<UserRef> list)
    {
        Collections.sort(list, new UserRefComparator());
    }


    static class UserRefComparator implements Comparator<UserRef>
    {
        public UserRefComparator() {}

        public int compare(UserRef o1, UserRef o2)
        {
            String name1 = o1.getName();
            String name2 = o2.getName();
            return name1.compareToIgnoreCase(name2);
        }
    }

    public boolean hasAddressMatchingFrag(String frag) {
        if(user != null){
            return user.hasAddressMatchingFrag(frag);
        }else{
            if(getName().toLowerCase().contains(frag) || getUniversalId().toLowerCase().contains(frag)){
                return true;
            }
        }
        return false;
    }

    /**
    * If the address was supplied with a name AND and address,
    * then this method will return the name part.
    * If not, returns null.
    *
    * For example, some email addresses look like:
    *      "Tom Jones"  <tom.jones@example.com>
    *
    * This will be properly parsed, and the email address /
    * universal ID will be just the email address, but to get
    * the name that comes before that, use this method.
    */
    public String getNamePart() {
        return namePart;
    }

    /**
    * See #getNamePart().  This method allows you to force a
    * name part into the address list entry.
    */
    public void setNamePart(String newName) {
        this.namePart = newName;
    }


    /**
    * Give this method a 'combined' address, that contains both a
    * user name and email address.  This will correctly parse the
    * two out, and return an AddressListEntry object that contains
    * both.
    */
    public static AddressListEntry parseCombinedAddress(String nameAddress)
    {
        //first check for the laquo and raquo case.  This is NOT
        //standard, but it is easier to deal with in HTML code
        int braketStart = nameAddress.lastIndexOf(LAQUO);
        int braketEnd   = nameAddress.lastIndexOf(RAQUO);

        //next, look for the normal angle brackets as per standard
        if (braketStart < 0 || braketEnd < 0) {
            braketStart = nameAddress.lastIndexOf('<');
            braketEnd   = nameAddress.lastIndexOf('>');
        }

        //if there is no angle brackets, then just return normal ALE
        if (braketStart<0 || braketEnd<braketStart) {
            return new AddressListEntry(nameAddress);
        }

        String beforePart = nameAddress.substring(0, braketStart).trim();
        String emailPart  = nameAddress.substring(braketStart+1, braketEnd).trim();

        AddressListEntry ale = new AddressListEntry(emailPart);
        ale.setNamePart(beforePart);
        return ale;
    }


    /**
     * In some cases we use email addresses with laquo and raquo demarking
     * the name.  This cleans that up, and uses angle brackets instead.
     */
    public static String cleanQuotes(String eAddress) throws Exception {

        //clean out legacy use of LAQUO and RAQUO to delimit user names.
        //hopefully not doing this any more anywhere.
        int braketStart = eAddress.lastIndexOf(LAQUO);
        int braketEnd   = eAddress.lastIndexOf(RAQUO);
        if (braketStart >= 0 && braketEnd >= 0) {
            if (braketStart < 0) {
                throw WeaverException.newBasic("Got an address with only an end raquo char -- the address should have both start and end, or none");
            }
            if (braketEnd < 0) {
                throw WeaverException.newBasic("Got an address with only a start laquo char -- the address should have both start and end, or none");
            }
            if (braketEnd <= braketStart) {
                throw WeaverException.newBasic("Got an address with laquo and raquo in the wrong order");
            }
            eAddress =  eAddress.substring(0, braketStart) + '<' + eAddress.substring(braketStart+1, braketEnd) + '>';
        }

        //also eliminate any quote characters that might exist
        if (eAddress.indexOf("\"")>=0) {
            //we have to get rid of all the double quotes as well, replace them with spaces
            //for the email that is actually being sent.
            eAddress = eAddress.replace('\"', ' ');
        }
        return eAddress;
    }

    /**
    * Given a string that contains a comma delimited list of email addresses
    * this will parse the addresses out, and write links for every address.
    */
    public static void writeParsedLinks(AuthRequest ar, String addressList)
        throws Exception
    {
        List<AddressListEntry> list = parseEmailList(addressList);
        boolean needsComma = false;
        for (AddressListEntry ale : list)
        {
            if (needsComma)
            {
                ar.write(", ");
            }
            ale.writeLink(ar);
            needsComma = true;
        }
    }


    /**
    * Given a string with email addresses (or openids) separated by either commas
    * semicolons, or carriage returns, this will parse the list, and return a
    * vector of AddressListEntry objects.
    */
    public static List<AddressListEntry> parseEmailList(String addressList)
        throws Exception
    {
        List<AddressListEntry> res = new ArrayList<AddressListEntry>();

        int start = 0;
        while (start < addressList.length())
        {
            int commaPos = addressList.indexOf(',', start);
            int semiPos = addressList.indexOf(';', start);
            int nlPos = addressList.indexOf('\n', start);
            int min = addressList.length();
            if (commaPos>start && commaPos<min)
            {
                min = commaPos;
            }
            if (semiPos>start && semiPos<min)
            {
                min = semiPos;
            }
            if (nlPos>start && nlPos<min)
            {
                min = nlPos;
            }

            String frag = addressList.substring(start, min).trim();
            if (frag.length()>0)
            {
                res.add( parseCombinedAddress(frag) );
            }
            start = min+1;
        }

        return res;
    }


    /**
     * Convert a list of string values into a list of address list entry objects
     */
    public static List<AddressListEntry> toAddressList( List<String> uidList ) {
        List<AddressListEntry> res = new ArrayList<AddressListEntry>();
        for (String uid : uidList) {
            res.add(new AddressListEntry(uid));
        }
        return res;
    }
    public static List<String> fromAddressList( List<AddressListEntry> addressList ) {
        List<String> res = new ArrayList<String> ();
        for (AddressListEntry ale : addressList) {
            res.add(ale.getUniversalId());
        }
        return res;
    }
    /**
     * Takes an array of user object, each user object with key, uid, and name
     */
    public static List<String> uidListfromJSONArray( JSONArray inputArray ) throws Exception {
        List<String> uids = new ArrayList<String>();
        for (JSONObject oneEntry : inputArray.getJSONObjectList()) {
            String email = oneEntry.getString("uid");
            AddressListEntry ale = new AddressListEntry(email);
            String betterEmail = ale.getUniversalId();
            if (!uids.contains(betterEmail)) {
                uids.add(betterEmail);
            }
        }
        return uids;
    }

    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("uid", getUniversalId());
        String name = getName();
        if (name == null || name.length()==0) {
            name = this.getUniversalId();
        }
        jObj.put("name", name);
        if (user!=null) {
            jObj.put("key", user.getKey());
        }
        else {
            //if this is a bare email address, use the email as the key
            jObj.put("key", getUniversalId());
        }
        return jObj;
    }

    public static AddressListEntry fromJSON(JSONObject jObj) throws Exception {
        if (jObj.has("name")) {
            String name = jObj.optString("name");
            if (jObj.has("uid")) {
                return new AddressListEntry(jObj.getString("uid"), name);
            }
            else {
                return new AddressListEntry(name);
            }
        }
        if (jObj.has("uid")) {
            return new AddressListEntry(jObj.getString("uid"));
        }
        throw WeaverException.newBasic("Unable to parse JSON for user address because neither 'uid' nor 'name' are present.");
    }

    public static JSONArray getJSONArrayFromIds(List<String> idList) throws Exception {
        JSONArray array = new JSONArray();
        for (String id : idList) {
            AddressListEntry ale = new AddressListEntry(id);
            array.put(ale.getJSON());
        }
        return array;
    }
    public static JSONArray getJSONArray(List<AddressListEntry> addressList) throws Exception {
        JSONArray array = new JSONArray();
        for (AddressListEntry ale : addressList) {
            array.put(ale.getJSON());
        }
        return array;
    }

    public static void addIfNotPresent(List<AddressListEntry> addressList,
            AddressListEntry newMember) throws Exception {
        for (AddressListEntry one : addressList) {
            if (one.equals(newMember)) {
                return;
            }
        }
        addressList.add(newMember);
    }


}
