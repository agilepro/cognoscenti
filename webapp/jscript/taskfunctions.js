    function populateTableRow(pName) 
    { 
      counter = counter + 1; 
      var tbl = document.getElementById('parentProcessTable'); 
      var tbody = tbl.tBodies[0]; 
      var rowCount = tbody.rows.length; 
      var row = document.createElement('tr'); 
 
      var cell1 = document.createElement('td'); 
      cell1.innerHTML = (counter); 
 
      var cell2 = document.createElement('td'); 
      var cbx =  document.createElement('input'); 
      cbx.setAttribute('name','check'); 
      cbx.setAttribute('type','checkbox'); 
      cbx.setAttribute('id','check'); 
      cell2.appendChild(cbx); 
 
      var cell3 = document.createElement('td'); 
      var inp =  document.createElement('input'); 
      inp.setAttribute('name','parentProcess'+counter); 
      inp.setAttribute('type','text'); 
      inp.setAttribute('value', pName); 
      inp.setAttribute('size', '97'); 
      cell3.appendChild(inp); 
 
      row.appendChild(cell1); 
      row.appendChild(cell2); 
      row.appendChild(cell3); 
 
      if((rowCount%2) != 0) 
      { 
          row.className = "Odd"; 
      } 
      tbody.appendChild(row); 
    } 
 
    function appendTableRow() 
    { 
      populateTableRow(""); 
    } 
 
    function deleteTableRow() 
    { 
      var tbl = document.getElementById("parentProcessTable");
      var tbody = tbl.tBodies[0];
      var rowCount = tbody.rows.length;
      for (var idx=0; idx<rowCount; idx++) 
      { 
          var row = tbody.rows[idx]; 
          var cell = row.cells[1]; 
          var node = cell.lastChild; 
          if (node.checked == true)
          { 
              tbody.deleteRow(idx); 
          } 
      } 
  } 
  function deleteAllRows() 
  { 
      var tbl = document.getElementById("parentProcessTable"); 
      var tbody = tbl.tBodies[0]; 
      var rowCount = tbody.rows.length -1; 
      for (var idx=rowCount; idx >= 0; idx--)
      { 
          tbody.deleteRow(idx);
      } 
  } 
