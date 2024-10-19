package com.purplehillsbooks.weaver.util;

import com.purplehillsbooks.weaver.exception.WeaverException;

/**
 * Three way merge.
 * 
 * cur - this is the current official record with all changes from everyone
 * old - this is what this change assumed the current record to be
 * new - this is what this change wants to change to
 * 
 * Changes that are identified in the current version completely missing from
 * old and new are preserved as these seem to have been made after the 
 * edit started and they simply did not know about it.
 * 
 * But if in all other cases whatever is in the current version is 
 * replaced with whatever is in the new version.
 */
public class ThreeWayMerge {
    
    PosStr cur;
    PosStr old;
    PosStr neu;
    PosStr[] allPosStr = new PosStr[3];
    
    StringBuilder result = new StringBuilder();

    int curGood = 0;
    int oldGood = 0;
    int neuGood = 0;
    
    public static String mergeThem(String _cur, String _old, String _neu) {
        ThreeWayMerge twm = new ThreeWayMerge(_cur, _old, _neu);
        return twm.getMerged();
    }
    
    public ThreeWayMerge(String _cur, String _old, String _neu) {
        cur = new PosStr(_cur);
        old = new PosStr(_old);
        neu = new PosStr(_neu);
        allPosStr[0] = cur;
        allPosStr[1] = old;
        allPosStr[2] = neu;
    }
    
    public String getMerged() {
        
        while (cur.isMore() || old.isMore() || neu.isMore()) {
            skipEqualsSpan();
            resolveDifferenceSpan();
        }
        return result.toString();
    }
    
    /**
     * This is the easy part of the algorithm, which is walk through
     * the strings advancing each as long as they are all three exactly 
     * the same.   Advance increments the pos pointer in the PosString
     * with the understanding that what is before the pos pointer has
     * been found to be identical.  Remember that due to previous differences
     * the actual offset might be different, but we are walking through
     * spans of the strings that are identical looking for the beginning
     * of a span for which one or two of the strings are different.
     */
    private void skipEqualsSpan() {
        while (cur.isMore() && 
               old.isMore() && 
               neu.isMore() && 
               cur.ch()==old.ch()  &&
               cur.ch()==neu.ch()) {
            result.append(cur.ch());
            cur.advance();
            old.advance();
            neu.advance();
        }
    }

    /**
     * The goal here is to find the span of differences in the three strings.
     * That is, we want to find the next span of three or more characters that are
     * the same in all three string after the current point.
     * We hope to find the shortest span across the three.
     * In many cases, two strings might be identical.
     * But we need to find a span that exists in all three strings, 
     * and that span that is closest to the beginning so that we have
     * a minimal span of difference.
     * 
     * for example
     * 
     *     abc ^ def    ^ ghi
     *     abc ^ 123456 ^ ghi
     *     abc ^ x      ^ ghi
     *     
     * In these three, the "ghi" terminates the difference span in all three
     * strings, and the difference span is 3, 6, and 1 character long respectively.
     * 
     * The problem is that you may find a match that is a long ways away, when a 
     * closer match would do.  We want to avoid this problem:
     * 
     *     abc ^ def       ^ ghi456ghi
     *     abc ^ 123ghi456 ^ ghi
     *     abc ^ x         ^ ghi456ghi
     * 
     * So, we start looking for chunks (3-letter-strings) that are closest to the
     * beginning of each of the strings -- actually closest to the beginning of the 
     * the span after the section that was found identical.  Gradually look for further and further
     * chunks.  Continue to try to find the minimal distance.
     */
    private void findShortestDiffBlock() {
        
        int bias = -1;
        int bestBias = 0;
        int which = 2;
        int bestWhich = 0;
        int bestValue = 666666;
        int max = Math.max(Math.max(cur.chunksLeft(), old.chunksLeft()), neu.chunksLeft());
        cur.diffSize = -1;
        old.diffSize = -1;
        neu.diffSize = -1;

        while (true) {
            
            if (which>=2) {
                which = 0;
                bias++;
            }
            else {
                which++;
            }
            if (bias>=max || bias>=bestValue) {
                //that is the end ... need to leave
                if (bestValue<666666) {
                    String chunk = allPosStr[bestWhich].getChunk(bestBias);
                    cur.setDiffSize(chunk);
                    old.setDiffSize(chunk);
                    neu.setDiffSize(chunk);
                }
                return;
            }
            
            if (bias>=allPosStr[which].chunksLeft()) {
                //nothing left in this source, try the next
                continue;
            }
            
            //A chunk is a three letter string at a particular bias position
            //beyond the end of the last matching section.
            String chunk = allPosStr[which].getChunk(bias);
            
            int curPos = cur.distanceOf(chunk);
            if (curPos<0) {
                continue;
            }
            int oldPos = old.distanceOf(chunk);
            if (oldPos<0) {
                continue;
            }
            int neuPos = neu.distanceOf(chunk);
            if (neuPos<0) {
                continue;
            }
            if (curPos + oldPos + neuPos < bestValue) {
                bestValue = curPos + oldPos + neuPos;
                bestWhich = which;
                bestBias = bias;              
            }
        }
    }
    
    
    private void resolveDifferenceSpan() {
        if (!cur.isMore() &&  !old.isMore() &&  !neu.isMore()) {
            //the strings ended equaling each other, nothing left to do
            return;
        }
        
        findShortestDiffBlock();
        
        String curDiff = cur.getDiffBlock();
        String oldDiff = old.getDiffBlock();
        String newDiff = neu.getDiffBlock();
        
        if (curDiff.length()==0 && oldDiff.length()==0 && newDiff.length()==0) {
            throw new RuntimeException("STRANGE, got zero zero zero for diff results ... they are all equal?");
        }
        
        if (oldDiff.equals(newDiff)) {
            //This is where the new delta has no change, so
            //preserve the change in the currently merged version
            //and ignore anything in both new and old.
            result.append(curDiff);
        }
        else if (curDiff.equals(oldDiff)) {
            //This is the regular replace case.  Remove the old
            //and just go with the new.
            result.append(newDiff);
        }
        
        else if (curDiff.equals(newDiff)) {
            //this is the strange case where two people type the
            //exact same thing.  The current already has exactly what
            //the new has, so ignore the change ... it is already there
            result.append(newDiff);
        }
        else {
            //this is a case where all three are different, and it 
            //means that two people were typing new material into the
            //same spot at the same time.
            //Include BOTH the changes from the current version
            //and ALSO the changes from the new version.
            //This might result in some duplication.
            //An earlier version of this algorithm used to delete the 
            //earlier modification, but this caused a lot of problem with
            //multiple people typing on the end of the text at the same time.
            //People would LOSE sentences and things like that.  
            //This will cause each person's merges to appear mixed with the 
            //other, but it will still be there to move and fix by editing.
            result.append(curDiff);
            result.append(newDiff);
        }
        cur.skipDiff();
        old.skipDiff();
        neu.skipDiff();
    }
    

    private class PosStr {
        public String s;
        public int pos;
        public int diffSize;
        
        public PosStr(String val) {
            s = val;
            pos = 0;
        }
        public char ch() {
            if (pos<s.length()) {
                return s.charAt(pos);
            }
            return (char)0;
        }
        public void advance() {
            pos++;
        }
        public int chunksLeft() {
            return s.length()-pos-2;
        }
        public String getChunk(int bias) {
            return s.substring(pos+bias, pos+bias+3);
        }
        public int distanceOf(String chunk) {
            return s.indexOf(chunk, pos)-pos;
        }
        public void setDiffSize(String chunk) {
            diffSize = distanceOf(chunk);
        }
        
        public String getDiffBlock() {
            if (diffSize<0) {
                return s.substring(pos);
            }
            else {
                return s.substring(pos, pos+diffSize);
            }
        }
        public void skipDiff() {
            if (diffSize<0) {
                pos = s.length();
            }
            else {
                pos += diffSize;
            }
        }
        
        public boolean isMore() {
            return pos<s.length();
        }
    }
    
    
    public static void testMergeCases() throws Exception  {
        String curStr = "abcdefghi";
        String oldStr = "abcdefghi";
        String neuStr = "abcdefghi";
        try {
            
            //all equal should work
            testOneMerge(neuStr, curStr, oldStr, neuStr);

            //complete change, no similarity
            neuStr = "123456789";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            
            
            //only the neu has deletion, should be equal to change
            neuStr = "abcdeghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abhi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "ai";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "bcdefghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefgh";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            
            //only the neu has insertion, should be equal to change
            neuStr = "abcdefxghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefxxghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefxxxghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "xabcdefxghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "xxabcdefxghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefxghix";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefxghixx";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
    
            //only the neu has replacement, should be equal to change
            neuStr = "abcdxfghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcxxxghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abxxxxxhi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "xxxxxxxxx";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "zbcdefghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "zzcdefghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefgzz";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            neuStr = "abcdefghz";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            
            //now test cases where there is no change in new/old
            //to see that change in cur is preserved
            neuStr = "abcdefghi";
            curStr = "abcxdefghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abcxxdefghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abcxxxdefghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abcefghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abcfghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abceghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "xabcdefghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "zzabcdefghi";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abcdefghix";
            testOneMerge(curStr, curStr, oldStr, neuStr);
            curStr = "abcdefghizz";
            testOneMerge(curStr, curStr, oldStr, neuStr);
    
            
            //now test where cur and neu have same changes in them
            oldStr = "abcdefghi";
            curStr = "abczzzghi";
            neuStr = "abczzzghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "abcghi";
            neuStr = "abcghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "bcdefghi";
            neuStr = "bcdefghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "cdefghi";
            neuStr = "cdefghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "defghi";
            neuStr = "defghi";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "abcdefgh";
            neuStr = "abcdefgh";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "abcdefg";
            neuStr = "abcdefg";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
            curStr = "abcdef";
            neuStr = "abcdef";
            testOneMerge(neuStr, curStr, oldStr, neuStr);
    
            //now test non conflicting MERGE cur and neu have same changes in different places
            curStr = "abxxcdefghi"; //add middle
            neuStr = "abcdefgzzhi"; //add middle
            testOneMerge("abxxcdefgzzhi", curStr, oldStr, neuStr);
            curStr = "abxxcdefghi"; //add middle
            neuStr = "abczzdefghi"; //add middle close to other (wins)
            testOneMerge("abczzdefghi", curStr, oldStr, neuStr);
            curStr = "abxxcdefghi"; //add middle
            neuStr = "abcdefghizz"; //add end
            testOneMerge("abxxcdefghizz", curStr, oldStr, neuStr);
            curStr = "abcdxxefghi"; //add middle
            neuStr = "zzabcdefghi"; //add begin
            testOneMerge("zzabcdxxefghi", curStr, oldStr, neuStr);
            curStr = "abxxcdefghi"; //add middle close to begin
            neuStr = "zzabcdefghi"; //add begin (wins)
            testOneMerge("zzabcdefghi", curStr, oldStr, neuStr);
            
            curStr = "abcdefxxghi"; //add middle
            neuStr = "abczzdefghi"; //add middle
            testOneMerge("abczzdefxxghi", curStr, oldStr, neuStr);
            curStr = "xxabcdefghi"; //add beginning
            neuStr = "abczzdefghi"; //add middle
            testOneMerge("xxabczzdefghi", curStr, oldStr, neuStr);
            curStr = "abcdefghixx"; //add end
            neuStr = "abczzdefghi"; //add middle
            testOneMerge("abczzdefghixx", curStr, oldStr, neuStr);
            
            curStr = "adefghi"; // delete middle
            neuStr = "abcdefi"; // delete middle
            testOneMerge("adefi", curStr, oldStr, neuStr);
            curStr = "abefghi"; // delete middle close
            neuStr = "abcdefi"; // delete middle close (wins)
            testOneMerge("abcdefi", curStr, oldStr, neuStr);
            curStr = "cdefghi"; // delete begin
            neuStr = "abcdefg"; // delete end
            testOneMerge("cdefg", curStr, oldStr, neuStr);
            curStr = "abcdef"; // delete end
            neuStr = "defghi"; // delete begin
            testOneMerge("def", curStr, oldStr, neuStr);
            
            //now test non CONFLICTS cur and neu have changes in same places
            curStr = "abcdxxxefghi"; //add some
            neuStr = "abcdzzzefghi"; //add different
            testOneMerge("abcdzzzefghi", curStr, oldStr, neuStr);
            curStr = "abcxxxghi"; //replace some
            neuStr = "abczzzghi"; //replace different
            testOneMerge("abczzzghi", curStr, oldStr, neuStr);
            curStr = "abcdxxxefghi"; //add some
            neuStr = "abczzzghi"; //replace different
            testOneMerge("abczzzghi", curStr, oldStr, neuStr);
            curStr = "abcxxxghi"; //replace some
            neuStr = "abcdzzzefghi"; //add different
            testOneMerge("abcdzzzefghi", curStr, oldStr, neuStr);
            
            //now test the special cases on the end, where both have added
            //and we want to preserve both changes, even though the clash
            //might be non-sense.  At least is it better than losing your entire change.
            oldStr = "abcdefghi";
            curStr = "abcdefghijlk";
            neuStr = "abcdefghimno";
            testOneMerge("abcdefghijlkmno", curStr, oldStr, neuStr);
            
    
            curStr = "This is a proper test sentence"; //add some
            oldStr = "This is a proper sentence"; //add some
            neuStr = "This should be a proper sentence."; //add different
            testOneMerge("This should be a proper test sentence.", curStr, oldStr, neuStr);
    
            curStr = "The black cat and dog make a black pair."; //add some
            oldStr = "The cat and dog make a black pair"; //add some
            neuStr = "The cat and black dog make a dark pair"; //add different
            testOneMerge("The black cat and black dog make a dark pair.", curStr, oldStr, neuStr);
            
            //this is a pathological case because there is a repeated value
            //within a short distance, less than 3x the size of the change.
            //so leaving this strange case with strange result.
            //at least it is well behaved.
            curStr = "line 1xxx-line 2xxx-blue 3xxx"; //add some
            oldStr = "line 1xxx-line 2xxx-line 3xxx"; //add some
            neuStr = "line 1xxx-red 2xxx-line 3xxx"; //add different
            testOneMerge("line 1xxx-red 2xxx-line 3xxx", curStr, oldStr, neuStr);
            
        }catch (Exception e) {
            System.out.println("Merge failed on case: ("+curStr+")("+oldStr+")("+neuStr+")"+e.toString());
            throw WeaverException.newWrap("Merge failed on case: ("+curStr+")("+oldStr+")("+neuStr+")",e);
        }
    }
    
    public static void testOneMerge(String result, String curStr, String oldStr, 
            String neuStr) throws Exception {
        String actual = ThreeWayMerge.mergeThem(curStr, oldStr, neuStr);
        if (!actual.equals(result)) {
            throw WeaverException.newBasic("MERGE FAIL:  got ("+actual+") instead of expected ("+result+")");
        }
        System.out.println("TEST MERGE: ("+curStr+")("+oldStr+")("+neuStr
                    +")  got ("+actual+")");
    }
}
