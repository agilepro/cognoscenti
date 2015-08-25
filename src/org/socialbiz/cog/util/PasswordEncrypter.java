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

package org.socialbiz.cog.util;


import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.util.Random;

public class PasswordEncrypter {
    // The higher the number of iterations the more
    // expensive computing the hash is for us
    // and also for a brute force attack.
    private static final int iterations = 10;
    private static final int saltLen = 32;
    private static final int desiredKeyLen = 256;

    /**
    * Computes a salted PBKDF2 hash of given plaintext password
    * suitable for storing in a database.
    */
    public static String getSaltedHash(String password) throws Exception {
        byte[] salt = SecureRandom.getInstance("SHA1PRNG").generateSeed(saltLen);
        // store the salt with the password
        return hexEncode(salt) + "$" + hash(password, salt);
    }

    /**
    * Checks whether given plaintext password corresponds
    * to a stored salted hash of the password.
    */
    public static boolean check(String password, String stored) throws Exception{
        String[] saltAndPass = stored.split("\\$");
        if (saltAndPass.length != 2) {
            return false;
        }
        String hashOfInput = hash(password, hexDecode(saltAndPass[0]));
        return hashOfInput.equals(saltAndPass[1]);
    }

    // using PBKDF2 from Sun, an alternative is https://github.com/wg/scrypt
    // cf. http://www.unlimitednovelty.com/2012/03/dont-use-bcrypt.html
    private static String hash(String password, byte[] salt) throws Exception {
        SecretKeyFactory f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        SecretKey key = f.generateSecret(new PBEKeySpec(
            password.toCharArray(), salt, iterations, desiredKeyLen)
        );
        return hexEncode(key.getEncoded());
    }

    /**
    * generates a hex code value using letters A=0 thru P=15
    */
    public static String hexEncode(byte[] byteArray) {
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<byteArray.length; i++) {
            int getRidOfByteSign = byteArray[i] + 256;
            sb.append( (char) (((getRidOfByteSign>>4) & 0x0F)+'A'));
            sb.append( (char) (((getRidOfByteSign) & 0x0F)+'A'));
        }
        return sb.toString();
    }

    /**
    * decodes a hex code value using letters A=0 thru P=15
    * other characters than these will cause spurious results, but no errors.
    */
    public static byte[] hexDecode(String hexDigits) {
        if (hexDigits.length()%2 !=0) {
            throw new RuntimeException("Can not decode an odd number of hex digits.  Something must be wrong");
        }
        int count = hexDigits.length()/2;
        byte[] res = new byte[count];
        for (int i=0; i<count; i++) {
            char ch1 = hexDigits.charAt(i*2);
            char ch2 = hexDigits.charAt(i*2 + 1);
            int v1= ch1-'A';
            int v2 =ch2-'A';
            res[i] = (byte) ((v1*16) + v2);
        }
        return res;
    }


    public static void testThis() {

        Random rand = new Random();
        byte[] initialTest = new byte[]{0,1,2,3,4};
        checkAndComplain(initialTest);
        for (int iteration=0; iteration<100; iteration++)  {
            byte[] testCase = new byte[20];
            for (int i=0; i<20; i++) {
                testCase[i] = (byte) (rand.nextInt(256)-128);
            }
            checkAndComplain(testCase);
        }
    }

    public static void checkAndComplain(byte[] possibleValue) {

        String middle = hexEncode(possibleValue);
        byte[] output = hexDecode(middle);

        for (int i=0; i<possibleValue.length; i++) {
            if (output[i]!=possibleValue[i]) {
                throw new RuntimeException("Value did not match at position '"+i+"' with test case "+middle);
            }
        }

    }
}