package org.socialbiz.cog.capture;

import java.io.InputStream;
import java.io.Writer;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.ssl.SSLContextBuilder;
import org.apache.http.ssl.TrustStrategy;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Comment;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;

import com.purplehillsbooks.streams.HTMLWriter;
import com.purplehillsbooks.streams.SSLPatch;

/*
 * Represents a simplified html page.
 * Is a lost of blocks
 */
public class CapturePage {

    List<CapturePageBlock> blockItems = new ArrayList<CapturePageBlock>();
    CapturePageBlock linkList = new CapturePageBlock(this, CapturePageBlock.MENUNAVBLOCK);
    String fullUrl = "";   
    String rootUrl = "";   //no slash on end
    String contextUrl = "";    //slash on end
    String cleanerUrl = "";
    String errorMessage = null;
    
    public static CapturePage consumeWebPage(Writer wr, String path, String cleaner) throws Exception {

        
        HttpClient httpclient = getGoodClient();
        HttpGet httpget = new HttpGet(path);

        HttpResponse response = httpclient.execute(httpget);

        CapturePage sp = new CapturePage();
        try {
            sp.fullUrl = path;
            int slashPos = path.lastIndexOf("/"); 
            if (slashPos>1) {
                sp.contextUrl = path.substring(0,slashPos+1);
            }
            slashPos = path.indexOf("//");
            if (slashPos>0) {
                slashPos = path.indexOf("/", slashPos+3);
                if (slashPos>0) {
                    sp.rootUrl = path.substring(0,slashPos);
                }
            }
            sp.cleanerUrl = cleaner;
            
            String contentType = response.getFirstHeader("Content-Type").getValue();
            if (!contentType.contains("text/html")) {
                sp.errorMessage = "Sorry, this attachment has a content type of "
                       +contentType+", not HTML text.   Can only show the text of HTML pages.";
            }
            else {
                InputStream input = response.getEntity().getContent();
                Document doc = Jsoup.parse(input, null, path);
                Element body = doc.body();
                sp.parseThePage(wr,body,"");
            }
        }
        catch (Exception e) {
            sp.errorMessage = e.toString();
        }
        return sp;
    }

    
    private void createPointerPage(String contentType, String path) {
        CapturePageBlock spb = new CapturePageBlock(this, CapturePageBlock.TEXTBLOCK);
        blockItems.add(spb);
        CapturePageText cpt = spb.addStyle("h1");
        cpt.addPlainText("Non-HTML Page");
        
        cpt = spb.addStyle("div");
        cpt.addPlainText("Sorry, this attachment is "
            +contentType+", not HTML text.   Can only show the text only version of HTML pages.   Click ");
        cpt.addLink("THIS LINK", path);
        cpt.addPlainText(" to visit the original web address.");
    }
    
    public static void writeCapturePageStyle(Writer w) throws Exception {
        w.write("\n<head>");
        w.write("\n<link href=\"../../../jscript/bootstrap.css\" rel=\"styleSheet\" type=\"text/css\"/>");
        w.write("\n<link href=\"../../../bits/main.min.css\" rel=\"styleSheet\" type=\"text/css\"/>");
        w.write("\n<style>");
        w.write("\n.cleanTitleBox{border:2px gray solid;border-radius:5px;margin:8px;padding:8px}");
        w.write("\nbody{margin:8px;padding:8px;max-width:600px}");
        w.write("\n</style>");
        w.write("\n</head>");
    }
    
    public static HttpClient getGoodClient() {
        try { 
            /*
            HttpClient base = new DefaultHttpClient();
            ClientConnectionManager ccm = base.getConnectionManager();
            
            SSLContext ctx = SSLContext.getInstance("TLS");
            ctx.init(null, new TrustManager[]{SSLPatch.getDummyTrustManager()}, null);
            SSLConnectionSocketFactory ssf = new SSLConnectionSocketFactory(ctx,  
                     SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
            //SchemeRegistry sr = ccm.getSchemeRegistry();
            //sr.register(new Scheme("https", ssf, 443));
            return new DefaultHttpClient(ccm, base.getParams());
            */
            TrustStrategy ts = new TrustStrategy() {
                public boolean isTrusted(X509Certificate[] arg0, String arg1) throws CertificateException {
                    return true;
                }
            };
            
            SSLContextBuilder scb = new SSLContextBuilder();
            scb.loadTrustMaterial(null, ts);
            
            HttpClientBuilder hcb = HttpClientBuilder.create();
            hcb.setSSLHostnameVerifier(SSLPatch.getAllHostVerifier());
            hcb.setSSLContext(scb.build());
            return hcb.build();
            
        } catch (Exception ex) {
            return null;
        }
    }


    private void parseThePage(Writer wr, Element ele, String s) throws Exception {
        String tagName = ele.nodeName().toLowerCase();
        String p = s + " / " + tagName;

        if ("script".equals(tagName)) {
            return;
        }
        if ("svg".equals(tagName)) {
            return;
        }
        if ("style".equals(tagName)) {
            return;
        }
        if ("form".equals(tagName)) {
            return;
        }
        if ("figure".equals(tagName)) {
            return;
        }
        if ("meta".equals(tagName)) {
            return;
        }
        if ("iframe".equals(tagName)) {
            wr.write("\n<div class=\"showBogus\">I-FRAME</div>");
            return;
        }

        int kind = kindOfBlock(ele);
        if ("a".equals(tagName)) {
            wr.write("\n<div class=\"showLink\">");
            linkList.captureLinks(wr,ele);
            wr.write("\n</div>");
            return;
        }
        if (tagName.startsWith("/")) {
            wr.write("\n == found endtag:"+tagName+"<br/>");
            return;
        }
        if (kind == 3) {
            wr.write("\n<span style=\"color:gray\">container: "+p+"</span><br/>");
        }
        else if (kind == 2) {
            int[] stats = new int[2];
            stats[0] = 0;
            stats[1] = 0;
            getContentStats(stats, ele);
            wr.write("\n<span style=\"color:blue\"> stats: "+stats[0]+","+stats[1]
                +","+tagName+"</span><br/>");
            if (stats[0]>stats[1]) {
                CapturePageBlock spb = new CapturePageBlock(this, CapturePageBlock.TEXTBLOCK);
                blockItems.add(spb);
                wr.write("\n<div class=\"showText\">");
                spb.fillContent(wr,ele);
                wr.write("\n</div>");
            }
            else if (stats[1]>0) {
                //CapturePageBlock throwAway = new CapturePageBlock(CapturePageBlock.UNKNOWN);
                wr.write("\n<div class=\"showLink\">");
                linkList.captureLinks(wr,ele);
                linkList.addPlainText(", ");
                wr.write("\n</div>");
            }
            return;
        }
        else {
            wr.write("\n<span style=\"color:red\">TAG "+kind+": "+p+"</span><br/>");
        }
        if ("button".equals(tagName)) {
            return;
        }
        
        for (Node child : ele.childNodes()) {
            if (child instanceof TextNode) {
                TextNode tNode = (TextNode) child;
                String t = tNode.getWholeText().trim();
                if (t.length()>0) {
                    wr.write("\n<div class=\"showText\">");
                    HTMLWriter.writeHtml(wr,t);
                    wr.write("</div>");
                }
            }
            else if (child instanceof Element) {
                Element subTag = (Element) child;
                parseThePage(wr, subTag, p);
            }
            else if (child instanceof Comment) {
                wr.write("\n   - <span style=\"color:green\">");
                HTMLWriter.writeHtml(wr,((Comment)child).getData());
                wr.write("</span><br/>");
            }
            else {
                wr.write("\n   - ? <span style=\"color:red\">");
                HTMLWriter.writeHtml(wr,child.nodeName());
                wr.write("</span><br/>");
            }
        }
    }
 
    
    /** 1 = not a block instead span or text style, 
        2 == leaf block,  
        3 == containing block, 
        0 == unknown */

    public int kindOfBlock(Element ele) {
        if (!ele.isBlock()) {
            return 1;
        }
        for (Element child : ele.children()) {
            int kind = kindOfBlock(child);
            if (kind==3 || kind==2) {
                // if inside the current block we find either a leaf block
                // or containing block, then the current block is a containing block.
                // nothing else has to be looked at.
                return 3;
            }   
        }
        return 2;
    }
    
    
    
    
    public void getContentStats (int[] res, Element ele) {
        String tagName = ele.nodeName().toLowerCase();
        if ("a".equals(tagName)) {
            res[1] += ele.text().trim().length();
            return;
        }
        for (Node child : ele.childNodes()) {
            if (child instanceof TextNode) {
                res[0] += ((TextNode) child).getWholeText().trim().length();
            }
            else if (child instanceof Element) {
                Element childEle = (Element) child;
                getContentStats(res,childEle);
            }
        }                
    }
    
    public void produceHtml(Writer w) throws Exception {
        if (errorMessage!=null) {
            w.write("\n<h1>Text-Only Not Available</h1>");
            w.write("\n<p>The following problem occurred in trying to get the text of the web page:</p>");
            w.write("\n<p><b>");
            HTMLWriter.writeHtml(w, errorMessage);
            w.write("\n</b></p>");
            w.write("\n<p>You can access the original web resource with <a href=\""+fullUrl+"\">THIS LINK</a></p>");
        }
        else {
            int i = 0;
            for (CapturePageBlock sbp : blockItems) {
                w.write("\n<!-- block "+(++i)+" -->\n");
                sbp.produceHtml(w);
            }
            w.write("\n<hr/>\n<h1>Extra Links</h1><p>\n");
            linkList.produceHtml(w);
            w.write("\n</p>");
        }
    }
}
