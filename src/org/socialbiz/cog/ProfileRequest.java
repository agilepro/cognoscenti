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

import java.io.StringWriter;
import java.net.URLEncoder;

import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
* ProfileRequest contains a request from a user to manipulate the profile
* information, but it can not be done in a single step for authentication
* reasons.  Instaed step one is to write down this information, and step
* two is after the email has been confirmed received, to take action.
*
* 1. Reset Password.  The user has forgotten the password, but still remembers
* the email address.  From email address we locate the user, verify that that
* is the primary email address for the user, and send a message to that address
* with the security token in it.  When the user receives the token, that confirms
* that they own the address, and that they are the user in question. So the user
* is logged in and alowed to change the user password.
* Requires: userkey, security token, timestamp
*
* 2. Add Email.  A user is logged in and wants to add a new email message to
* the profile.  We don't do this until we can prove that he owns the address.
* Create a ProfileRequest with a security token, email the security token to
* the new address.  When the user clicks on the link, AND if they are logged in
* as the specified user, then the email is added to the user.
* Requires: userkey, security token, new email, timestamp
*
* 3. Create Profile.  User does not have a profile.  They must provide an
* email address for this.  A Profile Request is created in a global space.
* the security token is emailed to that address.  When the user clicks on the
* link, the empty pofile is created with that email address in it.
* Requires: security token, new email, timestamp
*
*/
public class ProfileRequest extends DOMFace
{
    public static int RESET_PASSWORD = 1;
    public static int ADD_EMAIL      = 2;
    public static int CREATE_PROFILE = 3;


    public ProfileRequest(Document doc, Element definingElement, DOMFace p)
    {
        super (doc, definingElement, p);
    }

    /**
    * Must be unique within the context that this request is being stored
    * Usually unique in a leaf, or a user page.  This is not secret.
    */
    public String getId()
    {
        return getAttribute("id");
    }
    public void setId(String id)
    {
        setAttribute("id", id);
    }


    /**
    * Tells what kind of request it is
    * RESET_PASSWORD = 1;
    * ADD_EMAIL      = 2;
    * CREATE_PROFILE = 3;
    */
    public int getReqType()
    {
        return safeConvertInt(getAttribute("type"));
    }
    public void setReqType(int newType)
    {
        setAttribute("type", Integer.toString(newType));
    }


    /**
    * When a virtual attachments is created to be filled in, a person
    * is assigned to fill int he attachment, and reminders will be sent
    * until it is filled.
    */
    public String getUserKey()
    {
        return getAttribute("userkey");
    }
    public void setUserKey(String userkey)
    {
        setAttribute("userkey", userkey);
    }
    public boolean isForUser(UserProfile up)
    {
        return up.hasAnyId(getAttribute("userkey"));
    }

    /**
    * This is a global unique id designed simply to be hard to guess
    * This must be kept secret, never displayed in the user interface,
    * but sent in an email message in order to prove that they got the
    * email message.
    */
    public String getSecurityToken()
    {
        return getAttribute("token");
    }
    public void setSecurityToken(String token)
    {
        setAttribute("token", token);
    }


    /**
    * In some cases the profile does not exist, and the only
    * thing is an email address that the user is claiming
    * they own.  A request to create the profile is started using
    * only the email address and the security token.
    */
    public String getEmail()
    {
        return getAttribute("email");
    }
    public void setEmail(String email)
    {
        setAttribute("email", email);
    }


    /**
    * The time that the request was created, for use in timing out
    * the request after a period of time (24 hours).
    */
    public long getTimestamp()
    {
        return safeConvertLong(getAttribute("timestamp"));
    }
    public void setTimestamp(long timestamp)
    {
        setAttribute("timestamp", Long.toString(timestamp));
    }



    public static String getPromptString(int type)
        throws Exception
    {
        if (type==RESET_PASSWORD)
        {
            return "Reset Password";
        }
        if (type==CREATE_PROFILE)
        {
            return "Create New Profile";
        }
        if (type==ADD_EMAIL)
        {
            return "Add Email";
        }
        throw new ProgramLogicError("Asked for a prompt for an unknown value in ProfileRequest.java");
    }



    public void sendEmail(AuthRequest ar, String go)
        throws Exception
    {
        String option = getPromptString(getReqType());
        String registerAddr = ar.retPath+"t/confirmThroughMail.htm?email="+URLEncoder.encode(getEmail(), "UTF-8")
            +"&option="+URLEncoder.encode(option, "UTF-8")
            +"&mn="+URLEncoder.encode(getSecurityToken(), "UTF-8")
            +"&go="+URLEncoder.encode(go, "UTF-8");

        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
        clone.write("<html><body>\n");
        clone.write("<p>This message was sent automatically from an Avatar Console server for the purpose of: ");
        clone.writeHtml(option);
        clone.write(" for ");
        clone.writeHtml(getEmail());
        clone.write(".</p>\n");
        clone.write("<p>Click on <a href=\"");
        clone.writeHtml(registerAddr);
        clone.write("\">this link</a> or copy the following address into your browser:</p>");
        clone.write("<p>");
        clone.writeHtml(registerAddr);
        clone.write("</p>");
        clone.write("<p>You confirmation key is <b>");
        clone.writeHtml(getSecurityToken());
        clone.write("</b>.  You can enter this in to the confirmation key space on the confirmation page.</p>");
        clone.write("<p>If you did not request this operation, then it is possible");
        clone.write("   that someone else has entered your email by mistake, and you can");
        clone.write("   safely ignore and delete this message.</p>");
        clone.write("</body></html>");


        EmailSender.quickEmail(new OptOutIndividualRequest(AddressListEntry.parseCombinedAddress(getEmail())),
            null, option+" for "+getEmail(), bodyWriter.toString(), ar.getCogInstance());
    }



}
