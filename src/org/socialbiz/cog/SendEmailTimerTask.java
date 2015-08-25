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

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ArrayBlockingQueue;

public class SendEmailTimerTask extends TimerTask {

    private final static long EVERY_TWO_HOURS = 1000*60*60*2;

    public static Exception threadLastCheckException = null;

    private SendEmailTimerTask() throws Exception{
        EmailRecordMgr.initializeEmailRecordMgr();
    }

    public static void initEmailSender(Timer timer) throws Exception
    {
        SendEmailTimerTask sendEmailObj = new SendEmailTimerTask();
        timer.scheduleAtFixedRate(sendEmailObj, 60000, EVERY_TWO_HOURS);
    }

    @Override
    public void run() {
        try
        {
            //I am not sure why we have to do this, and why we need this class in the first place
            //since there is another class 'SendEmailThread' that does the same thing.
            EmailRecordMgr.triggerNextMessageSend();
        }
        catch(Exception e)
        {
            Exception failure = new Exception("Failure in the SendEmail thread run method. Thread died.", e);
            failure.printStackTrace();
            threadLastCheckException = failure;
        }
    }



    public static ArrayBlockingQueue<EmailRecord> blq = new ArrayBlockingQueue<EmailRecord>(1000);

}
