package org.socialbiz.cog.capture;

import java.io.Writer;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

import org.jsoup.nodes.Attribute;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;

import com.purplehillsbooks.streams.HTMLWriter;

/*
 * Represents a block on the page, like a paragraph or a div or a header
 */
public class CapturePageBlock {

    /** the blockType is initialized to UNKNOWN */
    public final static int UNKNOWN = 0;
    
    /** we have determined that this block contain first-class text which is part of the article */
    public final static int TEXTBLOCK = 1;
    
    /** we have determined that this block just contains a bunch of links and is probably just a menu or navigation section */
    public final static int MENUNAVBLOCK = 2;
    
    
    public List<CapturePageText> textItems = new ArrayList<CapturePageText>();
    public int blockType;
    public CapturePage thePage;
    
    public CapturePageBlock(CapturePage sp, int type) {
        thePage = sp;
        blockType = type;
    }
    
    public void addPlainText(String content) {
        CapturePageText sbt = CapturePageText.createPlainText(thePage, content);
        textItems.add(sbt);
    }
    public CapturePageText addStyle(String tagName) {
        CapturePageText sbt = CapturePageText.createStyle(thePage, tagName);
        textItems.add(sbt);
        return sbt;
    }
    
    public void fillContent(Writer wr, Element ele) throws Exception {
        String tagName = ele.nodeName().toLowerCase();
        if ("a".equals(tagName)) {
            streamLink(wr, ele);
            return;
        }
        CapturePageText spt = null;
        if ( exposedTagType(tagName) ) {
            spt = CapturePageText.createStyle(thePage, tagName);
            textItems.add(spt);
            wr.write("("+tagName+")");
        }
        else {
            wr.write("(-"+tagName+")");
        }

        for (Node child : ele.childNodes()) {
            if (child instanceof TextNode) {
                TextNode tNode = (TextNode) child;
                String t = tNode.getWholeText();
                if (spt!=null) {
                    spt.addPlainText(t);
                }
                else {
                    this.addPlainText(t);
                }
                HTMLWriter.writeHtml(wr, t);
            }
            else if (child instanceof Element) {
                Element childEle = (Element) child;
                if (spt!=null) {
                    spt.fillContent(wr, childEle);
                }
                else {
                    this.fillContent(wr, childEle);
                }
            }
        }        
        
        wr.write("(/"+tagName+")");
    }

    public void captureLinks(Writer wr, Element ele) throws Exception {
        String tagName = ele.nodeName().toLowerCase();
        if ("a".equals(tagName)) {
            streamLink(wr, ele);
            return;
        }

        for (Node child : ele.childNodes()) {
            if (child instanceof Element) {
                Element childEle = (Element) child;
                captureLinks(wr, childEle);
            }
        }        
    }

    public void streamLink(Writer wr, Element ele) throws Exception {
        String url = "";
        for (Attribute att : ele.attributes()) {
            if (att.getKey().equalsIgnoreCase("href")) {
                url = att.getValue();
                if (url.toLowerCase().startsWith("http")) {
                    //nothing to do
                }
                else if (url.startsWith("/")) {
                    //root style relative URL
                    url = thePage.rootUrl + url;
                }
                else {
                    //relative URL to current context
                    url = thePage.contextUrl + url;
                }
            }
        }
        String val = ele.text().trim();
        if (val.length()==0) {
            return;
        }
        CapturePageText sbt = CapturePageText.createLink(thePage, val, url);
        textItems.add(sbt);
        
        wr.write("<a href=\""+thePage.cleanerUrl+"?path=");
        wr.write(URLEncoder.encode(url, "UTF-8"));
        wr.write("\">");
        HTMLWriter.writeHtml(wr,val);
        wr.write("</a>");
    }

    public void produceHtml(Writer w) throws Exception {
        for (CapturePageText sbt : textItems) {
            sbt.produceHtml(w);
        }
    }
    
    public static boolean exposedTagType(String tagName) {
        if ("p".equals(tagName)) {
            return true;
        }
        if ("i".equals(tagName)) {
            return true;
        }
        if ("b".equals(tagName)) {
            return true;
        }
        if ("em".equals(tagName)) {
            return true;
        }
        if ("strong".equals(tagName)) {
            return true;
        }
        if ("h1".equals(tagName)) {
            return true;
        }
        if ("h2".equals(tagName)) {
            return true;
        }
        if ("h3".equals(tagName)) {
            return true;
        }
        if ("h4".equals(tagName)) {
            return true;
        }
        return false;
    }
}
