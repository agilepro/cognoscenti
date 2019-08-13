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

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

/**
* This is a Least Recently Used Cache.
* Believe it or not, Java does not come with such a simple thing.
* This keeps up to N object referenced by key, kicking out the oldest
* one when the new one is added.
* Everything is a Java Object -- no typing
*/
public class LRUCache
{
    private List<NGWorkspace> listOfPages;
    private Hashtable<String,NGWorkspace> hash;
    private int       cacheSize;

    public LRUCache(int numberToCache) {
        cacheSize = numberToCache;
        emptyCache();
    }

    public synchronized void emptyCache() {
        listOfPages = new ArrayList<NGWorkspace>(cacheSize);
        hash = new Hashtable<String,NGWorkspace>(cacheSize);
    }

    /**
    * Get an object out of the cache.
    * NOTE: the object is removed from the cache so that the
    * thread that takes it has exclusive access to the object
    * but remember, when done, store it back in there.
    *
    * If two thread are trying to manipulate the same object
    * at a time, they will end up each having a separate copy
    * of the object.  This design is *no worse* than without the cache.
    * If you have a file, and multiple threads are reading and
    * updating the file, then it is possible for multiple threads
    * to have the contents of one file in memory in two places,and
    * to be updating that file multiple times, writing on each other.
    * When the cache is used, the first thread will get the cached
    * object, and the second thread will not find one in the cache,
    * and so will go read the file.  Then one will store the object
    * and when the second stores the object, the first will be
    * replaced, and you will still have only one in the cache.
    *
    * The only real solution is to implement a "page lock" mechanism
    * where a thread gets a lock on a page id, and then releases it
    * when done, forcing reads and updates to be serialized.  This
    * mechanism is needed whether you have a cache or not.
    * So, the cache has no effect on this, but the cache DOES
    * make the first thread to request the page much much faster
    * and this reduces the possibility of simultaneous access.
    */
    public synchronized NGWorkspace recall(String id) {
        if (id==null) {
            throw new RuntimeException("NULL value passed for the cache key in LRUCache.recall");
        }
        NGWorkspace o = hash.get(id);
        if (o!=null) {
            unstore(id);
            if (!id.equals(o.getFilePath().toString())) {
                throw new RuntimeException("Retrieved object for "+id+" has a path of "+o.getFilePath()+"!");
            }
        }
        return o;
    }

    /**
     * If, while updating a cached object, an exception it thrown,
     * all changes need to be cancelled.  The working copy needs to
     * be eliminated from the cache.  This will guarantee that the
     * next access to a page will be from reading the file on the disk.
     */
    public synchronized void unstore(String id) {
        NGWorkspace o = hash.get(id);
        if (o!=null) {
            listOfPages.remove(o);
            hash.remove(id);
        }
        if (hash.containsKey(id)) {
            throw new RuntimeException("Removal of cache item did not work!");
        }
    }


    /**
    * Put an object (back) into the cache associated with the id.
    * If the cache is full, remove the oldest objects from cache.
    * If an object already exists with that id, then this new object
    * will replace it.
    */
    public synchronized void store(String id, NGWorkspace o) {
        if (!id.equals(o.getFilePath().toString())) {
            throw new RuntimeException("Trying to store object for "+id+" has a path of "+o.getFilePath()+"!");
        }
        NGWorkspace prev = hash.get(id);
        if (prev!=null) {
            listOfPages.remove(prev);
            hash.remove(prev);
        }
        else {
            //then, if cache full, remove the oldest ones
            while (listOfPages.size()>=cacheSize) {
                prev = listOfPages.remove(cacheSize-1);
                hash.remove(prev);
            }
        }
        listOfPages.add(0,o);
        hash.put(id, o);
    }

}