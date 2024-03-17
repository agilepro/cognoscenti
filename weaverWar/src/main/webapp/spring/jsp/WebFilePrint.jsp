<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.capture.WebFile"
%><%
    String attachmentId = ar.reqParam("aid");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    
    AttachmentRecord att = ngw.findAttachmentByIDOrFail(attachmentId);
    String title = att.getNiceName();
    WebFile wf = att.getWebFile();
    JSONObject wfjson = wf.getJson();
    JSONArray articles = wfjson.requireJSONArray("articles");
    JSONArray links = wfjson.requireJSONArray("links");
    boolean available = articles.length()>0;
    WikiConverter wc = new WikiConverter(ar);
%>

<!-- BEGIN Wrapper.jsp Layout-->
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">

    <!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />
    <title><% ar.writeHtml(title); %></title>

</head>

<body style="padding:10px;">

<style>
.cleanedWebStyle {
}
.cleanTitleBox{
    border:2px #EEE solid;
    border-radius:5px;
    margin:0px;
    padding:8px
}
.segmentBox{
    border:2px #F0F0F0 solid;
    border-radius:15px;
    margin:0px;
    padding:8px;
    max-width: 600px;
}

</style>

<div ng-cloak>

    <div class="cleanedWebStyle">
        <h1><% ar.writeHtml(title); %></h1>
    
        <p>Compressed Web View, <a href="<%= wfjson.getString("url") %>" target="_blank">View Uncompressed</a></p>
        <table class="tabledd">
        <% for (JSONObject article : articles.getJSONObjectList()) { %>
            <tr >
            
                <td style="max-width: 600px"><div class="segmentBox">
                <% 
                String markDown = article.getString("content");
                wc.writeWikiAsHtml(markDown);
                %>
                </div></td>
            </tr>
        <% } %>
            <hr/>
            <hr/>
        <% for (JSONObject link : links.getJSONObjectList()) { %>
            <tr >
                <td style="max-width: 600px"><div class="segmentBox">
                <% 
                String markDown = link.getString("content");
                wc.writeWikiAsHtml(markDown);
                %>
                </div></td>
            </tr>
        <% } %>
        </table>
        

        
    </div>

</div>
</body>
