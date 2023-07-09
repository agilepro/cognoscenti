package com.purplehillsbooks.weaver;

import java.io.File;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.StreamHelper;

public class LearningPath {
    
    private static File learningPathFile;
    private static JSONObject pathFile;
    private static Cognoscenti cog;
    
    public static void init(Cognoscenti _cog) throws Exception {
        cog = _cog;
        learningPathFile    =  new File(cog.getConfig().getUserFolderOrFail(), "learningPath.json");
        if (!learningPathFile.exists()) {
            File templateFile = cog.getConfig().getFileFromRoot("learningPath-sample.json");
            StreamHelper.copyFileToFile(templateFile, learningPathFile);
        }
        if (!learningPathFile.exists()) {
            throw new Exception("Learning path file is missing and can not be created: "+learningPathFile.getAbsolutePath());
        }
    }
    
    private static JSONObject getInternal() throws Exception {
        if (pathFile==null) {
            pathFile = JSONObject.readFromFile(learningPathFile);
        }
        return pathFile;
    }
    
    public static JSONObject getAllLearningPrompts() throws Exception {
        return UtilityMethods.deepCopy(getInternal());
    }
    
    public static JSONArray getLearningForPage(String jspName) throws Exception {
        JSONArray ret = getInternal().requireJSONArray(jspName);
        return ret;
    }
    
    
    public static void putLearningForPage(String jspName, String mode, JSONObject learning) throws Exception {
        try {
            JSONArray ret = getInternal().requireJSONArray(jspName);
            JSONArray newList = new JSONArray();
            learning.put("mode",  mode);
            boolean found = false;
            for (JSONObject oneLearn : ret.getJSONObjectList()) {
                if (oneLearn.getString("mode").contentEquals(mode)) {
                    newList.put(learning);
                    found = true;
                }
                else {
                    newList.put(oneLearn);
                }
            }
            if (!found) {
                newList.put(learning);
            }
            pathFile.put(jspName, newList);
            pathFile.writeToFile(learningPathFile);
        }
        catch (Exception e) {
            pathFile = null;  //force re-read
            throw new Exception(String.format("Failure while trying to update learning path mode=%s, jsp=%s", mode, jspName), e);
        }
    }
    
}
