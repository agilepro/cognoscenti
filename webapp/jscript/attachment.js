var removecallback = {
    success: function(o) {
                var respText = o.responseText;
                var json = eval('(' + respText+')');
                if(json.msgType == "success"){
                    deleteRow();
                }else{
                    showErrorMessage("Result", json.msg , json.comments );
                }
            },
    failure: function(o) {
        alert("removecallback Error:" +o.responseText);
    }
}

function deleteRow(){
    myDataTable2.deleteRow(elRow2);
    window.location.reload();
}

var handleUndeleteAction = {

    success: function(o) {
        var respText = o.responseText;
        var json = eval('(' + respText+')');

        if(json.msgType == "success"){
            window.location.reload();
        }
        else if(json.msgType == "failure"){
            showErrorMessage("Error : Undeleting Document", json.msg , json.comments);
        }else{
            window.location  = "<%=ar.retPath%>t/EmailLoginForm.htm?&msg=<%=encodedLoginMsg%>&go=<%ar.writeURLData(ar.getCompleteURL());%>";
        }
    },
    failure: function(o) {
        alert("handleUndeleteAction Error:" +o.responseText);
    }
}



function save(formId, fieldId, label){

    var fileName = document.getElementById(fieldId).value;
    if(fileName == ""){
        alert(label+" Field is mandetory.");
        document.getElementById(fieldId).focus();
        return false;
    }else{
        document.getElementById(formId).submit();
        myPanel.hide();
        return true;
    }
}

function checkVal(type){
    var val = "";

    if(type == "attachment"){
        return check("fname", "Local File");
    }else if(type == "link"){
         return (check("link_comment", "Description of Web Page") && check("taskUrl", "URL"));

    }else if(type == "email"){
         return (check("assignee", "To")
                 && check("subj", "Subject")
                 && check("instruct", "Instuctions")
                 && check("email_comment", "Description of File to Attach")
                 //&& check("pname", "Proposed Name")
                 );
    }
}