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

package com.purplehillsbooks.weaver.rest;

import java.util.Timer;
import java.util.TimerTask;

import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.SectionUtil;

import com.purplehillsbooks.json.JSONException;

/**
 * Implements the server initialization protocol.  The variable "serverInitState" tells
 * what the current state of the entire server initialization.  All other services should
 * look at this state variable, and only proceed with regular functions when the server
 * is in the STATE_RUNNING state.
 *
 * When the server is in any other state, normal user-oriented requests should not be handled.
 * User requests at those times should be forwarded to a simple page that announces only
 * that the server is still starting up.  This prevents the problem that a user request
 * might occur before the server is completely initialized.
 *
 * Some failures of the server might cause the server to re-initialize, so other parts of the
 * system should never assume that because they encountered the RUNNING state, that it will
 * always remain in the running state.
 *
 * The state variable starts in the INITIAL state, but that is immediately changed to the
 * TESTING state.
 *
 * During TESTING, the server attempts to read the config files and initialize all the
 * proper internal variable.  This may involve contacting external servers that it depends
 * on to make sure they are there.   This will either transition to RUNNING or to FAILED
 *
 * In the FAILED state, the server will not serve any end-user request, but will allow the
 * administrator to restart initialization.  The server will rest in FAILED state for
 * about 30 seconds, and then will automatically try to initialize again.  This way, if
 * there was some temporary reason that the server could not start (e.g. it needed another
 * service that had not completed its start up yet), this will eventually allow it to start.
 *
 * RUNNING state is where the server spends most of the time, and it is where the end-user
 * requests are handled.
 *
 * PAUSED state is essentially for shutting down properly.  The server should enter the PAUSED
 * state for about 30 second before actually stopping.  This allows all the current request
 * to be cleanly handled, but no further requests to be started in that time.  This might also
 * be used to re-initialize the server, go into PAUSED state for 30 seconds, before going
 * and reinitializing the entire server from config files again.
 *
 * This class is purely to implement this protocol.  It is fundamentally a thread that will
 * check on the state every 30 seconds.  If that thread finds the server in the FAILED
 * state, it will attempt to reinitialize it, possibly returning it to the FAILED state,
 * but also possibly transitioning into the running state.
 */
public class ServerInitializer extends TimerTask {


    public static final int STATE_INITIAL = 0;
    public static final int STATE_TESTING = 1;
    public static final int STATE_FAILED  = 2;
    public static final int STATE_PAUSED  = 3;
    public static final int STATE_RUNNING = 4;

    /**
     * Take great care with the serverInitState.
     * It MUST be initialized (statically) to STATE_INITIAL
     * and that means it is a brand new object, nothing done
     *
     * Then it starts initialization by setting the FAILED
     * status ... in case an exception is thrown.  FAILED is
     * a permanent status, and it means something is wrong
     * beyond the ability of the server to correct.
     *
     * If the server gets up and running, but notices that a
     * resource (like another server) that it needs is not
     * available, then it can go into TESTING state.
     * It is not running, but it will continue to retry
     * those resources, and when everything is available
     * it goes into RUNNING.
     *
     * When it succeeds in initializing, it goes to RUNNING
     *
     * While RUNNING, if it notices that one of those external
     * resources has gone down, it should return to TESTING
     * mode.  Once they are all available again it can return
     * to RUNNING.
     *
     * When it is running, it can be PAUSED and subsequently resumed
     * under administrator control.
     */
    public int serverInitState = STATE_INITIAL;

    private Cognoscenti  cog;
    public Exception lastFailureMsg = null;
    public long lastInitAttemptTime = 0;

    private Timer timerForOtherTasks = null;
    private Timer timerForInit = null;


    /**
     * Creates an instance of the initializer, and also sets the
     * timer to call it at 30 second intervals.
     */
    public ServerInitializer(Cognoscenti _cog) {
        cog = _cog;
        serverInitState = STATE_FAILED;

        timerForInit = new Timer("Initialization Timer", true);
        timerForInit.scheduleAtFixedRate(this, 30000, 30000);
    }

    /**
     * Convenience routine will return true if the server is currently reading the config
     * file, and initializing.  You will only see this if initialization takes a long time,
     * or if you are extremely lucky.
     */
    public boolean isActivelyStarting() {
        return serverInitState == STATE_TESTING;
    }

    /**
     * puts the server into the PAUSED state.
     * You should delay for an additional time (30 seconds) before
     * doing anything else to the server to all all the other threads
     * to complete what they are doing.
     */
    public void pauseServer() {
        serverInitState = STATE_PAUSED;

        //cancel all the background processing from this existing timer
        if (timerForOtherTasks!=null) {
            timerForOtherTasks.cancel();
        }
        timerForOtherTasks = null;
        cog.isInitialized = false;
        System.out.println("COG SERVER CHANGE - New state "+getServerStateString());
    }

    /**
     * Takes the server from the PAUSED mode and attempts to reinitialize it.
     * Results in server in either RUNNING mode or FAILED mode.
     * @return
     */
    public void reinitServer() {
        if (serverInitState != STATE_PAUSED) {
            pauseServer();
        }
        serverInitState = STATE_FAILED;
        run();
        System.out.println("COG SERVER CHANGE - New state "+getServerStateString());
    }

    public synchronized void run() {
        // System.out.println("ServerInitializer started on thread: "+Thread.currentThread().getName() + " -- " + SectionUtil.currentTimestampString());
        //any non-FAILED state, there is nothing to do, so exit quick as possible
        //this get hit every 30 seconds or so while running.
        if (serverInitState != STATE_FAILED) {
            return;
        }

        System.out.println("COG SERVER INIT - Starting state ("+getServerStateString()+") at "+SectionUtil.currentTimestampString());
        //only if it is in FAILED state, it should attempt to reinitialize everything.
        //Init fails if any init method throws an exception

        try {
            NGPageIndex.assertNoLocksOnThread();
            serverInitState = STATE_TESTING;
            lastInitAttemptTime = System.currentTimeMillis();

            //I don't know if this is needed.  Basically, you should never be in this
            //situation, but it makes sense to clean things up before restarting.
            if (timerForOtherTasks!=null) {
                timerForOtherTasks.cancel();
            }
            timerForOtherTasks = new Timer("Main Cog Background Timer", true);

            //start by clearing everything ... in case there is mess left over.
            cog.clearAllStaticVariables();

            //garbage collect at this time, cleans out the heap space
            //freeing up and defragmenting memory
            System.gc();

            cog.initializeAll(timerForOtherTasks);

            serverInitState = STATE_RUNNING;
            System.out.println("ServerInitializer: successfully initialized and ready");
            lastFailureMsg = null;
        }
        catch (Exception e) {
            lastFailureMsg = e;
            serverInitState = STATE_FAILED;
            try {
                System.out.println("ServerInitializer: (FAILED) because "+e.toString());
                JSONException.traceException(System.out, e, "ServerInitializer: (FAILED)");
                if (timerForOtherTasks!=null) {
                    timerForOtherTasks.cancel();
                }
                timerForOtherTasks = null;
                cog.clearAllStaticVariables();
            }
            catch (Exception eee) {
                //just ignore this failure to report the real exception and cleanup
            }
        }
        finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        System.out.println("COG SERVER INIT - Concluding state "+getServerStateString());
    }

    public void shutDown() {
        System.out.println("STOP - ServerInitializer shutdown, killing timers");
        System.err.println("\n=======================\nSTOP - ServerInitializer shutdown, killing timers");
        timerForInit.cancel();
        timerForOtherTasks.cancel();
    }

    public String getServerStateString() {
        if (serverInitState==STATE_RUNNING) {
            return "Running";
        }
        if (serverInitState==STATE_FAILED) {
            return "Failed";
        }
        if (serverInitState==STATE_PAUSED) {
            return "Paused";
        }
        if (serverInitState==STATE_INITIAL) {
            return "Initial";
        }
        if (serverInitState==STATE_TESTING) {
            return "Testing";
        }
        return "Unknown";
    }
}
