

function setVisibility(id) {
  if(document.getElementById(id).style.display == "inline")
    {
      document.getElementById(id).style.display = "none";
      document.getElementById('showDiv').style.display = "inline";
      document.getElementById('hideDiv').style.display = "none";
    }
  else
    {
      document.getElementById(id).style.display = "inline";
      document.getElementById('showDiv').style.display = "none";
      document.getElementById('hideDiv').style.display = "inline";
    }
  }

function expandCollapseLeftNav(id) {

  if(document.getElementById(id).style.display == "block")
    {
      document.getElementById(id).style.display = "none";
      var strId3 = id.substring(id.indexOf("_") + 1, id.length);
      document.getElementById("imgLN" + strId3).src=CPATH_LEFTNAV+"/assets/expandBlackIcon.gif";

    }
    else
    {
      document.getElementById(id).style.display = "block";
      var strId3 = id.substring(id.indexOf("_") + 1, id.length);
      document.getElementById("imgLN" + strId3).src=CPATH_LEFTNAV+"/assets/collapseBlackIcon.gif";
    }
}

function expandCollapseLeaflets(id,cpath,divheadingid) {

    if(document.getElementById(id).style.display == "")
    {
      document.getElementById(id).style.display = "none";
      var strId2 = id.substring(id.indexOf("_") + 1, id.length);
      document.getElementById(divheadingid+"_"+id).style.color='#333';
      document.getElementById(divheadingid+"_"+id).style.backgroundImage='none';
      document.getElementById(divheadingid+"_"+id).style.border='0px solid #ccc';
      var strId = id.substring(id.indexOf("_") + 1, id.length);
      document.getElementById("img_"+id).src=cpath+"assets/images/expandIcon.gif";

    }
    else
    {
      document.getElementById(id).style.display = "";
      var strId2 = id.substring(id.indexOf("_") + 1, id.length);
      document.getElementById(divheadingid+"_"+id).style.color='#182d6a';
      document.getElementById(divheadingid+"_"+id).style.backgroundImage='url('+cpath+'assets/images/leafLetSelected.gif)';
      document.getElementById(divheadingid+"_"+id).style.border='0px solid #c5cdd8';
      document.getElementById(divheadingid+"_"+id).style.borderRight='0px solid #c5cdd8';
      var strId = id.substring(id.indexOf("_") + 1, id.length);
      document.getElementById("img_"+id).src=cpath+"assets/images/collapseIcon.gif";
    }
}

function setVisibility_2(id) {

if(document.getElementById(id).style.display == "inline")
{
  document.getElementById(id).style.display = "none";
  document.getElementById('showDiv1').style.display = "inline";
  document.getElementById('hideDiv1').style.display = "none";

}
else
{
  //alert(document.getElementById('showHide').style.visibility);
  document.getElementById(id).style.display = "inline";
  document.getElementById('showDiv1').style.display = "none";
  document.getElementById('hideDiv1').style.display = "inline";


  //showHide.visiblity = hidden;
}
}
function showhide(id){
    if(document.getElementById(id).style.display == "none")
        {
         document.getElementById(id).style.display = "";
        }
        else
        {
         document.getElementById(id).style.display = "none";
        }
    }

function expandDiv(id){
  document.getElementById(id).style.display = "inline";
}

function expandDiv(id){
      document.getElementById(id).style.display = "inline";
}

function collapseDiv(id){
      document.getElementById(id).style.display = "none";
}
function collapseDiv1(id,id2,id3,id4,elementName){
    document.getElementById(id).style.display = "none";
      document.getElementById(id2).style.display = "none";
      document.getElementById(id3).style.display = "inline";
      document.getElementById(id4).style.display = "none";

      document.getElementById(elementName).value="";
}



