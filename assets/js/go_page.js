/*!
 * GO Page Function
 */

function goPage(pno, psize) {
  var itable = document.getElementById("post list");
  var num = itable.rows.length; //all rows
  console.log(num);
  var totalPage = 0; //all pages
  var pageSize = psize; //rows per page
  //how many pages
  if (num / pageSize > parseInt(num / pageSize)) {
    totalPage = parseInt(num / pageSize) + 1;
  } else {
    totalPage = parseInt(num / pageSize);
  }
  var currentPage = pno; //currentPage
  var startRow = (currentPage - 1) * pageSize + 1; //startRow 31
  var endRow = currentPage * pageSize; //endRow  40
  endRow = endRow > num ? num : endRow; //40
  console.log(endRow);
  for (var i = 1; i < num + 1; i++) {
    var irow = itable.rows[i - 1];
    if (i >= startRow && i <= endRow) {
      irow.style.display = "block";
    } else {
      irow.style.display = "none";
    }
  }
  var tempStr =
    "Totally " +
    num +
    " Divided into " +
    totalPage +
    " pages Currently the" +
    currentPage +
    "th Page";
  if (currentPage > 1) {
    tempStr +=
      '<a href="#" onClick="goPage(' + 1 + "," + psize + ')">Front Page</a>';
    tempStr +=
      '<a href="#" onClick="goPage(' +
      (currentPage - 1) +
      "," +
      psize +
      ')"><Previous Page</a>';
  } else {
    tempStr += "Front Page";
    tempStr += "<Previous Page";
  }
  if (currentPage < totalPage) {
    tempStr +=
      '<a href="#" onClick="goPage(' +
      (currentPage + 1) +
      "," +
      psize +
      ')">Next Page></a>';
    tempStr +=
      '<a href="#" onClick="goPage(' +
      totalPage +
      "," +
      psize +
      ')">Last Page</a>';
  } else {
    tempStr += "Next Page>";
    tempStr += "Last Page";
  }
  document.getElementById("barcon").innerHTML = tempStr;
}
