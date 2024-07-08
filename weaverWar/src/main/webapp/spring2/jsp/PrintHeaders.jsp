<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%>

<!-- BEGIN Wrapper.jsp Layout-->
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
    
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">

    <!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>
    <!-- Weaver specific tweaks -->
        <!-- Bootstrap 5.0-->
        <link rel="stylesheet" href="<%=ar.retPath%>css/bootstrap.min.css" />
        <link rel="stylesheet" href="<%=ar.retPath%>css/weaver.min.css" />
</head>

<body style="padding:10px;">

