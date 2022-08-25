package com.purplehillsbooks.weaver.mail;

import java.io.File;
import java.io.StringWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;
import com.purplehillsbooks.weaver.AuthRequest;
import com.x5.template.Chunk;
import com.x5.template.ContentSource;
import com.x5.template.Theme;


/**
 * Chunk Template is an open source template library.
 *
 * This class isolates all the special code needed to work with it.
 */
public class ChunkTemplate {

    public static HashMap<String,Object> convertToMap(JSONObject jo) throws Exception {
        HashMap<String,Object> res = new HashMap<String,Object> ();
        Set<String> keys = jo.keySet();
        if (keys.size()==0) {
            return null;
        }
        for (String key : keys) {
            Object kewl = jo.get(key);
            if (kewl instanceof JSONObject) {
                Object o = convertToMap((JSONObject)kewl);
                if (o!=null) {
                    res.put(key, o);
                }
            }
            else if (kewl instanceof JSONArray) {
                Object o = convertToList((JSONArray)kewl);
                if (o!=null) {
                    res.put(key, o);
                }
            }
            else if (kewl instanceof String) {
                res.put(key, kewl);
            }
            else if (kewl instanceof Boolean) {
                if (((Boolean)kewl).booleanValue()) {
                    //only insert a value if true .... do not put one if false
                    res.put(key, "true");
                }
            }
            else if (kewl instanceof Long) {
                res.put(key, ((Long)kewl).toString());
            }
            else if (kewl instanceof Integer) {
                res.put(key, ((Integer)kewl).toString());
            }
            else if (kewl instanceof Float) {
                res.put(key, ((Float)kewl).toString());
            }
            else if (kewl instanceof Double) {
                res.put(key, ((Double)kewl).toString());
            }
            else {
                res.put(key, kewl.toString() + " TYPE:"+kewl.getClass().getName());
            }
        }
        return res;
    }

    public static List<Object> convertToList(JSONArray ja) throws Exception {
        if (ja.length()==0) {
            return null;
        }
        List<Object> res = new ArrayList<Object> ();
        for (int i=0; i<ja.length(); i++) {
            Object kewl = ja.get(i);
            if (kewl instanceof JSONObject) {
                Object o = convertToMap((JSONObject)kewl);
                if (o!=null) {
                    res.add(o);
                }
            }
            else if (kewl instanceof JSONArray) {
                Object o = res.add(convertToList((JSONArray)kewl));
                if (o!=null) {
                    res.add(o);
                }
            }
            else if (kewl instanceof String) {
                res.add(kewl);
            }
            else if (kewl instanceof Boolean) {
                if (((Boolean)kewl).booleanValue()) {
                    //only add a value if true .... do not put one if false
                    res.add("true");
                }
                else {
                    //not sure this works.   This only effects arrays of booleans
                    //who would have an array of booleans?
                    //we need to add something because we must preserve the positions
                    res.add("");
                }
            }
            else {
                res.add(kewl.toString());
            }
        }
        return res;
    }


    public static void streamIt(Writer w, File templateFile, JSONObject data, Calendar cal) throws Exception {
        if (!templateFile.exists()) {
            throw new Exception("The template file is missing: "+templateFile);
        }
        String fileName = templateFile.getName();
        if (fileName.toLowerCase().endsWith(".chtml")) {
            fileName = fileName.substring(0,fileName.length()-6);
        }
        
        Theme theme = new Theme();
        theme.setTemplateFolder(templateFile.getParentFile().toString());
        theme.setDefaultFileExtension("chtml");
        theme.setEncoding("UTF-8");

        //This allows {$myDate|date(YYYY-MM-dd)} style tokens in the file
        theme.registerFilter(new ChunkFilterDate(cal));
        theme.registerFilter(new ChunkFilterMarkdown());

        Chunk c = theme.makeChunk(fileName);
        
        finishUp(w,c,data);
    }
    
    /**
     * in Weaver default templates are stored in the code repository, but these can be 
     * overridden by custom templates in the site.   Streaming the template this way
     * assures that the template is found in the site when overridden.
     * @param w is the writer that will be written to
     * @param ar the AuthRequest initialized with a workspace on it for finding template
     * @param templateName without the file extension
     * @param data the JSON data
     * @param cal the personal calendar of the person receiving the result
     * @throws Exception
     */
    public static void streamAuthRequest(Writer w, AuthRequest ar, String templateName, JSONObject data, Calendar cal) throws Exception {
        Exception debug = new Exception("streamAuthRequest called with this stack trace template="+templateName);
        debug.printStackTrace(System.out);
        
        String nameWithExtension = templateName + ".chtml";
        
        TemplateProviderWeaver provider = new TemplateProviderWeaver(ar);
        
        //this will throw an exception if template file does not exist
        ar.findChunkTemplate(nameWithExtension);
        
        Theme theme = new Theme((ContentSource)provider);
        //theme.setTemplateFolder(templateFile.getParentFile().toString());
        //theme.setDefaultFileExtension("chtml");
        theme.setEncoding("UTF-8");

        //This allows {$myDate|date(YYYY-MM-dd)} style tokens in the file
        theme.registerFilter(new ChunkFilterDate(cal));
        theme.registerFilter(new ChunkFilterMarkdown());

        Chunk c = theme.makeChunk(templateName);
        
        finishUp(w,c,data);
    }
    
    
    public static String streamToString(File templateFile, JSONObject data, Calendar cal) throws Exception {
        MemFile mf = new MemFile();
        Writer w = mf.getWriter();
        streamIt(w,templateFile, data, cal);
        w.flush();
        return mf.toString();
    }
    
    
    
    /**
     * Takes a string that looks like a template, some data, and a calendar
     * and returns the string with the data substituted into it.
     * This is intended for small strings.
     * 
     * @param str the template that is to be interpreted
     * @param data is JSON structured field values
     * @param cal is teh calendar to use for date conversions
     * @return the resulting string with the data substituted in
     */
    public static String stringIt(String str, JSONObject data, Calendar cal) throws Exception {
        StringWriter sw = new StringWriter();
        Theme theme = new Theme();
        theme.setDefaultFileExtension("chtml");
        theme.setEncoding("UTF-8");

        //This allows {$myDate|date(YYYY-MM-dd)} style tokens in the file
        theme.registerFilter(new ChunkFilterDate(cal));

        Chunk c = theme.makeChunk();
        c.append(str);
        
        finishUp(sw,c,data);
        return sw.toString();
    }
    
    private static void finishUp(Writer w, Chunk c, JSONObject data) throws Exception {

        for (String key : data.keySet()) {
            Object kewl = data.get(key);
            if (kewl instanceof JSONObject) {
                Object o = convertToMap((JSONObject)kewl);
                if (o!=null) {
                    c.set(key, o);
                }
            }
            else if (kewl instanceof JSONArray) {
                Object o = convertToList((JSONArray)kewl);
                if (o!=null) {
                    c.set(key, o);
                }
            }
            else if (kewl instanceof String) {
                c.set(key, (String)kewl);
            }
            else {
                c.set(key, kewl.toString());
            }
        }
        c.set("debugDump", data.toString(2));

        c.render(w);
        w.flush();
    }

}
