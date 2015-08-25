                            <div class="pagenavigation">
                                <div class="pagenav">
                                    <div class="left"></div>
                                    <div class="right"></div>
                                    <div class="clearer"></div>
                                </div>
                                <div class="pagenav_bottom"></div>

                            </div>

                        </div>


                    </div>

<%@ include file="LeftSide.jsp"%>

                    <div class="clearer">&nbsp;</div>


                </div>




                <div id="footer">
                    <div class="left">Source:  https://code.google.com/p/cognoscenti/</div>
                    <div class="right">&laquo; Adaptive Case Management &raquo;</div>
                    <div class="clearer">&nbsp;</div>
                </div>

            </div>
            <div id="layout_edgebottom"></div>
        </div>

    </body>
</html>
<%
    ar.flush();
    //for some strange reason, the rest of the page does not get output unless
    //we manually call flush here.  No idea why.
%>
