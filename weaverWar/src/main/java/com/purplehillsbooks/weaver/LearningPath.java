package com.purplehillsbooks.weaver;

import java.io.File;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class LearningPath {
    
    private static File learningPathFile;
    private static JSONObject pathFile;
    private static Cognoscenti cog;
    
    public static void init(Cognoscenti _cog) throws Exception {
        cog = _cog;
        learningPathFile    =  cog.getConfig().getFileFromRoot("learningPath.json");
        if (!learningPathFile.exists()) {
            throw new Exception("Learning path file is missing: "+learningPathFile.getAbsolutePath());
        }
        pathFile = JSONObject.readFromFile(learningPathFile);
    }
    
    public static JSONArray getLearningForPage(String jspName) throws Exception {
        JSONArray ret = pathFile.requireJSONArray(jspName);
        return ret;
    }
    
    
    public static void putLearningForPage(String jspName, String mode, JSONObject learning) throws Exception {
        JSONArray ret = pathFile.requireJSONArray(jspName);
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

}
