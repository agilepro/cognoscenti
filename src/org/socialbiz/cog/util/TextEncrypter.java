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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.security.spec.KeySpec;
import java.util.Vector;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.DESKeySpec;
import javax.crypto.spec.DESedeKeySpec;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.workcast.streams.Base64;

/**
 * TextEncrypter handles the encruption of password in ini file
 */

public class TextEncrypter {
    public static final String DESEDE_ENCRYPTION_SCHEME = "DESede";
    public static final String DES_ENCRYPTION_SCHEME = "DES";
    public static final String DEFAULT_ENCRYPTION_KEY = "Need to encrypt IBPM password";
    private KeySpec keySpec;
    private SecretKeyFactory keyFactory;
    private Cipher cipher;
    private Vector<String> listOfKeys = new Vector<String>();

    private static final String UNICODE_FORMAT = "UTF-8";

    public TextEncrypter(String encryptionScheme) throws Exception {
        this(encryptionScheme, DEFAULT_ENCRYPTION_KEY);
    }

    public TextEncrypter(String encryptionScheme, String encryptionKey)
            throws Exception {
        populateKeys();
        if (encryptionKey == null) {
            throw new ProgramLogicError("Invalid Encryption key");
        }

        if (encryptionKey.trim().length() < 24) {
            throw new ProgramLogicError("Invalid Encryption key");

        }
        byte[] keyAsBytes = encryptionKey.getBytes(UNICODE_FORMAT);

        if (encryptionScheme.equals(DESEDE_ENCRYPTION_SCHEME)) {
            keySpec = new DESedeKeySpec(keyAsBytes);
        } else if (encryptionScheme.equals(DES_ENCRYPTION_SCHEME)) {
            keySpec = new DESKeySpec(keyAsBytes);
        } else {
            throw new ProgramLogicError("Invalid Encryption key");
        }

        keyFactory = SecretKeyFactory.getInstance(encryptionScheme);
        cipher = Cipher.getInstance(encryptionScheme);

    }

    public String encrypt(String unencryptedString) throws Exception {
        if (unencryptedString == null || unencryptedString.trim().length() == 0) {
            throw new ProgramLogicError("Invalid input text:" + unencryptedString);
        }
        SecretKey key = keyFactory.generateSecret(keySpec);
        cipher.init(Cipher.ENCRYPT_MODE, key);
        byte[] cleartext = unencryptedString.getBytes(UNICODE_FORMAT);
        byte[] ciphertext = cipher.doFinal(cleartext);

        return Base64.encode(ciphertext);
    }

    public String decrypt(String encryptedString) throws Exception {
        if (encryptedString == null || encryptedString.trim().length() <= 0) {
            throw new ProgramLogicError("Invalid input text:" + encryptedString);
        }
        SecretKey key = keyFactory.generateSecret(keySpec);
        cipher.init(Cipher.DECRYPT_MODE, key);
        byte[] cleartext = Base64.decodeBuffer(encryptedString);
        byte[] ciphertext = cipher.doFinal(cleartext);
        return new String(ciphertext, UNICODE_FORMAT);
    }

    public void updatePropFile(String fileName) throws Exception {
        File iniFile = new File(fileName);
        if (!iniFile.exists()) {
            throw new NGException("nugen.exception.file.invalid", new Object[]{fileName});
        }

        BufferedReader fileBr = new BufferedReader(new FileReader(iniFile));
        Vector<String> lineList = new Vector<String>();
        while (true) {
            String readLn = null;
            readLn = fileBr.readLine();
            if (readLn == null) {
                fileBr.close();
                break;
            }
            int srchIndex = 0;
            if ((srchIndex = readLn.indexOf("=")) != -1) {
                String key = readLn.substring(0, srchIndex).trim();
                if (listOfKeys.contains(key.toLowerCase())) {
                    String value = readLn.substring(srchIndex + 1).trim();
                    if (value == null || value.length() <= 0) {
                        lineList.add(readLn);
                    }
                    else {
                        String newL = encrypt(value);
                        newL = key + " = " + newL;
                        lineList.add(newL);
                    }
                }
                else {
                    lineList.add(readLn);
                }
            } else {
                lineList.add(readLn);
            }
        }
        // now open the same file for writing and write the resultant
        // StringBuffer to the file.
        if (lineList.size() > 0) {
            BufferedWriter fileBw = new BufferedWriter(new FileWriter(iniFile));
            for (int i = 0; i < lineList.size(); i++) {
                fileBw.write(lineList.get(i));
                fileBw.newLine();
            }
            fileBw.close();
        }
    }

    private void populateKeys() {
        // AE Keys
        listOfKeys.add("twfserverpassword");
        listOfKeys.add("dbaloginpassword");
        listOfKeys.add("defaultasappassword");

        // EE Keys
        listOfKeys.add("serverpassword");
        listOfKeys.add("oraclepassword");
        listOfKeys.add("iflowdbpassword");

        // Common Keys
        listOfKeys.add("ldapaccessuserpassword");
        listOfKeys.add("swaplinkagepassword");
        listOfKeys.add("smtppassword");
        listOfKeys.add("smsaccesspassword");
        listOfKeys.add("uddipublisherpassword");
        listOfKeys.add("metadatarepositorypassword");

        // PPM Password
        listOfKeys.add("password");
    }

    public static void main(String[] args) {

        if (args == null || args.length < 2) {
            printMessage();
            System.exit(0);
        }
        try {
            TextEncrypter tEncryp = null;
            String encryptionScheme = DESEDE_ENCRYPTION_SCHEME;
            if (args.length > 3) {
                encryptionScheme = args[3];
            }
            if (args.length > 2) {
                tEncryp = new TextEncrypter(encryptionScheme, args[2]);
            } else {
                tEncryp = new TextEncrypter(encryptionScheme);
            }
            if (args[0].equalsIgnoreCase("-e")) {
                String value = args[1].trim();
                value = tEncryp.encrypt(args[1]);
                System.out.println(value);
            } else if (args[0].equalsIgnoreCase("-f")) {
                tEncryp.updatePropFile(args[1]);
                System.out.println("Updated ini File " + args[1]);
            } else if (args[0].equalsIgnoreCase("-efd")) {
                String value = args[1].trim();
                value = tEncryp.decrypt(value);
                System.out.println(value);
            } else {
                System.out
                        .println("Failed to encrypt. Please check the input parameters.");
                printMessage();
                System.exit(0);
            }

        } catch (Exception e) {
            System.out.println("Exception occured: " + e.toString());
            System.exit(1);
        }

    }

    private static void printMessage() {
        System.out
                .println("usage : java TextEncrypter -e StringToEncrypt EncryptionKey EncryptionScheme");
        System.out.println("      OR     ");
        System.out
                .println("usage : java TextEncrypter -f iniFileWithPath EncryptionKey EncryptionScheme");
        System.out
                .println("NOTE: EncryptionKey key should be minimum 24 characters.");
        System.out
                .println("NOTE: Supported EncryptionScheme is \"DESede\"  and \"DES\"");
    }

}