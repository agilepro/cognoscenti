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

/**
* This is a class that produces multi level numbers like this:
*
*  1.               L0
*  2.               L0
*  2.1              L1
*  2.2              L1
*  3.               L0
*  3.1              L1
*  3.1.1            L2
*  3.1.2            L2
* etc.
*
* Each request is made by asking for the next number, AT A PARTICULAR LEVEL.
* The numbers on the right represent the level of number that was asked for.
* The first call is for a number at level 0, then next at level 0 again.
* The third request is for a number at level 1.  In this case it leaves the
* top level 0 number the same, but increments the next level, and returns a
* two digit number.
*
* All you need to know is the level (depth) of the thing being numbered, and
* this will return the correct next number for that level.
*/

class MultiLevelNumber
{
    int[] tracker = new int[20];

    public MultiLevelNumber() {
        for (int i=0; i<20; i++) {
            tracker[i] = 0;
        }
    }


    /**
    * Top level number is level 0.
    * Specify the level, and a combined number is returned
    */
    public String nextAtLevel(int level) {
        if (level<0 || level>=20) {
            throw new RuntimeException("nextAtLevel can not handle more than level 19");
        }

        //increment the number at the specified level
        tracker[level]++;

        //zero all the numbers for higher levels
        for (int i=level+1; i<20; i++) {
            tracker[i] = 0;
        }

        //now generate the string value
        StringBuffer seq = new StringBuffer();
        for (int i=0; i<=level; i++) {
            seq.append(Integer.toString(tracker[i]));
            seq.append(".");
        }
        return seq.toString();
    }
}
