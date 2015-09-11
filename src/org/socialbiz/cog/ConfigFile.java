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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.List;
import java.util.Properties;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;

/**
 * Holds configuration settings
 */
public class ConfigFile {
    /**
     * This is the path to the WEB-INF folder where all config information lives
     */
    private File rootPath;
    private File webInfPath;

    /**
     * the name of the file that the properties are expected to be in
     */
    private File configFile = null;

    /**
     * This is where the properties are cached internally in memory when the
     * class is properly initialized.
     */
    private Properties props = null;


    /**
     * Given the path to a file within the application, this will return the
     * absolute File path object to access it.
     */
    public File getFileFromRoot(String filePath) {
        return new File(rootPath, filePath);
    }

    /**
     * Given a name of a configuration file, this will return the File object to
     * access it.
     */
    public File getFile(String fileName) {
        return new File(webInfPath, fileName);
    }

    /**
     * Initialize by passing in the root folder for the application.
     * This is expected to have a {root}/WEB-INF/config.txt file in there.
     * @param newRoot is the root of the web application
     * @throws Exception if anything is detected wrong with the configuration
     */
    public static ConfigFile initialize(File newRoot) throws Exception {
        ConfigFile mySingleton = new ConfigFile();
        mySingleton.init(newRoot);
        return mySingleton;
    }

    private void init(File newRoot) throws Exception {
        try {
            rootPath = newRoot;
            if (!rootPath.exists()) {
                //this is just paranoia, should never happen
                throw new Exception("Something is very wrong with the server ... "+
                     "the root of the application is not being retrieved correctly from the "+
                     "servlet contxt object.  Something is wrong with the TomCat server.");
            }
            webInfPath = new File(rootPath,"WEB-INF");
            if (!webInfPath.exists()) {
                //this is just paranoia, should never happen
                throw new Exception("Something is very wrong with the server ... "+
                     "the WEB-INF folder is not being found from the "+
                     "servlet contxt object.  Something is wrong with the TomCat server.");
            }
            configFile = getFile("config.txt");

            if (!configFile.exists()) {
                //this is probably a new installation.  copy the example config file
                File exampleConfigFile = getFile("config_example.txt");
                if (exampleConfigFile.exists()) {
                    UtilityMethods.copyFileContents(exampleConfigFile,configFile);
                }

                //while we are at it, copy the ssofi config as well
                File ssofiConfig = getFile("ssofi.config");
                File exampleSsofiConfig = getFile("ssofi_example.config");
                if (!ssofiConfig.exists() && exampleSsofiConfig.exists()) {
                    UtilityMethods.copyFileContents(exampleSsofiConfig,ssofiConfig);
                }

                //while we are at it, copy the email config as well
                File emailConfig = getFile("EmailNotification.properties");
                File exampleEmailConfig = getFile("EmailNotification_example.properties");
                if (!emailConfig.exists() && exampleEmailConfig.exists()) {
                    UtilityMethods.copyFileContents(exampleEmailConfig,emailConfig);
                }
            }

            initializeFromPath();
            MimeTypes.initialize(webInfPath);
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.configfile.initialization.fail", null, e);
        }
    }

    private void initializeFromPath() throws Exception {
        FileInputStream fis = new FileInputStream(configFile);
        Properties tprop = new Properties();
        tprop.load(fis);
        fis.close();
        props = tprop;
    }

    /**
     * Check whether this class has been initialized and can say anything about
     * the configuration parameters.
     */
    public boolean isInitialized() {
        return (props != null);
    }

    /**
     * getConfigProperties will return the configuration properties installed in
     * WEB-INF/config.txt. Complains if it can not find such a file. This is the
     * static version. Will never return null.
     */
    public Properties getConfigProperties() throws Exception {
        if (props == null) {
            // this will only happen if the server is not initializing classes
            // in the right order
            // so no reason to translate.
            throw new NGException("nugen.exception.unable.to.read.config.properties", null);
        }
        return props;
    }

    public String getProperty(String name) {
        if (props == null) {
            return null;
        }
        return props.getProperty(name);
    }

    /**
     * Returns an array of strings from a configuration settings which is
     * SEMICOLON delimited. That is, the config value is a list of values
     * separated by semicolons. The values can not themselves have semicolons in
     * them. This method will split them and return a proper array.
     */
    public String[] getArrayProperty(String name) {
        if (props == null) {
            return null;
        }
        String list = props.getProperty(name);
        if (list == null) {
            return new String[0];
        }
        String[] vals = UtilityMethods.splitOnDelimiter(list, ';');
        return vals;
    }

    /**
     * Set a ConfigFile property. Pass a null to clear a setting.
     */
    public void setProperty(String name, String value) throws Exception {
        if (props == null) {
            throw new NGException("nugen.exception.configfile.not.initialized", null);
        }
        if (value == null) {
            props.remove(name);
        }
        else {
            props.setProperty(name, value);
        }
    }

    public void save() throws Exception {
        if (props == null) {
            throw new NGException("nugen.exception.configfile.not.initialized", null);
        }
        saveConfigFile(props);
    }

    private void saveConfigFile(Properties nProp) throws Exception {
        if (nProp == null) {
            throw new ProgramLogicError(
                    "Call was made to 'saveConfigFile' with null properties object");
        }
        if (configFile == null) {
            throw new ProgramLogicError(
                    "Can not save properties when config file path has not been initialized.");
        }
        FileOutputStream fos = new FileOutputStream(configFile);
        nProp.store(fos, "Configured using ConfigFile.saveConfigFile");
        fos.close();
        initializeFromPath();
    }

    /**
     * Checks that the supplied path exists, and that it is a directory. Throws
     * standard errors if it is not.
     */
    public File getFolderOrFail(String folderPath) throws Exception {
        File root = new File(folderPath);
        if (!root.exists()) {
            throw new NGException("nugen.exception.root.dir.does.not.exist",
                    new Object[] { folderPath });
        }
        if (!root.isDirectory()) {
            throw new NGException("nugen.exception.root.dir.must.be.folder",
                    new Object[] { folderPath });
        }
        return root;
    }


    public void assertConfigureCorrectInternal() throws Exception {
        Properties props = getConfigProperties();

        getAttachFolderOrFail();
        getDataFolderOrFail();
        getUserFolderOrFail();
        getSiteFolders();

        String baseURL = props.getProperty("baseURL");
        if (baseURL==null) {
            throw new NGException("nugen.exception.system.configured.incorrectly",
                    new Object[] { "baseURL" });
        }
        String identityProvider = props.getProperty("identityProvider");
        if (identityProvider==null) {
            throw new NGException("nugen.exception.system.configured.incorrectly",
                    new Object[] { "identityProvider" });
        }
    }

    /**
     * Either return the valid File object to the path to the folder containing
     * user data, or fail throwing an exception that the server is not correctly
     * configured.
     */
    public File getUserFolderOrFail() throws Exception {
        return getGenericFolderOrFail("userFolder", "user");
    }
    public File getDataFolderOrFail() throws Exception {
        return getGenericFolderOrFail("dataFolder", "olddata");
    }
    public File getAttachFolderOrFail() throws Exception {
        return getGenericFolderOrFail("attachFolder", "oldattach");
    }
    public List<File> getSiteFolders() throws Exception {
        String[] libFolders = getArrayProperty("libFolder");
        Vector<File> allSiteFiles = new Vector<File>();
        if (libFolders==null || libFolders.length==0) {
            File parentPath = getParentFolderOrFail();
            File newFolder = new File(parentPath, "sites");
            if (!newFolder.exists()) {
                newFolder.mkdirs();
            }
            allSiteFiles.add(newFolder);
            return allSiteFiles;
        }

        for (String libFolder : libFolders) {
            File libDirectory = new File(libFolder);
            if (!libDirectory.exists()) {
                libDirectory.mkdirs();
            }
            allSiteFiles.add(libDirectory);
        }
        return allSiteFiles;
    }


    private File getGenericFolderOrFail(String propertyName, String subFolderName) throws Exception {
        String getFolder = props.getProperty(propertyName);
        File genFolderPath = null;
        if (getFolder == null || getFolder.length()==0) {
            File parentPath = getParentFolderOrFail();
            genFolderPath = new File(parentPath, subFolderName);
        }
        else {
            genFolderPath = new File(getFolder);
        }
        if (!genFolderPath.exists()) {
            genFolderPath.mkdirs();
        }
        if (!genFolderPath.exists()) {
            throw new Exception("For some reason can not find or create the folder: "+genFolderPath);
        }
        if (!genFolderPath.isDirectory()) {
            throw new NGException("nugen.exception.folder.not.folder", new Object[] { propertyName,
                    genFolderPath.getAbsolutePath() });
        }
        return genFolderPath;
    }

    private File getParentFolderOrFail() throws Exception {
        String parent = props.getProperty("dataContainer");
        if (parent==null || parent.length()==0) {
            //seems like a reasonable default to try out, pretty safe
            parent="c:/CognoscentiData/";
        }
        File parentPath = new File(parent);
        if (!parentPath.exists()) {
            //if the data folder does not exist, then go ahead and create it
            //what would be wrong with that?
            parentPath.mkdirs();
        }
        if (!parentPath.exists()) {
            throw new Exception("For some reason can not find or create the data container: "+parent);
        }
        return parentPath;
    }

    /**
     * Returns a user specified globally unique value, or else a random value if
     * one was not set. The purpose is to provide a unique jey for the server.
     * If the user does not set a value, then the unique key may be different
     * every time the server is started. However, two servers are highly
     * unlikely to have the same value, and that is the purpose, to distinguish
     * servers.
     *
     * Use can specify the value in the config file setting: ServerId
     */
    private String serverId = null;

    public synchronized String getServerGlobalId() {
        if (serverId != null) {
            return serverId;
        }
        serverId = getProperty("ServerId");
        if (serverId != null && serverId.length() > 0) {
            return serverId;
        }
        serverId = IdGenerator.generateKey();
        return serverId;
    }

}
