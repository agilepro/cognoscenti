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
import com.purplehillsbooks.weaver.SectionUtil;
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
            webFile.requireJSONArray("sections");
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
            JSONArray sections = new JSONArray();
            HtmlToWikiConverter2 converter = new HtmlToWikiConverter2();
            List<String> markDown = converter.webPageToWiki(url);
            int count = 0;
            for (String block : markDown) {
                JSONObject seg = new JSONObject();
                seg.put("group", "article");
                seg.put("originPos", ++count);
                seg.put("content", block);
                if (block.startsWith("!!")) {
                    seg.put("group", "article");
                }
                else if (HtmlToWikiConverter2.amtNonLinkedText(block)>articleThreshold) {
                    seg.put("group", "article");
                }
                else if (block.length()>threshold) {
                    seg.put("group", "links");
                }
                else {
                    seg.put("group", "hidden");
                }
                sections.put(seg);
            }
            webFile.put("sections", sections);
            sortAndNumber();
            save();
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to download web page from (%s)", e, url);
        }
    }

    private void sortAndNumber() {
        int count = 0;
        JSONArray sections = webFile.getJSONArray("sections");
        JSONArray sortedList = new JSONArray();
        for (JSONObject sec : sections.getJSONObjectList() ) {
            if ("article".equals(sec.getString("group"))) {
                sec.put("displayOrder", ++count);
                sortedList.put(sec);
            }
        }
        for (JSONObject sec : sections.getJSONObjectList() ) {
            if ("links".equals(sec.getString("group"))) {
                sec.put("displayOrder", ++count);
                sortedList.put(sec);
            }
        }
        for (JSONObject sec : sections.getJSONObjectList() ) {
            if ("hidden".equals(sec.getString("group"))) {
                sec.put("displayOrder", ++count);
                sortedList.put(sec);
            }
        }
        webFile.put("sections", sortedList);
    }

    public List<String> getMarkDownBlocks() {
        List<String> res = new ArrayList<>();
        JSONArray artlist = webFile.requireJSONArray("sections");
        for (JSONObject article : artlist.getJSONObjectList()) {
            res.add(article.getString("content"));
        }
        return res;
    }

    public void updateData(JSONObject newList) {
        JSONArray secsToProcess = newList.getJSONArray("sections");
        for (JSONObject section : secsToProcess.getJSONObjectList()) {
            int secNum = section.getInt("originPos");
            updateSectionData(secNum, section);
        }
        sortAndNumber();
    }

    private void  updateSectionData(int secNum, JSONObject newSection) {
        for (JSONObject oldSection : webFile.getJSONArray("sections").getJSONObjectList()) {
            if (secNum == oldSection.getInt("originPos")) {
                copyIfPresent(oldSection, newSection, "group");
                copyIfPresent(oldSection, newSection, "content");
                copyIfPresent(oldSection, newSection, "displayOrder");
            }
        }
    }

    public void updateUserComments(int secNum, String userKey, JSONObject posted) {
        JSONArray newComments = posted.requireJSONArray("comments");
        for (JSONObject oldSection : webFile.getJSONArray("sections").getJSONObjectList()) {
            if (secNum == oldSection.getInt("originPos")) {
                JSONObject comments = oldSection.requireJSONObject("comments");
                comments.put(userKey, newComments);
            }
        }
    }

    public String findSection(int secNum) {
        for (JSONObject oldSection : webFile.getJSONArray("sections").getJSONObjectList()) {
            if (secNum == oldSection.getInt("originPos")) {
                return oldSection.getString("content");
            }
        }
        return "";
    }

    public JSONObject getSectionParagraphsAndSentences(int secNum) throws Exception {
        String entireBlock = null;
        for (JSONObject oldSection : webFile.getJSONArray("sections").getJSONObjectList()) {
            if (secNum == oldSection.getInt("originPos")) {
                entireBlock = oldSection.getString("content");
            }
        }
        if (entireBlock == null) {
            throw WeaverException.newBasic("Can not find section %d in this web file", secNum);
        }

        JSONObject total = new JSONObject();
        JSONArray paragraphs = total.requireJSONArray("paragraphs");

        int paraNum = 0;
        for (String para : findParagraphs(entireBlock)) {
            JSONObject onePara = new JSONObject();
            onePara.put("original", para);
            paragraphs.put(onePara);
            onePara.put("paraNum", ++paraNum);
            JSONArray lines = onePara.requireJSONArray("lines");
            int lineNum = 0;
            for (String line : findSentences(para)) {
                JSONObject oneLine = new JSONObject();
                lines.put(oneLine);
                oneLine.put("lineNum", ++lineNum);
                oneLine.put("text", line);
            }
        }
        return total;
    }

    public static List<String> findParagraphs(String block) {
        List<String> listOfParagraphs = new ArrayList<>();
        StringBuilder paragraph = new StringBuilder();
        for (String line : block.split("\n")) {
            line = line.trim();
            boolean isNewParagraph = (line.length()==0);
            int start = 0;
            if (line.startsWith("*")) {
                isNewParagraph = true;
                start = skipChar(0, line, '*');
            }
            if (line.startsWith("!")) {
                isNewParagraph = true;
                start = skipChar(0, line, '!');
            }
            if (line.startsWith(":")) {
                isNewParagraph = true;
                start = skipChar(0, line, ':');
            }
            if (isNewParagraph) {
                String full = paragraph.toString().trim();
                if (full.length()>0) {
                    listOfParagraphs.add(full);
                }
                paragraph = new StringBuilder();
            }
            start = skipWhite(start, line);
            // pull the preceeding markdown out
            paragraph.append(line.substring(start));
            paragraph.append(" ");
        }
        String full2 = paragraph.toString().trim();
        if (full2.length()>0) {
            listOfParagraphs.add(full2.trim());
        }
        return listOfParagraphs;
    }

    public static List<String> findSentences(String paragraph) {
        List<String> listOfSentences = new ArrayList<>();
        int start = skipWhite(0, paragraph);
        while (start < paragraph.length()) {
            int pos = findSentenceEnd(paragraph, start);
            String trimmedLine = paragraph.substring(start, pos).trim();
            if (trimmedLine.length()>0) {
                listOfSentences.add(trimmedLine);
            }
            start = skipWhite(pos, paragraph);
        }
        return listOfSentences;
    }

    private static int skipWhite(int pos, String val) {
        if (pos>= val.length()) {
            return pos;
        }

        while (pos<val.length()) {
            char ch = val.charAt(pos);
            if (!Character.isWhitespace(ch) && 160 != ch) {
                return pos;
            }
            pos++;
        }
        return pos;
    }

    private static int skipChar(int pos, String val, char match) {
        if (pos>= val.length()) {
            return pos;
        }

        while (pos < val.length()) {
            char ch = val.charAt(pos);
            if (match != ch) {
                return pos;
            }
            pos++;
        }
        return pos;
    }

    private static int findSentenceEnd(String paragraph, int start) {
        int i = start;
        int limit = paragraph.length()-1;
        if (i >= paragraph.length()) {
            return paragraph.length();
        }
        boolean skipHyperLink = false;
        while (i < limit) {
            char ch = paragraph.charAt(i);
            i++;
            if (skipHyperLink) {
                if (ch==']') {
                    skipHyperLink = false;
                }
            }
            else {
                if (ch=='[') {
                    skipHyperLink = true;
                }
                else if (i < limit && (ch == '.' || ch == ';' || ch == '?' || ch == '!')) {
                    ch = paragraph.charAt(i);
                    while (i < limit &&
                            (ch == '\"' || ch == '”' || ch == '\'' || ch == '’' || ch == ')')) {
                        i++;
                        ch = paragraph.charAt(i);
                    }
                    if (i > 10) {
                        // avoid the worst of sequences like a.b.c.d.e.f.
                        return i;
                    }
                }
            }
        }
        return paragraph.length();
    }

    private static void copyIfPresent(JSONObject oldObj, JSONObject newObj, String key) {
        if (newObj.has(key)) {
            oldObj.put(key, newObj.get(key));
        }
    }

    public JSONObject getJson() {
        return JSONObject.deepCopy(webFile);
    }

    public String lionize(String input) {
        return input;
    }

}
