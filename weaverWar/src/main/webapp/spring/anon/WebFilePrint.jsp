<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.capture.WebFile"
%><%
    String attachmentId = ar.reqParam("aid");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    String userKey = "j9iyux0nhu6mh9n2";

    AttachmentRecord att = ngw.findAttachmentByIDOrFail(attachmentId);
    String title = att.getNiceName();
    WebFile wf = att.getWebFile();
    JSONObject wfjson = wf.getJson();
    JSONArray sections = wfjson.requireJSONArray("sections");
    JSONArray links = wfjson.requireJSONArray("links");
    boolean available = sections.length()>0;
    WikiConverter wc = new WikiConverter(ar);
%>

<!-- BEGIN WebFilePrint.jsp Layout-->
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE web fonts -->
    <title><% ar.writeHtml(title); %></title>

    <!-- for the Lora Font -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&display=swap" rel="stylesheet">

</head>

<body>

<style>
body {
    width: 100%;
    padding-top: 0px;
    font-family: Lora, sans-serif;
}
.toptop { 
    padding: 10px;
    margin: auto;
    margin-bottom: 20px;
    width: 728px; 
}
.smalltime {
    font-size: 12px;
    border:2px #EEE solid;
    border-radius:5px;
}
.container {
    padding: 0;
    margin: auto;
    width: 728px;
    font-kerning: auto;
    font-size: 20px;
    font-weight: 400;
    line-height: 32px;
}
h1 {
    color: rgb(60, 30, 0);
    font-size: 32px;
    font-weight: 600;
    line-height: 36px;
    margin-bottom: 20px;
    margin-left: 0px;
    margin-right: 0px;
    margin-top: 0px;
    overflow-wrap: break-word;
}
h2 {
    color: rgb(140, 140, 140);
    cursor: default;
    font-kerning: auto;
    font-size: 24px;
    font-weight: 400;
    line-height: 24px;
    margin-bottom: 20px;
    margin-left: 0px;
    margin-right: 0px;
    margin-top: 12px;
    overflow-wrap: break-word;
}
h3 {
    color: rgb(140, 140, 140);
    cursor: default;
    font-kerning: auto;
    font-size: 18px;
    font-weight: 400;
    line-height: 24px;
    margin-bottom: 20px;
    margin-left: 0px;
    margin-right: 0px;
    margin-top: 12px;
    overflow-wrap: break-word;
}
p {
    color: rgb(64, 64, 64);
    cursor: default;
    font-kerning: auto;
    font-size: 20px;
    font-weight: 400;
    line-height: 32px;
    margin-top: 0px;
    margin-bottom: 20px;
    overflow-wrap: break-word;
    word-break: break-word;
}
.cleanTitleBox{
    border:2px #EEE solid;
    border-radius:5px;
    margin:0px;
    padding:8px
}
.segmentBox {
    max-width: 728px;
}
a {
    color:rgb(64, 64, 64);
}
.commentBox {
    margin-left: 80px;
    padding-left: 10px;
    border-left: double skyblue 6px;
}

</style>

<div >
    <div class="container toptop">
        <p class="smalltime"><% ar.writeHtml(title); %>
        Compressed Web View, 
        <a href="<%= wfjson.getString("url") %>" target="_blank">View Uncompressed</a></p>
    </div>
    <div class="container">

        <% for (JSONObject article : sections.getJSONObjectList()) {
               if( "article".equals(article.getString("group") ) ) {   
                   String markDown = article.getString("content");
                   JSONObject commentMap = article.requireJSONObject("comments");
                   JSONArray comments = commentMap.requireJSONArray(userKey);
                   int paraNum = 0;
               %> <div class="segmentBox"> <%
                   for (String paragraph : WebFile.findParagraphs(markDown)) {
                       paraNum++;
                       wc.writeWikiAsHtml(paragraph);
                       for (JSONObject comment : comments.getJSONObjectList()) {
                           if (paraNum == comment.getInt("para")) {
                               %> <div class="commentBox"> <%
                               wc.writeWikiAsHtml(comment.optString("cmt", ""));
                               %> </div> <% 
                           }
                       }
                   }
                %> </div> <% 

               }  
           } %>
        <% for (JSONObject link : sections.getJSONObjectList()) {
               if( "links".equals(link.getString("group") ) ) {  %>
            <tr >
                <td style="max-width: 600px"><div class="segmentBox">
                <%
                String markDown = link.getString("content");
                wc.writeWikiAsHtml(markDown);
                %>
                </div></td>
            </tr>
        <% }  } %>
        </table>



    </div>

</div>
</body>
