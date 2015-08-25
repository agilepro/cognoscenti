<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.spring.XHTMLError"
%><%
/*
Required parameter:

    1. errors : This parameter is used to retrieve list of XHTMLError from request attribute.

*/

    List<XHTMLError> errors = (List<XHTMLError>)request.getAttribute("errors");
    String source = (String) request.getAttribute("source");

    writeHtmlErros(errors,ar);

    ar.write("\n<hr/>\n<pre style=\"background-color:white;\">");
    int count = 0;
    int pos = source.indexOf("\n");
    int start = 0;
    while (pos>start) {
        ar.write("\n"+(count++)+": ");
        ar.writeHtml(source.substring(start, pos));
        start = pos+1;
        //while (start<source.length() && source.charAt(start)<' ') {
        //    start++;
        //}
        pos = source.indexOf("\n", start);
    }
    if (start<source.length()) {
        ar.write("\n"+(count)+": ");
        ar.writeHtml(source.substring(start));
    }
    ar.write("\n</pre>");
%><%!

    public void writeHtmlErros(List<XHTMLError> errors,AuthRequest out )throws Exception{
         for (XHTMLError error : errors) {
             out.writeHtml("Line : ");
             out.writeHtml(String.valueOf(error.getLine()));
             out.writeHtml(" Column : ");
             out.writeHtml(String.valueOf(error.getColumn()));
             out.writeHtml(" - ");
             out.writeHtml(error.getErrorMessage());
             out.write("<br/>");
            }
         out.write("\n\n\t Total Error on this Page = " + errors.size());
    }

%>