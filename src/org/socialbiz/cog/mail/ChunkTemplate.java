package org.socialbiz.cog.mail;

import java.io.File;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

import com.x5.template.Chunk;
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


    public static void streamIt(Writer w, File templateFile, JSONObject data) throws Exception {
        if (!templateFile.exists()) {
            throw new Exception("The template file is missing: "+templateFile);
        }
        String fileName = templateFile.getName();
        if (fileName.toLowerCase().endsWith(".chtml")) {
            fileName = fileName.substring(0,fileName.length()-6);
        }
        //TemplateSet tempSet = new TemplateSet(templateFile.getParentFile().toString(), "chtml", 5);
        Theme theme = new Theme();
        theme.setTemplateFolder(templateFile.getParentFile().toString());
        theme.setDefaultFileExtension("chtml");
        theme.setEncoding("UTF-8");

        //This allows {$myDate|date(YYYY-MM-dd)} style tokens in the file
        theme.registerFilter(new ChunkFilterDate());

        Chunk c = theme.makeChunk(fileName);

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

//        MemFile mf = new MemFile();
//        Writer ww = mf.getWriter();
        c.render(w);
//        ww.flush();
//        File tempOutFile = new File(templateFile.getParentFile(), templateFile.getName()+".out.txt");
//        FileOutputStream fos = new FileOutputStream(tempOutFile);
//        Writer fosw = new OutputStreamWriter(fos, "UTF-8");
//        mf.outToWriter(fosw);
//        fosw.flush();
//        fosw.close();
//        System.out.println("CHUNK: file dumped to "+tempOutFile);
//        mf.outToWriter(w);
        w.flush();
    }

}
