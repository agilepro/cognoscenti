package com.purplehillsbooks.weaver.util;

import org.bson.Document;
import org.springframework.instrument.classloading.WeavingTransformer;

import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.ReplaceOptions;
import com.mongodb.client.result.UpdateResult;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;
import com.purplehillsbooks.weaver.exception.WeaverException;

/**
 * Isolate the arcane Mongo specific classes here if possible
 */
public class MongoDB {

    public final String uri = "mongodb://localhost:27017";
    MongoClient mongoClient;
    MongoDatabase db;
    MongoCollection<org.bson.Document> emaildb;
    public int limit = 100;

    public MongoDB() {
        mongoClient = MongoClients.create(uri);
        db = mongoClient.getDatabase("weaver");
        emaildb = db.getCollection("email");
    }

    public void setLimit(int i) {
        limit = i;
    }

    /**
     * don't try to use this after closing
     */
    public void close() {
        System.out.println("MONGO DB - closed");
        mongoClient.close();
    }

    /**
     * simple default query that gets all the records up to a limit
     * probably only useful for testing/debugging
     */
    public JSONArray findAllRecords() throws Exception {
        FindIterable<Document> resultSet = emaildb.find();
        MongoCursor<Document> cursor = resultSet.iterator();

        JSONArray ja = new JSONArray();
        int count = 0;
        while (count++ < limit && cursor.hasNext()) {
            Document d = cursor.next();

            JSONObject jo = new JSONObject(new JSONTokener( d.toJson() ));
            ja.put(jo);
        }
        cursor.close();
        return ja;
    }
    public JSONArray queryRecords(JSONObject query) throws Exception {
        return querySortRecords(query, null, 0, limit);
    }
    public JSONArray queryRecords(JSONObject query, int skip, int batchSize) throws Exception {
        return querySortRecords(query, null, skip, batchSize);
    }
    public JSONArray querySortRecords(JSONObject query, JSONObject sort) throws Exception {
        return querySortRecords(query, sort, 0, limit);
    }
    public JSONArray querySortRecords(JSONObject query, JSONObject sort, int skip, int batchSize) throws Exception {
        try {
            String queryString = query.toString(0);
            long startTime = System.currentTimeMillis();

            Document dq = Document.parse(queryString);
            FindIterable<Document> resultSet = emaildb.find(dq);
            if (sort!=null) {
                resultSet.sort(Document.parse(sort.toString(0)));
            }
            resultSet.skip(skip);
            MongoCursor<Document> cursor = resultSet.iterator();
            try {
                JSONArray ja = new JSONArray();
                int count = 0;
                while (cursor.hasNext() && count < batchSize) {
                    Document d = cursor.next();
                    JSONObject jo = new JSONObject(new JSONTokener(d.toJson()));
                    ja.put(jo);
                    count++;
                }
                long ms = System.currentTimeMillis()-startTime;
                if (count>0) {
                    System.out.println("MONGO: "+count+" records ("+ms+"ms) from: "+queryString);
                }
                return ja;
            }
            finally {
                cursor.close();
            }
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to read Mongo DB query (%s)", e, query.toString(2));
        }
    }

    public void createRecord(JSONObject emailRecord) throws Exception {
        String rep = emailRecord.toString(2);
        emaildb.insertOne(Document.parse(rep));
    }

    public void replaceRecord(JSONObject query, JSONObject emailRecord) throws Exception {
        String queryStr = query.toString(0);
        Document queryDoc = Document.parse(query.toString(0));
        Document recordDoc = Document.parse(emailRecord.toString(2));
        ReplaceOptions uopts = new ReplaceOptions();
        uopts.upsert(true);
        UpdateResult result = emaildb.replaceOne(queryDoc, recordDoc, uopts);
        System.out.println("MONGO updated "+result.getMatchedCount()+" records "+queryStr);
    }

}
