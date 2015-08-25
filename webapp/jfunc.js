    function showHideCommnets(elementid,url) {
        if (document.getElementById(elementid).style.display == 'none'){
            document.getElementById(elementid).style.display = 'block';
            var strId2 = elementid.substring(elementid.indexOf("-") + 1, elementid.length);
      if(document.getElementById("leafHeading" + strId2)!=null){
        document.getElementById("leafHeading" + strId2).style.color='#182d6a';
        document.getElementById("leafHeading" + strId2).style.backgroundImage='url('+url+'assets/images/leafLetSelected.gif)';
        document.getElementById("leafHeading" + strId2).style.border='1px solid #c5cdd8';
        document.getElementById("leafHeading" + strId2).style.borderBottom='0px solid #fbca05';
      }
      var strId = elementid.substring(elementid.indexOf("-") + 1, elementid.length);
      if(document.getElementById("image" + strId)!=null){
        document.getElementById("image" + strId).src=url+"assets/images/collapseIcon.gif";
      }

         }else{
            document.getElementById(elementid).style.display = 'none';
            var strId2 = elementid.substring(elementid.indexOf("-") + 1, elementid.length);
            if(document.getElementById("leafHeading" + strId2)!=null){
        document.getElementById("leafHeading" + strId2).style.color='#333';
        document.getElementById("leafHeading" + strId2).style.backgroundImage='none';
        document.getElementById("leafHeading" + strId2).style.border='1px solid #ccc';
      }
      var strId = elementid.substring(elementid.indexOf("-") + 1, elementid.length);
      if(document.getElementById("image" + strId)!=null){
        document.getElementById("image" + strId).src=url+"assets/images/expandIcon.gif";
      }


  //showHide.visiblity = hidden;
         }
    }
    function showHideAllCommnets(){
        var belement = document.getElementById("comment-expand");
        var action = belement.value;
        if(belement.value == "Expand"){
            belement.value = "Collapse";
            action = "block";
        }
        else{
            belement.value = "Expand";
            action = "none";
        }

        var i = 0;
        while(i >= 0){
            var divid = "comment-" + i;
            i = i+1;
            var elmnt = document.getElementById(divid);
            if(elmnt == null){
                i=-1;
                return;
            }
            elmnt.style.display = action;
        }
    }


/*Sorting Table *************Begin******************/

currentCol = 0
previousCol = -1

function CompareAlpha(a, b) {
    if (a[currentCol] < b[currentCol]) { return -1; }
    if (a[currentCol] > b[currentCol]) { return 1; }
    return 0;
}

function CompareAlphaIgnore(a, b) {
    strA = a[currentCol].toLowerCase();
    strB = b[currentCol].toLowerCase();
    if (strA < strB) { return -1; }
    else {
        if (strA > strB) { return 1; }
        else { return 0; }
    }
}

function CompareDate(a, b) {
    // this one works with date formats conforming to Javascript specifications, e.g. m/d/yyyy
    datA = new Date(a[currentCol]);
    datB = new Date(b[currentCol]);
    if (datA < datB) { return -1; }
    else {
        if (datA > datB) { return 1; }
        else { return 0; }
    }
}

function CompareDateEuro(a, b) {
    // this one works with european date formats, e.g. d.m.yyyy
    strA = a[currentCol].split(".");
    strB = b[currentCol].split(".")
    datA = new Date(strA[2], strA[1], strA[0]);
    datB = new Date(strB[2], strB[1], strB[0]);
    if (datA < datB) { return -1; }
    else {
        if (datA > datB) { return 1; }
        else { return 0; }
    }
}

function CompareNumeric(a, b) {
    //window.alert ("CompareNumeric");
    numA = a[currentCol]
    numB = b[currentCol]
    if (isNaN(numA)) { return 0;}
    else {
        if (isNaN(numB)) { return 0; }
        else { return numA - numB; }
    }
}

function TableSort(myTable, myCol, myType) {

    // Create a two-dimensional array and fill it with the table's content
    var mySource = document.all(myTable);
    var myRows = mySource.rows.length;
    var myCols = mySource.rows(0).cells.length;
    currentCol = myCol
    myArray = new Array(myRows)
    for (i=0; i < myRows; i++) {
        myArray[i] = new Array(myCols)
        for (j=0; j < myCols; j++) {
            myArray[i][j] = document.all(myTable).rows(i).cells(j).innerHTML
        }
    }
    if (myCol == previousCol) {
        myArray.reverse(); // clicked the same column as previously - reverse the sort
    }
    else { // clicked on a new column - sort as indicated
        switch (myType) {
            case "a":
                myArray.sort(CompareAlpha);
                break;
            case "ai":
                myArray.sort(CompareAlphaIgnore);
                break;
            case "d":
                myArray.sort(CompareDate);
                break;
            case "de":
                myArray.sort(CompareDateEuro);
                break;
            case "n":
                myArray.sort(CompareNumeric);
                break;
            default:
                myArray.sort()
        }
    }

    // Re-write the table contents
    for (i=0; i < myRows; i++) {
        for (j=0; j < myCols; j++) {
            mySource.rows(i).cells(j).innerHTML = myArray[i][j]
        }
    }

    previousCol = myCol; // remember the current sort column for the next pass
    return 0;
}

