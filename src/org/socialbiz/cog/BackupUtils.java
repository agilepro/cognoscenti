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

import java.io.File;
import java.io.FileFilter;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.filefilter.WildcardFileFilter;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class BackupUtils  {

    /**
     * The class logger.
     */
    private static Log log = LogFactory.getLog(BackupUtils.class.getName());

    private static final long DEFAULT_COPY_BUFFER_SIZE = 32 * 1024 * 1024; // 32 MB

    private static final String BACKUP = "BackUp";

    private static final String RESTORE = "Restore";

    public static boolean areDirectoryInSync(File source, File destination, List<String> patternList) throws IOException {
      if ( source.isDirectory() ) {
        if ( !destination.exists() ) {
          return false;
        }
        else if ( !destination.isDirectory() ) {
          throw new IOException(
              "Source and Destination not of the same type:"
                  + source.getCanonicalPath() + " , " + destination.getCanonicalPath()
          );
        }

        FilenameFilter fileFilter = new WildcardFileFilter(patternList);

        String[] sources = source.list(fileFilter);
        Set<String> srcNames = new HashSet<String>( Arrays.asList( sources ) );
        String[] dests = destination.list();

        // check for files in destination and not in source
        for ( String fileName : dests ) {
          if ( !srcNames.contains( fileName ) ) {
            return false;
          }
        }

        boolean inSync = true;
        for ( String fileName : sources ) {
          File srcFile = new File( source, fileName );
          File destFile = new File( destination, fileName );
          if ( !areDirectoryInSync( srcFile, destFile,patternList ) ) {
            inSync = false;
            break;
          }
        }
        return inSync;
      }
      else {
        if ( destination.exists() && destination.isFile() ) {
          long sourceTimestamp = source.lastModified();
          long destinationTimestamp = destination.lastModified();
          return sourceTimestamp == destinationTimestamp;
        }
        else {
          return false;
        }
      }
    }

   public static void synDirectory(File source, File destination, List <String>patternList) throws IOException {
      if ( source.isDirectory() ) {
        if ( !destination.exists() ) {
          if ( !destination.mkdirs() ) {
            throw new IOException( "Could not create path " + destination );
          }
        }
        else if ( !destination.isDirectory() ) {
          throw new IOException(
              "Source and Destination not of the same type:"
                  + source.getCanonicalPath() + " , " + destination.getCanonicalPath()
          );
        }

        FilenameFilter fileFilter = new WildcardFileFilter(patternList);
        String[] sources = source.list(fileFilter);

        //copy each file from source
        for ( String fileName : sources ) {
          File srcFile = new File( source, fileName );
          File destFile = new File( destination, fileName );
          synDirectory( srcFile, destFile,patternList );
        }
      }
      else {
        if ( destination.exists() && destination.isDirectory() ) {
          delete( destination );
        }
        if ( destination.exists() ) {
          long sts = source.lastModified();
          long dts = destination.lastModified();

          //do not copy if same timestamp and same length
          if ( sts == 0 || sts != dts || source.length() != destination.length() ) {
            copyFile( source, destination );
          }
        }
        else {
          copyFile( source, destination );
        }
      }
    }

    private static void copyFile(File srcFile, File destFile) throws IOException {
      FileInputStream is = null;
      FileOutputStream os = null;
      try {

        is = new FileInputStream( srcFile );
        FileChannel iChannel = is.getChannel();

        os = new FileOutputStream( destFile, false );
        FileChannel oChannel = os.getChannel();

        long doneBytes = 0L;
        long todoBytes = srcFile.length();

        while ( todoBytes != 0L ) {

         //Return the smallest of two
          long iterationBytes = Math.min(todoBytes, DEFAULT_COPY_BUFFER_SIZE );

          long transferredLength = oChannel.transferFrom(iChannel, doneBytes, iterationBytes );

          if ( iterationBytes != transferredLength ) {
            throw new IOException(
                "Error during file transfer: expected "
                    + iterationBytes + " bytes, only " + transferredLength + " bytes copied."
            );
          }
          doneBytes += transferredLength;
          todoBytes -= transferredLength;
        }
      }
      finally {
        if ( is != null ) {
          is.close();
        }
        if ( os != null ) {
          os.close();
        }
      }
      boolean successTimestampOp = destFile.setLastModified( srcFile.lastModified() );
      if ( !successTimestampOp ) {
          log.info("Could not change timestamp for {}. Index synchronization may be slow. " + destFile );
      }
    }

    private static void delete(File file) {
      if ( file.isDirectory() ) {
        for ( File subFile : file.listFiles() ) {
          delete( subFile );
        }
      }
      if ( file.exists() ) {
        if ( !file.delete() ) {
            log.info("Could not delete {}" + file );
        }
      }
    }


    private static void copyFileToDirectory(File sourceFile, File destFile, List <String>patternList)
            throws IOException {

        // The source file name to be copied.
        if (!sourceFile.exists()) {
            return;
        }
        // The target directory name to which the source file will be copied.
        if (!destFile.exists()) {
            destFile.mkdir();
        }
        try
        {
        // To copy a file to a specified folder we can use the FileUtils.copyDirectory() method.
        if (log.isDebugEnabled()) {
            log.debug("Copying " + sourceFile + " file to " + destFile);
        }

        FileFilter fileFilter = new WildcardFileFilter(patternList);

        FileUtils.copyDirectory(sourceFile, destFile,fileFilter);

        } catch (IOException e)
        {
        // If any error occures during copying the file
         log.error("IO error occurs while copying the file from source to destination." + e);
        }
    }

    public static void main(String[] args) {

        //List of filenames matching a pattern
        //
        //This is very strange ... this list is very speicific to Cognoscenti
        //so this class is not a general purpose backup class, but instead specialized
        //for this application only.  Not sure why ANT capability is not being used.
        List <String>patternList =new ArrayList<String>();
        patternList.add("UserProfiles.xml");
        patternList.add("errorLog_*.xml");
        patternList.add("Reqs*.log");
        patternList.add("ANONYMOUS_REQUESTS.*");
        patternList.add("Email*.*");

        try{
            log.info("Copying from "+args[0]+" to "+ args[1]);
            if(args[2].equals(BackupUtils.BACKUP)){
                copyFileToDirectory(new File(args[0]), new File(args[1]),patternList);
            }

            else if(args[2].equals(BackupUtils.RESTORE)){
                boolean syn=areDirectoryInSync(new File(args[0]), new File(args[1]),patternList);
                log.info("Is files in syn "+syn);
                if(!syn){
                   synDirectory( new File(args[0]), new File(args[1]), patternList );
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

    }

}
