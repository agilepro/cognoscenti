package org.socialbiz.cog;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;

public class UserCache {
    JSONObject cacheObj;
    String userKey;
    File userCacheFile;

    UserCache(Cognoscenti cog, String _userKey) throws Exception {
        userKey = _userKey;
        File userFolder = cog.getConfig().getUserFolderOrFail();
        userCacheFile = new File(userFolder, userKey+".user.json");
        if (userCacheFile.exists()) {
            FileInputStream fis = new FileInputStream(userCacheFile);
            JSONTokener jt = new JSONTokener(fis);
            cacheObj = new JSONObject(jt);
        }
        else {
            cacheObj = new JSONObject();
            save();
        }
    }

    public void save() throws Exception {
        File folder = userCacheFile.getParentFile();
        File tempFile = new File(folder, "~"+userCacheFile.getName()+"~tmp~");
        if (tempFile.exists()) {
            tempFile.delete();
        }
        FileOutputStream fos = new FileOutputStream(tempFile);
        OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
        cacheObj.write(osw,2,0);
        osw.close();
        if (userCacheFile.exists()) {
            userCacheFile.delete();
        }
        tempFile.renameTo(userCacheFile);
    }

    // operation get task list.
    public void refreshCache(Cognoscenti cog) throws Exception {

        NGPageIndex.assertNoLocksOnThread();

        JSONArray actionItemList = new JSONArray();
        JSONArray proposalList = new JSONArray();

        UserProfile up = UserManager.getUserProfileByKey(userKey);

        for (NGPageIndex ngpi : cog.getAllContainers()) {
            if (!ngpi.isProject()) {
                continue;
            }

            NGPage aPage = ngpi.getPage();
            for (GoalRecord gr : aPage.getAllGoals()) {

                if (gr.isPassive()) {
                    //ignore tasks that are from other servers.  They will be identified and tracked on
                    //those other servers
                    continue;
                }

                if (!gr.isAssignee(up)) {
                    continue;
                }

                actionItemList.put(gr.getJSON4Goal(aPage));
            }
            for (NoteRecord aNote : aPage.getAllNotes()) {
                String targetRole = aNote.getTargetRole();
                NGRole users = aPage.getRole(targetRole);
                if (users==null) {
                    //ignore notes that have invalid target role
                    continue;
                }
                for (CommentRecord cr : aNote.getComments()) {
                    if (cr.isPoll()) {

                    }
                }
            }
            // clean out any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();
       }

        cacheObj.put("actionItems", actionItemList);
        cacheObj.put("proposals", proposalList);
    }

    public JSONArray getActionItems() throws Exception {
        return cacheObj.getJSONArray("actionItems");
    }
    public JSONArray getProposals() throws Exception {
        return cacheObj.getJSONArray("proposals");
    }
}
