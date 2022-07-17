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

package com.purplehillsbooks.weaver.util;

import java.io.File;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.weaver.NGWorkspace;

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
    private Hashtable<File,NGWorkspace> hash;
    private int       cacheSize;

    public LRUCache(int numberToCache) {
        cacheSize = numberToCache;
        emptyCache();
    }

    public synchronized void emptyCache() {
        listOfPages = new ArrayList<NGWorkspace>(cacheSize);
        hash = new Hashtable<File,NGWorkspace>(cacheSize);
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
    public synchronized NGWorkspace recall(File id) {
        if (id==null) {
            throw new RuntimeException("NULL value passed for the cache key in LRUCache.recall");
        }
        NGWorkspace ngw = hash.get(id);
        if (ngw!=null) {
            unstore(id);
            if (!id.equals(ngw.getFilePath())) {
                throw new RuntimeException("Retrieved object for "+id+" has a path of "+ngw.getFilePath()+"!");
            }
        }
        return ngw;
    }

    /**
     * If, while updating a cached object, an exception it thrown,
     * all changes need to be cancelled.  The working copy needs to
     * be eliminated from the cache.  This will guarantee that the
     * next access to a page will be from reading the file on the disk.
     */
    public synchronized void unstore(File associatedFile) {
        NGWorkspace ngw = hash.get(associatedFile);
        if (ngw!=null) {
            listOfPages.remove(ngw);
            hash.remove(associatedFile);
        }
        if (hash.containsKey(associatedFile)) {
            throw new RuntimeException("Removal of cache item did not work!");
        }
    }


    /**
    * Put an object (back) into the cache associated with the id.
    * If the cache is full, remove the oldest objects from cache.
    * If an object already exists with that id, then this new object
    * will replace it.
    */
    public synchronized void store(File id, NGWorkspace ngw) {
        if (!id.equals(ngw.getFilePath())) {
            throw new RuntimeException("Trying to store object for "+id+" has a path of "+ngw.getFilePath()+"!");
        }
        NGWorkspace prev = hash.get(id);
        if (prev!=null) {
            listOfPages.remove(prev);
            hash.remove(id);
        }
        else {
            //then, if cache full, remove the oldest ones
            while (listOfPages.size()>=cacheSize) {
                prev = listOfPages.remove(cacheSize-1);
                hash.remove(prev.getFilePath());
            }
        }
        listOfPages.add(0,ngw);
        hash.put(id, ngw);
    }

}