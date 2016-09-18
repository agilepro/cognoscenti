<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionWiki"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't  change the name of this page.");

    String p = ar.reqParam("p");
    String action = ar.reqParam("action");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertAdmin("Unable to change the name of this page.");

    String go = ar.defParam("go", ar.getResourceURL(ngp,"admin.htm"));

    if (action.equals("Change Name"))
    {
        String newName = ar.reqParam("newName");
        List newNameSet = new Vector();
        List<String> nameSet = ngp.getContainerNames();

        boolean isNew = true;

        //first, see if the new name is one of the old names, and if so
        //just rearrange the list
        int oldPos = findString(nameSet, newName);
        if (oldPos<0) {
            //we did not find the value, so just insert it
            nameSet.add(0, newName);
        }
        else {
            nameSet.remove(oldPos);
            nameSet.add(0,newName);
        }
        ngp.setPageNames(nameSet);
    }
    else if (action.equals("delName"))
    {
        String oldName = ar.reqParam("oldName");

        List<String> nameSet = ngp.getContainerNames();
        int oldPos = findString(nameSet, oldName);

        if (oldPos>=0) {
            nameSet.remove(oldPos);
            ngp.setPageNames(nameSet);
        }
    }
    ngp.saveFile(ar, "Change Name Action");

    response.sendRedirect(go);%><%@ include file="functions.jsp"
%><%!

    // compare the sanitized versions of the names in the array, and if
    // the val equals one, return the index of that string, otherwise
    // return -1
    public int findString(String[] array, String val)
    {
        String sanVal = SectionWiki.sanitize(val);
        for (int i=0; i<array.length; i++)
        {
            String san2 = SectionWiki.sanitize(array[i]);
            if (sanVal.equals(san2))
            {
                return i;
            }
        }
        return -1;
    }

    //insert the specified value into the array, and shift the values
    //in the array up to the specified point.  The value at that position
    //will be effectively removed.  The values after that position remain
    //unchanged.
    public void insertRemove(String[] array, String val, int position)
    {
        String replaceVal = val;
        for (int i=0; i<position; i++)
        {
            String tmp = array[i];
            array[i] = replaceVal;
            replaceVal = tmp;
        }
        array[position] = replaceVal;
    }

    //insert at beginning, Returns a new string array that is
    //one value larger
    public String[] insertFront(String[] array, String val)
    {
        int len = array.length;
        String[] ret = new String[len+1];
        ret[0] = val;
        for (int i=0; i<len; i++)
        {
            ret[i+1] = array[i];
        }
        return ret;
    }

    //insert at beginning, Returns a new string array that is
    //one value larger
    public String[] shrink(String[] array, int pos)
    {
        int len = array.length;
        String[] ret = new String[len-1];
        for (int i=0; i<pos; i++)
        {
            ret[i] = array[i];
        }
        for (int i=pos+1; i<len; i++)
        {
            ret[i-1] = array[i];
        }
        return ret;
    }

%>
