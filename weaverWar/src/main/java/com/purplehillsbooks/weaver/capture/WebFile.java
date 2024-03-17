/*
 * Copyright 2024 Keith D Swenson
 */

package com.purplehillsbooks.weaver.capture;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.weaver.exception.WeaverException;

/**
 *
 */
public class WebFile {

    private JSONObject webFile = new JSONObject();
    private File location;

    private WebFile(File loc) {
        location = loc;
        webFile = JSONObject.readFromFile(loc);
    }

    public static WebFile readOrCreate(File loc, String urlPath) throws Exception {
        if (!loc.exists()) {
            JSONObject webFile = new JSONObject();
            webFile.requireJSONArray("articles");
            webFile.requireJSONArray("links");
            webFile.put("url", urlPath);
            webFile.put("downloadTime", System.currentTimeMillis());
            webFile.writeToFile(loc);
        }
        WebFile ret = new WebFile(loc);
        return ret;
    }

    public String getUrl() throws Exception {
        return webFile.getString("url");
    }

    public void save() throws Exception {
        webFile.writeToFile(location);
    }

    static int threshold = 400;
    static int articleThreshold = 400;
    public void refreshFromWeb() throws Exception {
        String url = getUrl();
        try {
            JSONArray artlist = webFile.requireJSONArray("articles");
            JSONArray linklist = webFile.requireJSONArray("links");
            HtmlToWikiConverter2 converter = new HtmlToWikiConverter2();
            List<String> markDown = converter.webPageToWiki(url);
            int count = 0;
            for (String block : markDown) {
                count++;
                JSONObject seg = new JSONObject();
                seg.put("originPos", count);
                if (block.startsWith("!!")) {
                    seg.put("content", block);
                    artlist.put(seg);
                }
                else if (HtmlToWikiConverter2.amtNonLinkedText(block)>articleThreshold) {
                    seg.put("content", block);
                    artlist.put(seg);
                }
                else if (block.length()>threshold) {
                    seg.put("content", block);
                    linklist.put(seg);
                }
                else {
                    //ignore short blocks of text
                }
            }
            save();
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to download web page from (%s)", e, url);
        }
    }

    public List<String> getMarkDownBlocks() {
        List<String> res = new ArrayList<>();
        JSONArray artlist = webFile.requireJSONArray("articles");
        for (JSONObject article : artlist.getJSONObjectList()) {
            res.add(article.getString("content"));
        }
        return res;
    }

    public JSONObject getJson() {
        return JSONObject.deepCopy(webFile);
    }

}
