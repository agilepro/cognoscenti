package com.purplehillsbooks.weaver.util;

import java.util.List;

import org.bson.Document;

import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.result.DeleteResult;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
 * Isolate the arcate Mongo specific classes here if possible
 */
public class MongoDB {

    public final String uri = "mongodb://192.168.1.23:27017";
    MongoClient mongoClient;
    MongoDatabase db;
    MongoCollection<org.bson.Document> pospatdb;
    public int limit = 100;
    
    public MongoDB() {
        mongoClient = MongoClients.create(uri);
        db = mongoClient.getDatabase("photo");
        pospatdb = db.getCollection("pospat");
    }
    
    public void setLimit(int i) {
        limit = i;
    }
    
    /**
     * don't try to use this after closing
     */
    public void close() {
        mongoClient.close();
    }
    
    /**
     * simple default query that gets all the records up to a limit
     * probably only useful for testing/debugging
     */
    public JSONArray findAllRecords(int limit) throws Exception {
        FindIterable<Document> resultSet = pospatdb.find();
        MongoCursor<Document> cursor = resultSet.iterator();
        
        JSONArray ja = new JSONArray();
        int count = 0;
        while (count++ < limit && cursor.hasNext()) {
            Document d = cursor.next();
            
            JSONObject jo = new JSONObject(d.toJson());
            ja.put(jo);
        }
        return ja;
    }
    public JSONArray queryRecords(JSONObject query) throws Exception {
        String queryString = query.toString(0);
        long startTime = System.currentTimeMillis();
        
        Document dq = Document.parse(queryString);
        FindIterable<Document> resultSet = pospatdb.find(dq);
        
        MongoCursor<Document> cursor = resultSet.iterator();
        
        JSONArray ja = new JSONArray();
        int count = 0;
        while (count++ < limit && cursor.hasNext()) {
            Document d = cursor.next();
            
            JSONObject jo = new JSONObject(d.toJson());
            ja.put(jo);
        }
        long ms = System.currentTimeMillis()-startTime;
        System.out.println("MONGO: "+count+" records ("+ms+"ms) from: "+queryString);
        return ja;
    }
    
    
    /**
     * This deletes all the pospat records that are associated with a particular disk
     */
    public void clearAllFromDisk(String diskName) throws Exception {
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("disk", diskName);
        pospatdb.deleteMany(Document.parse(filter.toString(2)));
    }
    public void clearAllFromDiskPath(String diskName, String path) throws Exception {
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("disk", diskName);
        filter.put("path", path);
        DeleteResult dr = pospatdb.deleteMany(Document.parse(filter.toString(0)));
        System.out.println("MONGO: removed "+dr.getDeletedCount()+" records disk=("+diskName+") path=("+path+") using "+filter.toString(0));
    }
    
    public void createPosPatRecord(PosPat pp, List<ImageInfo> imagesForPP) throws Exception {
        String symbol = pp.getSymbol();
        
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("symbol", symbol);
        pospatdb.deleteOne(Document.parse(filter.toString(2)));
        
        JSONObject jo = pp.getFullMongoDoc(imagesForPP);
        String rep = jo.toString(2);
        //System.out.println("=============INSERTING===============\n"+rep+"\n=========================");
        pospatdb.insertOne(Document.parse(rep));
    }
    
    private JSONObject parseQuery(String query) throws Exception {
        if (query.length()<4) {
            throw new JSONException("query is too short, must be letter, an open paren, at least one value char, and a close paren");
        }
       
        if (query.charAt(1) != '(') {
            throw new JSONException("error with query, second character must be an open paren");
        }

        JSONObject mongoQuery = new JSONObject();
        // all conditions will be ANDED together:  (AND  q q q)
        JSONArray queryAndList = new JSONArray();

        int startPos = 0;
        while (startPos<query.length()) {
            char sel = query.charAt(startPos++);
            if (query.charAt(startPos) != '(') {
                throw new JSONException("error with query, character "+startPos+" must be an open paren");
            }
            startPos++;
            int pos = query.indexOf(')', startPos);
            if (pos<0) {
                throw new JSONException("Error, can not find the closing paren char after position {0}", startPos);
            }
            String val = query.substring(startPos, pos);
            JSONObject q = new JSONObject();
            switch (sel) {
                case 'g':
                    q.put("tags", val.toLowerCase());
                    queryAndList.put(q);
                    break;
                case 'p':
                case 'e':
                    //pattern equals value
                    q.put("pattern", val);
                    queryAndList.put(q);
                    break;
                case 'x':
                    //pattern equals value
                    q.put("symbol", val);
                    queryAndList.put(q);
                    break;
                case 'b':
                    //pattern must not equal this value
                    JSONObject negp = q.requireJSONObject("pattern");
                    negp.put("$ne", val);
                    queryAndList.put(q);
                    break;
                case 's':   
                    //pattern starts with
                    JSONObject regex = q.requireJSONObject("pattern");
                    regex.put("$regex", "^"+val);
                    queryAndList.put(q);
                    break;
                case 'd':  
                    //exclude tag
                    JSONObject condition = q.requireJSONObject("tags");
                    condition.put("$ne", val.toLowerCase());
                    queryAndList.put(q);
                    break;
                case 'k':  
                    if ("hasSample".equals(val)) {
                        condition = q.requireJSONObject("hasSample");
                        condition.put("$eq", true);
                        queryAndList.put(q);
                    }
                    else if ("noSample".equals(val)) {
                        condition = q.requireJSONObject("hasSample");
                        condition.put("$ne", true);
                        queryAndList.put(q);
                    }
                    else{
                        throw new JSONException("keyword 'hasSample' & 'noSample' supported.  Don't understand keyword:  "+val);
                    }
                    break;
                default:
                    throw new JSONException("secondary query elements must begin with a 'g' for tag, "
                        +"'d' for NOT tag, 'p' for pattern contains, 'b' for pattern not contains, "
                        +"'s' pattern starts,  or 'e' for pattern exact, 't' for duplicate size, "
                        +"'i' for index, and '!' for NOT index, 'n' for numeric range, 'u' for number of tags,"
                        +"'l' for larger-than size");
            }
            startPos = pos+1;
        }
        mongoQuery.put("$and", queryAndList);
        return mongoQuery;
    }
    
    public JSONArray querySets(String query) throws Exception {
        System.out.println("MONGO: query records for: "+query);
        try {

            if (query.length()<4) {
                throw new JSONException("query is too short, must be letter, an open paren, at least one value char, and a close paren");
            }
           
            if (query.charAt(1) != '(') {
                throw new JSONException("error with query, second character must be an open paren");
            }

            JSONObject mongoQuery = parseQuery(query);
            JSONArray res = queryRecords(mongoQuery);

            System.out.println("MONGO: query found: "+res.length()+" records");
            return res;
        }
        catch(Exception e) {
            throw new JSONException("Error in queryImages({0})",e, query);
        }
    }
    
    public void findStatsForDisk(String diskName, HashCounter tags, HashCounter patterns, HashCounter symbols, HashCounter fileSize) throws Exception {
        //no filter, means you get the entire database
        JSONObject filter = new JSONObject();
        filter.put("disk", diskName);
        
        queryStats(filter, tags, patterns, symbols, fileSize);        
    }
    
    public void queryStatistics(String query, HashCounter tags, HashCounter patterns, HashCounter symbols, HashCounter fileSize) throws Exception {
        JSONObject mongoQuery = parseQuery(query);
        queryStats(mongoQuery, tags, patterns, symbols, fileSize);
    }
    
    
    public void queryStats(JSONObject mongoQuery, HashCounter tags, HashCounter patterns, HashCounter symbols, HashCounter fileSize) throws Exception {
        System.out.println("MONGO: query statistics for: "+mongoQuery.toString(0));
        try {

            Document dq = Document.parse(mongoQuery.toString(0));
            FindIterable<Document> resultSet = pospatdb.find(dq);
            
            JSONObject projection = new JSONObject();
            projection.put("tags",  1);
            projection.put("pattern",  1);
            projection.put("symbol",  1);
            projection.put("imageCount",  1);
            projection.put("totalSize",  1);
            Document df = Document.parse(projection.toString(0));
            resultSet.projection(df);
            
            MongoCursor<Document> cursor = resultSet.iterator();

            while (cursor.hasNext()) {
                Document d = cursor.next();
                
                JSONObject jo = new JSONObject(d.toJson());
                
                int imageCount = 1;
                if (jo.has("imageCount")) {
                    imageCount = jo.getInt("imageCount");
                }

                int kiloBytes = 0;
                if (jo.has("totalSize")) {
                    kiloBytes = jo.getInt("totalSize")/1000;
                }
                
                String pattern = jo.getString("pattern");
                patterns.changeBy(pattern, imageCount);
                
                String symbol = jo.getString("symbol");
                symbols.changeBy(symbol, imageCount);
                
                JSONArray tagArray = jo.getJSONArray("tags");
                for (String tagValue : tagArray.getStringList()) {
                    tags.changeBy(tagValue, imageCount);
                    fileSize.changeBy(tagValue, kiloBytes);
                }
            }
        }
        catch(Exception e) {
            throw new JSONException("Error in queryImages({0})",e, mongoQuery.toString(0));
        }
    }
    
}
