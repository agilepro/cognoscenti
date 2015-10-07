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

package org.socialbiz.cog.spring;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;

@Controller
public class LoginController extends BaseController {




    @Autowired
    public void setContext(ApplicationContext context) {
//        this.context = context;
    }


/*
    public ConsumerManager getConsumerManager(HttpSession session) throws Exception
    {
        ConsumerManager cm = (ConsumerManager) session.getServletContext().getAttribute("consumermanager");
        if (cm == null)
        {
            cm = SSLPatch.newConsumerManager();
            session.getServletContext().setAttribute("consumermanager", cm);
        }
        return cm;
    }
*/
    
    
/*
    @RequestMapping(value = "/openIdLogin.htm", method = RequestMethod.GET)
    public ModelAndView openIdLogin(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        request.setCharacterEncoding("UTF-8");
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        String uopenid = ar.reqParam("openid");    //id user trying to log in as
        String go      = ar.reqParam("go");        //when to go when successful
        String err     = ar.reqParam("err");       //where to go if it fails, adding a msg parameter
        String upKey   = ar.defParam("key", null); //optional: user profile this openid is being added to
        HttpSession session = request.getSession();

        uopenid = uopenid.trim();
        try
        {
            ConsumerManager manager = getConsumerManager(session);

            String returnToUrl = ar.baseURL + "t/Cognoscenti.htm";

            session.setAttribute("login-page", go);
            session.setAttribute("login-err",  err);


            if (upKey!=null)
            {
                session.setAttribute("user-profile-key", upKey);
            }

            List<?> discoveries = manager.discover(uopenid);
            if (discoveries==null) {
                throw new NGException("nugen.exception.client.manager.discover.null",null);
            }

            DiscoveryInformation discovered = manager.associate(discoveries);
            if (discovered==null) {
                throw new NGException("nugen.exception.client.manager.associate.null",null);
            }

            session.setAttribute("openid-disco", discovered);

            org.openid4java.message.AuthRequest authReq = manager.authenticate(discovered, returnToUrl);

            response.sendRedirect(authReq.getDestinationUrl(true));
        }
        catch (Exception e)
        {
            String msg = "Unable to verify the supplied OpenID ("+uopenid
            +").  This could be for a number of reasons.  It might be that "
            +"network connectivity to the open id provider is down, the server is off line "
            +"temporarily, or the OpenId was not entered correctly.Additional detail: "+e.toString();

            //error message from one page to another page is passed as a session attribute
            //so that it does not become a permanent part of the URL that the user can see
            session.setAttribute("error-msg", msg);
            response.sendRedirect(err);
        }
        return null;
    }
*/


}
