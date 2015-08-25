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

import java.io.PrintWriter;
import java.util.Date;
import java.util.TimerTask;

import org.socialbiz.cog.exception.NGException;

public class SendEmailThread extends TimerTask {
    Cognoscenti cog;

    public SendEmailThread(Cognoscenti _cog) {
        cog = _cog;
    }

    public void run() {
        try {
            String pageKey;

            //walk through the known pages and see if there are any email
            //messages there to send
            while ((pageKey=cog.getPageWithEmailToSend()) != null) {

                //START first transaction here
                NGPage possiblePage =  cog.getProjectByKeyOrFail(pageKey);
                EmailRecord eRec=possiblePage.getEmailReadyToSend();
                if (eRec==null) {
                    cog.removePageFromEmailToSend(pageKey);
                }
                else {
                    String id = eRec.getId();
                    eRec.prepareForSending(possiblePage);
                    NGPageIndex.clearLocksHeldByThisThread();
                    Exception exHolder = null;

                    try {
                        //this is done while not holding any locks .... important because some servers are slow
                        EmailSender.sendPreparedMessageImmediately(eRec, cog);
                    }
                    catch (Exception whatWentWrong) {
                        exHolder = whatWentWrong;
                    }

                    //START the second transaction to update that the message has been sent
                    possiblePage =  cog.getProjectByKeyOrFail(pageKey);
                    eRec=possiblePage.getEmail(id);

                    if (exHolder==null) {
                        eRec.setErrorMessage(null);
                        eRec.setStatus(EmailRecord.SENT);
                    }
                    else {
                        eRec.setErrorMessage(NGException.getFullMessage(exHolder));
                        eRec.setStatus(EmailRecord.FAILED);
                    }
                    possiblePage.save();
                    eRec.setLastSentDate(System.currentTimeMillis());
                }
                //let go of locks from that or any other pages at this time before looping back
                NGPageIndex.clearLocksHeldByThisThread();

                //This is a background task, so give others the chance to get in.  Don't hog the lock.
                Thread.sleep(5000);
            }

            //This is the old, deprecated way to store email messages in the
            //for sending later in a single global store.
            if (EmailRecordMgr.getEmailReadyToSend() != null) {
                //EmailSender.sendPreparedMessageImmediately(eRec);
                //EmailRecordMgr.save();
                throw new Exception("Deprecated EmailRecordMgr.getEmailReadyToSend is still being used?");
            }

        }
        catch (Exception e) {

            //need to save the message that was marked as having failed to send
            //TODO: not sure that this is the right thing to do
            try {
                System.out.println("\nSendEmailThread: "+new Date().toString()+"\n");
                System.out.println("\nSendEmailThread Exception: "+NGException.getFullMessage(e)+"\n");
                System.out.println("\nSendEmailThread Stack Trace------------------\n");
                e.printStackTrace(new PrintWriter(System.out));
                System.out.println("\n-----------------------------\n");
                EmailRecordMgr.save();
            }
            catch (Exception dead) {
                //what can we do here?
            }

        }
        finally {
            //only call this when you are sure you are not holding on to any containers
            NGPageIndex.clearLocksHeldByThisThread();
        }
    }

}
