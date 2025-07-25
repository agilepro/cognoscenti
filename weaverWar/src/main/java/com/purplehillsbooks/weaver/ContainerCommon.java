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

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import com.purplehillsbooks.weaver.exception.WeaverException;

import org.w3c.dom.Document;

/**
* The three classes: NGWorkspace, NGBook, and UserPage are all DOMFile classes, and there
* are some methods that they can easily share.  This class is an abstract base class
* so that these classes can easily share a few methods.
*/
public abstract class ContainerCommon extends NGContainer
{
    DOMFace roleParent;
    DOMFace infoParent;


    public ContainerCommon(File path, Document doc) throws Exception
    {
        super(path, doc);
        roleParent   = getRoleParent();
        infoParent    = getInfoParent();
    }


    /**
     * Here is how schema version works.   Each major file object will declare what
     * the current schema version and set it here for saving in the file.
     * A file is ALWAYS written at the current schema version.
     *
     * Every time a file is read, all the schema upgrades are applied on reading, generally
     * in the constructor.  So the version of the file IN MEMORY is always the latest schema,
     * so you can always write out the memory and always the latest schema.
     *
     * But ... lots of files a read but not written.  So the file on disk might be many schema versions
     * behind.
     *
     * Before saving, if the schema had been out of date, then a
     * pass is made to touch all the sub-objects, and make sure that all objects are at the
     * current schema level.  Then the file is written.
     *
     * RULE FOR MANAGING VERSION
     * Every time any schema change is that requires schema update, the whole file schema
     * versions is incremented.  You must make sure that the schema update method touches
     * that component (with a constructor so that it is certain to be upgraded.  The we are
     * assured that the entire file is current and can be written.
     *
     * EXAMPLE
     * You have a file with schema version 68.
     * You make a change in the CommentRecord that requires a schema migration.
     * (1) You bump the schema version to 69.
     * (2) You make a comment that the CommentRecord change is what caused increment to 69.
     * (3) You make sure that the schemaUpgrade method touches (and upgrades) all comments.
     *
     * That is it.  The reason for making the comment is because in the future, we might be able
     * to determine that there no longer exist any files (anywhere in the world) with schema <= 68.
     * When that happens we will be able to remove the code that does the schema migration to 69.
     *
     * The next schema change, anywhere in the code, will bump the schema version to 70 and the
     * same assurances about making sure that schemaUpgrade touches the object in the right way.
     */
    public int getSchemaVersion()  {
        return getAttributeInt("schemaVersion");
    }
    /**
     * Only set schema version AFTER schemaUpgrade has been called and you know that the schema
     * is guaranteed to be up to date.
     */
    private void setSchemaVersion(int val)  {
        setAttributeInt("schemaVersion", val);
    }
    /**
     * The implementation of this must touch all objects in the file and make sure that
     * the internal structure is set to the latest schema.
     */
    abstract public void schemaUpgrade(int fromLevel, int toLevel) throws Exception;
    abstract public int currentSchemaVersion();

    public void save() throws Exception {
        int sv = getSchemaVersion();
        int current = currentSchemaVersion();
        if (sv<current) {
            schemaUpgrade(sv, current);
            setSchemaVersion(current);
        }
        super.save();
    }



    //these are methods that the extending classes need to implement so that this class will work
    public abstract String getUniqueOnPage() throws Exception;
    protected abstract DOMFace getRoleParent() throws Exception;
    protected abstract DOMFace getInfoParent() throws Exception;




    //////////////////// ROLES ///////////////////////



    public List<CustomRole> getAllRoles() throws Exception {
        return roleParent.getChildren("role", CustomRole.class);
    }

    /**
     * Gets a role by either the name or the symbol
     */
    public CustomRole getRole(String roleSymbol) throws Exception {
        for (CustomRole role : getAllRoles()) {
            if (roleSymbol.equals(role.getSymbol())) {
                return role;
            }
        }
        for (CustomRole role : getAllRoles()) {
            if (roleSymbol.equals(role.getName())) {
                return role;
            }
        }
        return null;
    }

    public CustomRole getRoleOrFail(String roleSymbol) throws Exception {
        CustomRole ret = getRole(roleSymbol);
        if (ret==null) {
            throw WeaverException.newBasic("Unable to locate a role with name '%s' on '%s'.", roleSymbol, getFullName());
        }
        return ret;
    }

    public CustomRole createRole(String roleSymbol, String description) throws Exception {
        if (roleSymbol==null || roleSymbol.length()==0) {
            throw WeaverException.newBasic("The name of a role can not be empty when creating the role.");
        }

        NGRole existing = getRole(roleSymbol);
        if (existing!=null) {
            throw WeaverException.newBasic("Can not create a new role, because there is already a role named '%s'", roleSymbol);
        }
        CustomRole newRole = roleParent.createChild("role", CustomRole.class);
        newRole.setScalar("rolename", roleSymbol);
        newRole.setDescription(description);
        return newRole;
    }

    public void deleteRole(String roleSymbol) throws Exception {
        NGRole role = getRole(roleSymbol);
        if (role!=null) {
            roleParent.removeChild((DOMFace)role);
        }
    }


    /**
    * just a shortcut for getRole(roleSymbol).addPlayer(newMember)
    */
    public void addPlayerToRole(String roleSymbol,String newMember) throws Exception
    {
        NGRole role= getRoleOrFail(roleSymbol);
        role.addPlayer(AddressListEntry.findOrCreate(newMember));
    }

    public List<NGRole> findRolesOfPlayer(UserRef user) throws Exception {
        List<NGRole> res = new ArrayList<NGRole>();
        if (user==null) {
            return res;
        }
        for (NGRole role : getAllRoles()) {
            if (role.isExpandedPlayer(user, this)) {
                res.add(role);
            }
        }
        return res;
    }


    ////////////////////// WRITE LINKS //////////////////////////


    public String trimName(String nameOfLink, int len) {
        if (nameOfLink.length()>len) {
            return nameOfLink.substring(0,len-1)+"...";
        }
        return nameOfLink;
    }

    protected void removeRoleIfEmpty(String roleName) throws Exception {
        NGRole role = getRole(roleName);
        if (role!=null && role.getDirectPlayers().size() == 0) {
            deleteRole(roleName);
        }
    }

    /**
    * get a role, and create it if not found.
    */
    public NGRole getRequiredRole(String symbol) throws Exception {
        NGRole role = getRole(symbol);
        if (role==null) {
            String desc = symbol+" of the workspace "+getFullName();
            String elegibility = "";
            if ("Executives".equals(symbol)) {
                desc = "The role 'Executives' contains a list of people who are assigned to the site "
                +"as a whole, and are automatically members of every workspace in that site.  ";
            }
            if ("Owners".equals(symbol)) {
                desc = "The role 'Owners' contains one or more people who take full responsibility "
                +"for the site as a whole both administratively and financially.  The site owner(s) "
                +"can add and remove anything from any workspace and ultimately decides when to terminate the site.";
            }
            role = createRole(symbol, desc);
            role.setRequirements(elegibility);
        }
        return role;
    }

    /**
    * The purpose of this, is to generate a unique magic number
    * for any given email id for this page.  Links to this
    * page could include this magic number, and it will allow
    * a person with that email address access to this page.
    * It will prove that they have been sent the magic number,
    * and proof that they received it, and therefor proof that
    * they own the email address.
    *
    * Pass the email address that you are sending to, and this will
    * return the magic number.   When the user clicks on the link
    * match the magic number in the link, with the magic number
    * generated here, to make sure they are not hacking their way in.
    *
    * The URL that the user clisk on must have BOTH the email address
    * and the magic number in it, because they are precisely paired.
    * Don't expect to get the email address from other part of
    * environment, because remember that email addresses are sometimes
    * transformed through the sending of the document.
    *
    * The magic number is ephemeral.  They need to last long enough
    * for someone to receive the email and click on the link,
    * so they have to last for days at least, probably weeks.
    * This algorithm generates a magic number that will last
    * permanently as long as the workspace lasts.  This is good because
    * there is no real way to migrate to a new algorithm for generating
    * the magic numbers.  But in practice
    * this algorithm might be changed at any time, causing discomfort
    * to those users that just received links, but presumably they
    * would soon receive new links with the new numbers in them.
    * There is no real requirement that the number last *forever*.
    */
    public String emailDependentMagicNumber(String emailId) throws Exception {
        String encryptionPad = getScalar("encryptionPad");
        if (encryptionPad==null || encryptionPad.length()!=30)
        {
            StringBuilder tmp = new StringBuilder();
            Random r = new Random();
            for (int i=0; i<30; i++)
            {
                //generate a random character >32 and <10000
                char ch = (char) (r.nextInt(9967) + 33);
                tmp.append(ch);
            }
            encryptionPad = tmp.toString();
            setScalar("encryptionPad", encryptionPad);
        }

        long chksum = 0;

        for (int i=0; i<30; i++)
        {
            char ch1 = encryptionPad.charAt(i);
            char ch2 = 'x';
            if (i < emailId.length())
            {
                ch2 = emailId.charAt(i);
            }
            int partial = ch1 ^ ch2;
            chksum = chksum + (partial*partial);
        }

        StringBuilder gen = new StringBuilder();

        while (chksum>0)
        {
            char gch = (char)('A' +  (chksum % 26));
            chksum = chksum / 26;
            gen.append(gch);
            gch = (char) ('0' + (chksum % 10));
            chksum = chksum / 10;
            gen.append(gch);
        }

        return gen.toString();
    }

    public String getContainerUniversalId() {
        //TODO: get rid of this static method use
        return Cognoscenti.getServerGlobalId() + "@" + getKey();

    }


    /**
    * Pages have a set of licenses
    */
    public List<License> getLicenses() throws Exception {
        List<LicenseRecord> vc = infoParent.getChildren("license", LicenseRecord.class);
        List<License> v = new ArrayList<License>();
        for (License child : vc) {
            v.add(child);
        }
        return v;
    }

    public License getLicense(String id) throws Exception {
        if (id==null || id.length()==0) {
            //silently ignore the null by returning null
            return null;
        }
        for (License child : getLicenses()) {
            if (id.equals(child.getId())) {
                return child;
            }
        }
        int bangPos = id.indexOf("!");
        if (bangPos>0) {
            String userKey = id.substring(0, bangPos);
            String token = id.substring(bangPos+1);
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            if (!token.equals(up.getLicenseToken())) {
                throw WeaverException.newBasic("License token does not match for user: %s", token);
            }
            return new LicenseForUser(up);
        }
        return null;
    }

    public boolean removeLicense(String id) throws Exception {
        List<LicenseRecord> vc = infoParent.getChildren("license", LicenseRecord.class);
        for (LicenseRecord child : vc) {
            if (id.equals(child.getId())) {
                infoParent.removeChild(child);
                return true;
            }
        }
        //maybe this should throw an exception?
        return false;
    }

    public License addLicense(String id) throws Exception {
        LicenseRecord newLement = infoParent.createChildWithID("license",
                LicenseRecord.class, "id", id);
        return newLement;
    }

    public boolean isValidLicense(License lr, long time) throws Exception {
        if (lr==null) {
            //no license passed, then not valid, handle this quietly so that
            //this can be used with getLicense operations.
            return false;
        }
        if (time>lr.getTimeout()) {
            return false;
        }

        AddressListEntry ale = AddressListEntry.findOrCreate(lr.getCreator());
        NGRole ngr = getRole(lr.getRole());
        if (ngr!=null) {
            //check to see if the user who created it, is still in the
            //role or in the member's role
            if (ngr.isExpandedPlayer(ale,  this)) {
                return true;
            }
        }
        if (primaryOrSecondaryPermission(ale)) {
            return true;
        }
        return false;
    }

}
