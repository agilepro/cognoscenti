<%@ page language="java" import="java.util.*,java.lang.Thread.State" contentType="text/html;charset=UTF-8"
    pageEncoding="ISO-8859-1"%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="CACHE-CONTROL" content="NO-CACHE">
<title>Thread Dump</title>
</head>
<body>
<%
    out.print("Generating Thread-dump at:" + (new java.util.Date()).toString() + "<BR>");
    out.println("----------------------------<br>");
    Map<Thread, StackTraceElement[]> map = Thread.getAllStackTraces();
    Iterator<Thread> itr = map.keySet().iterator();
    while (itr.hasNext()) {
            Thread t = itr.next();
            StackTraceElement[] elem = map.get(t);
            out.print("\"" + t.getName() + "\"");
            out.print(" prio=" + t.getPriority());
            out.print(" tid=" + t.getId());
            State s = t.getState();
            String state = null;
            String color = "000000";
            String GREEN = "00FF00";
            String RED = "FF0000";
            String ORANGE = "FCA742";
            switch(s) {
                case NEW: state ="NEW"; color = GREEN; break;
                case BLOCKED: state = "BLOCKED"; color = RED; break;
                case RUNNABLE: state = "RUNNABLE"; color = GREEN; break;
                case TERMINATED: state = "TERMINATED"; break;
                case TIMED_WAITING: state = "TIME WAITING"; color = ORANGE; break;
                case WAITING: state = "WAITING"; color = RED; break;
            }
            out.print("<font color=\"" + color + "\"> @@@@</font>");
            out.println(" " + state + "<BR>");
            for (int i=0; i < elem.length; i++) {
                    out.println("  at ");
                    out.print(elem[i].toString());
                    out.println("<BR>");
            }
            out.println("----------------------------<br>");
    }

%>
</body>
</html>